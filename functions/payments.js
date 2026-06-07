const functions = require('firebase-functions');
const admin = require('firebase-admin');

// ----------------------------------------------------------------------------
// CONFIGURATION
// ----------------------------------------------------------------------------

// Resolve PayPal config. Credentials precedence:
//   1. Dashboard (Firestore system_settings/api_keys → paypal_client_id /
//      paypal_secret) — editable by admins with no redeploy, like the Zego keys.
//   2. firebase functions:config:set paypal.client_id=... paypal.secret=...
// Sandbox mode is controlled ONLY by functions.config().paypal.sandbox. It is
// deliberately NOT tied to the app's `payment_test_mode` toggle: PayPal's
// sandbox and live environments need DIFFERENT credentials, and the dashboard
// holds a single cred pair — so one toggle can't serve both. (The
// `payment_test_mode` toggle switches Freemius only.)
const _clean = (v) =>
          typeof v === 'string' && v.trim() && !v.startsWith('YOUR_')
                    ? v.trim()
                    : undefined;

const getPaypalConfig = async () => {
          const config = functions.config().paypal || {};

          let fsClientId;
          let fsSecret;
          try {
                    const keysSnap = await admin.firestore()
                              .collection('system_settings')
                              .doc('api_keys')
                              .get();
                    const keys = keysSnap.exists ? keysSnap.data() : {};
                    fsClientId = _clean(keys.paypal_client_id);
                    fsSecret = _clean(keys.paypal_secret);
          } catch (e) {
                    console.warn(
                              'getPaypalConfig: Firestore read failed, falling back to functions.config():',
                              e.message,
                    );
          }

          return {
                    clientId: fsClientId || _clean(config.client_id),
                    secret: fsSecret || _clean(config.secret),
                    isSandbox: config.sandbox === 'true' || config.sandbox === true,
          };
};

const PAYPAL_API = {
          SANDBOX: 'https://api-m.sandbox.paypal.com',
          PROD: 'https://api-m.paypal.com',
};

// ----------------------------------------------------------------------------
// PAYPAL HELPERS
// ----------------------------------------------------------------------------

async function getPaypalAccessToken() {
          const { clientId, secret, isSandbox } = await getPaypalConfig();

          if (!clientId || !secret) {
                    throw new Error('PayPal config missing (client_id/secret)');
          }

          const baseUrl = isSandbox ? PAYPAL_API.SANDBOX : PAYPAL_API.PROD;
          const credentials = Buffer.from(`${clientId}:${secret}`).toString('base64');

          const response = await fetch(`${baseUrl}/v1/oauth2/token`, {
                    method: 'POST',
                    headers: {
                              'Authorization': `Basic ${credentials}`,
                              'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: 'grant_type=client_credentials',
          });

          if (!response.ok) {
                    const error = await response.text();
                    throw new Error(`Failed to get PayPal token: ${error}`);
          }

          const data = await response.json();
          return data.access_token;
}

// ----------------------------------------------------------------------------
// EXPORTED FUNCTIONS
// ----------------------------------------------------------------------------

/**
 * Creates a PayPal Order (Optimization: moved to backend)
 */
exports.createPayPalOrder = functions.https.onCall(async (data, context) => {
          if (!context.auth) {
                    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
          }

          const userId = context.auth.uid;
          const {
                    amount,
                    currency = 'USD',
                    description = 'Consultation',
                    productId = '',
                    bookingId = null,
                    daysValid = 30,
          } = data;

          const { isSandbox } = await getPaypalConfig();
          const baseUrl = isSandbox ? PAYPAL_API.SANDBOX : PAYPAL_API.PROD;

          try {
                    const accessToken = await getPaypalAccessToken();

                    const orderBody = {
                              intent: 'CAPTURE',
                              purchase_units: [
                                        {
                                                  reference_id: userId,
                                                  description: description,
                                                  custom_id: userId,
                                                  amount: {
                                                            currency_code: currency,
                                                            value: Number(amount).toFixed(2),
                                                  },
                                        },
                              ],
                              application_context: {
                                        brand_name: 'Sanad',
                                        locale: 'ar-SA',
                                        shipping_preference: 'NO_SHIPPING',
                                        user_action: 'PAY_NOW',
                                        // In backend flow, return URLs might need to be deep links or web pages
                                        // We'll use the ones passed from client or defaults
                                        return_url: 'sanad://payment/success',
                                        cancel_url: 'sanad://payment/cancel',
                              },
                    };

                    const response = await fetch(`${baseUrl}/v2/checkout/orders`, {
                              method: 'POST',
                              headers: {
                                        'Authorization': `Bearer ${accessToken}`,
                                        'Content-Type': 'application/json',
                                        'PayPal-Request-Id': `SANAD-${userId}-${Date.now()}`,
                              },
                              body: JSON.stringify(orderBody),
                    });

                    if (!response.ok) {
                              const errorText = await response.text();
                              console.error('PayPal Order Error:', errorText);
                              throw new Error(`PayPal API Error: ${response.statusText}`);
                    }

                    const orderData = await response.json();

                    // Store a pending-order record keyed by the PayPal order id so
                    // capturePayPalOrder can activate the right entitlement
                    // server-side (source of truth) without trusting the client.
                    try {
                              await admin.firestore()
                                        .collection('paypal_pending_orders')
                                        .doc(orderData.id)
                                        .set({
                                                  user_id: userId,
                                                  product_id: productId,
                                                  booking_id: bookingId,
                                                  days_valid: Number(daysValid) || 30,
                                                  amount: Number(amount),
                                                  currency,
                                                  created_at: admin.firestore.FieldValue.serverTimestamp(),
                                        });
                    } catch (e) {
                              console.warn('Failed to store PayPal pending order:', e.message);
                              // Non-fatal — capture falls back to a subscription activation.
                    }

                    // Find approval link
                    const approvalLink = (orderData.links || []).find(link => link.rel === 'approve');

                    // Without a usable approval URL the client WebView would
                    // load a blank page. Treat it as a failure so the app shows
                    // an error instead of a blank checkout.
                    if (!approvalLink || !approvalLink.href) {
                              console.error('PayPal order created but no approval link returned:', JSON.stringify(orderData.links));
                              return {
                                        success: false,
                                        orderId: orderData.id,
                                        errorMessage: 'PayPal did not return an approval URL',
                              };
                    }

                    return {
                              success: true,
                              orderId: orderData.id,
                              approvalUrl: approvalLink.href,
                    };

          } catch (error) {
                    console.error('Create Order Failed:', error);
                    throw new functions.https.HttpsError('internal', error.message);
          }
});

/**
 * Creates a Google Pay / Apple Pay order processed through PayPal Orders v2.
 *
 * The Flutter `pay` package returns a tokenized payment blob (the
 * `paymentToken` below). We forward it to PayPal's Orders API as a
 * `google_pay` funding source inside `payment_source`. PayPal charges the
 * token and returns an order with status=COMPLETED on success.
 *
 * ✅ Schema verified against `api-m.sandbox.paypal.com` on 2026-04-14 —
 * this exact request body was accepted with status `CREATED`. See
 * docs/PAYMENT-LAUNCH-CHECKLIST.md Step 5 for the verification record.
 *
 * Flutter callers:
 *  - lib/features/subscription/screens/google_pay_screen.dart
 *  - lib/features/subscription/screens/apple_pay_screen.dart
 */
exports.createGooglePayOrder = functions.https.onCall(async (data, context) => {
          if (!context.auth) {
                    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
          }

          const userId = context.auth.uid;
          const {
                    amount,
                    currency = 'USD',
                    description = 'Subscription',
                    productId = '',
                    paymentToken,
          } = data;

          if (!paymentToken) {
                    throw new functions.https.HttpsError('invalid-argument', 'paymentToken is required');
          }
          if (!amount || Number(amount) <= 0) {
                    throw new functions.https.HttpsError('invalid-argument', 'amount must be > 0');
          }

          const { isSandbox } = await getPaypalConfig();
          const baseUrl = isSandbox ? PAYPAL_API.SANDBOX : PAYPAL_API.PROD;

          try {
                    const accessToken = await getPaypalAccessToken();

                    const orderBody = {
                              intent: 'CAPTURE',
                              purchase_units: [
                                        {
                                                  reference_id: userId,
                                                  description: description,
                                                  custom_id: `${userId}:${productId}`,
                                                  amount: {
                                                            currency_code: currency,
                                                            value: Number(amount).toFixed(2),
                                                  },
                                        },
                              ],
                              payment_source: {
                                        // PayPal accepts the stringified tokenization payload from the
                                        // Google Pay `pay` package inside `google_pay.card.payment_data`.
                                        // Apple Pay routes through the same endpoint with the Apple-issued
                                        // token in the same slot. If PayPal ever rejects the combined
                                        // endpoint for Apple Pay, split this into a separate
                                        // `createApplePayOrder` function using `payment_source.apple_pay`.
                                        google_pay: {
                                                  card: {
                                                            name: 'Sanad Subscriber',
                                                  },
                                                  payment_data: paymentToken,
                                        },
                              },
                              application_context: {
                                        brand_name: 'Sanad',
                                        locale: 'ar-SA',
                                        shipping_preference: 'NO_SHIPPING',
                              },
                    };

                    const response = await fetch(`${baseUrl}/v2/checkout/orders`, {
                              method: 'POST',
                              headers: {
                                        'Authorization': `Bearer ${accessToken}`,
                                        'Content-Type': 'application/json',
                                        'PayPal-Request-Id': `SANAD-GP-${userId}-${Date.now()}`,
                                        'Prefer': 'return=representation',
                              },
                              body: JSON.stringify(orderBody),
                    });

                    if (!response.ok) {
                              const errorText = await response.text();
                              console.error('PayPal Google Pay Order Error:', errorText);
                              throw new Error(`PayPal API Error: ${response.statusText}`);
                    }

                    const orderData = await response.json();

                    // Only COMPLETED means PayPal has actually captured the funds.
                    // APPROVED means the order is created and ready to capture — money
                    // has NOT moved yet. Calling the booking "paid" on APPROVED is the
                    // bug that lets failed Google Pay attempts mark bookings as paid
                    // and notify the therapist. So: if APPROVED, capture immediately
                    // and only return success when the capture comes back COMPLETED.
                    let finalStatus = orderData.status;

                    if (finalStatus === 'APPROVED') {
                              try {
                                        const captureResp = await fetch(
                                                  `${baseUrl}/v2/checkout/orders/${orderData.id}/capture`,
                                                  {
                                                            method: 'POST',
                                                            headers: {
                                                                      'Authorization': `Bearer ${accessToken}`,
                                                                      'Content-Type': 'application/json',
                                                                      'PayPal-Request-Id': `SANAD-GP-CAP-${orderData.id}`,
                                                            },
                                                  },
                                        );
                                        if (!captureResp.ok) {
                                                  const errText = await captureResp.text();
                                                  console.error('PayPal Google Pay Capture Error:', errText);
                                                  return {
                                                            success: false,
                                                            error: 'Capture failed',
                                                            orderId: orderData.id,
                                                  };
                                        }
                                        const captureData = await captureResp.json();
                                        finalStatus = captureData.status;
                              } catch (capErr) {
                                        console.error('PayPal Google Pay Capture Threw:', capErr);
                                        return {
                                                  success: false,
                                                  error: 'Capture failed',
                                                  orderId: orderData.id,
                                        };
                              }
                    }

                    if (finalStatus === 'COMPLETED') {
                              // Record the payment for bookkeeping. Subscription activation
                              // happens client-side in confirmPaymentSubscription.
                              const db = admin.firestore();
                              await db.collection('payments').add({
                                        order_id: orderData.id,
                                        user_id: userId,
                                        amount: Number(amount),
                                        currency: currency,
                                        provider: 'google_pay_via_paypal',
                                        product_id: productId,
                                        status: 'completed',
                                        created_at: admin.firestore.FieldValue.serverTimestamp(),
                              });

                              return {
                                        success: true,
                                        orderId: orderData.id,
                                        status: 'COMPLETED',
                              };
                    }

                    console.warn('Google Pay order final status not COMPLETED:', finalStatus);
                    return {
                              success: false,
                              error: `Payment not captured (status: ${finalStatus})`,
                              orderId: orderData.id,
                    };

          } catch (error) {
                    console.error('Create Google Pay Order Failed:', error);
                    throw new functions.https.HttpsError('internal', error.message);
          }
});

/**
 * Activate the entitlement for a captured PayPal order, server-side.
 *
 * Source of truth — does NOT trust the client. Reads the pending-order record
 * written by createPayPalOrder to know what was bought (subscription vs
 * booking), then activates it. Idempotent: a second capture of the same order
 * is a no-op (guarded on `payments.order_id`). Mirrors the Freemius webhook
 * (handlePaymentCreated) so the canonical premium fields stay consistent.
 */
async function activatePaypalEntitlement(orderId, fallbackUserId, captureData) {
          const db = admin.firestore();
          const now = admin.firestore.FieldValue.serverTimestamp();

          // Idempotency — PayPal/client may retry the capture. If we already
          // recorded this order, skip so we don't double-extend a subscription.
          const existing = await db
                    .collection('payments')
                    .where('order_id', '==', orderId)
                    .limit(1)
                    .get();
          if (!existing.empty) {
                    console.log(`PayPal: order ${orderId} already processed — skipping`);
                    return;
          }

          // Pending record (written at create time) tells us what was bought.
          const pendingRef = db.collection('paypal_pending_orders').doc(orderId);
          const pendingSnap = await pendingRef.get();
          const pending = pendingSnap.exists ? pendingSnap.data() : {};

          const capture =
                    captureData.purchase_units?.[0]?.payments?.captures?.[0]?.amount;
          const userId = pending.user_id || fallbackUserId;
          const amount = capture?.value ?? pending.amount ?? 0;
          const currency = capture?.currency_code ?? pending.currency ?? 'USD';
          const bookingId = pending.booking_id || null;
          const productId = pending.product_id || '';
          const daysValid = Number(pending.days_valid) || 30;

          // 1. Record the payment (order_id powers the idempotency guard above).
          await db.collection('payments').add({
                    order_id: orderId,
                    user_id: userId,
                    amount,
                    currency,
                    provider: 'paypal',
                    product_id: productId,
                    status: 'completed',
                    created_at: now,
          });

          // 2. Activate the entitlement — only when we know WHAT was bought.
          if (!pendingSnap.exists) {
                    // No pending record (create-time write failed, or the order
                    // predates this code). Do NOT guess: granting premium for what
                    // might be a booking is worse than deferring to the client's
                    // confirm call, which carries the real booking-vs-subscription
                    // intent. The payment is already recorded above.
                    console.warn(
                              `PayPal: no pending record for order ${orderId} — payment recorded, activation deferred to client.`,
                    );
                    return;
          }

          if (bookingId) {
                    await db.collection('bookings').doc(bookingId).update({
                              status: 'pending',
                              payment_status: 'paid',
                              payment_id: orderId,
                              payment_method: 'paypal',
                              paid_at: now,
                    });
          } else {
                    const expiryDate = new Date();
                    expiryDate.setDate(expiryDate.getDate() + daysValid);
                    // set(merge) — never throw after funds are captured just because
                    // the user doc is unexpectedly absent (would leave the customer
                    // charged but not activated).
                    await db.collection('users').doc(userId).set({
                              subscription_status: 'active',
                              subscription_plan: productId,
                              subscription_expiry_date:
                                        admin.firestore.Timestamp.fromDate(expiryDate),
                              payment_gateway: 'paypal',
                              is_premium: true,
                              auto_renew: false,
                              updated_at: now,
                    }, { merge: true });
          }

          // 3. Clean up the pending record.
          try {
                    await pendingRef.delete();
          } catch (_) {
                    // Non-fatal.
          }
}

/**
 * Captures a PayPal payment after user approval
 */
exports.capturePayPalOrder = functions.https.onCall(async (data, context) => {
          if (!context.auth) {
                    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
          }

          const { orderId } = data;
          if (!orderId) {
                    throw new functions.https.HttpsError('invalid-argument', 'Order ID required');
          }

          const { isSandbox } = await getPaypalConfig();
          const baseUrl = isSandbox ? PAYPAL_API.SANDBOX : PAYPAL_API.PROD;

          try {
                    const accessToken = await getPaypalAccessToken();

                    const response = await fetch(`${baseUrl}/v2/checkout/orders/${orderId}/capture`, {
                              method: 'POST',
                              headers: {
                                        'Authorization': `Bearer ${accessToken}`,
                                        'Content-Type': 'application/json',
                              },
                    });

                    if (!response.ok) {
                              // If already captured, check status
                              if (response.status === 422) {
                                        // Optionally check if already captured details, but for now throw
                              }
                              const errorText = await response.text();
                              console.error('PayPal Capture Error:', errorText);
                              throw new Error('Failed to capture payment.');
                    }

                    const captureData = await response.json();

                    if (captureData.status === 'COMPLETED') {
                              await activatePaypalEntitlement(orderId, context.auth.uid, captureData);
                              return { success: true, status: 'COMPLETED' };
                    } else {
                              return { success: false, status: captureData.status };
                    }

          } catch (error) {
                    console.error('Capture Order Failed:', error);
                    throw new functions.https.HttpsError('internal', error.message);
          }
});


