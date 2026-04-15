const functions = require('firebase-functions');
const admin = require('firebase-admin');

// ----------------------------------------------------------------------------
// CONFIGURATION
// ----------------------------------------------------------------------------

// Get config from firebase functions:config:set
// Usage:
// firebase functions:config:set paypal.client_id="YOUR_ID" paypal.secret="YOUR_SECRET" paypal.sandbox="true"
const getPaypalConfig = () => {
          const config = functions.config().paypal || {};
          return {
                    clientId: config.client_id,
                    secret: config.secret,
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
          const { clientId, secret, isSandbox } = getPaypalConfig();

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
          const { amount, currency = 'USD', description = 'Consultation' } = data;

          const { isSandbox } = getPaypalConfig();
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

                    // Find approval link
                    const approvalLink = orderData.links.find(link => link.rel === 'approve');

                    return {
                              success: true,
                              orderId: orderData.id,
                              approvalUrl: approvalLink ? approvalLink.href : null,
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

          const { isSandbox } = getPaypalConfig();
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

                    if (orderData.status === 'COMPLETED' || orderData.status === 'APPROVED') {
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
                                        status: orderData.status.toLowerCase(),
                                        created_at: admin.firestore.FieldValue.serverTimestamp(),
                              });

                              return {
                                        success: true,
                                        orderId: orderData.id,
                                        status: orderData.status,
                              };
                    }

                    console.warn('Google Pay order returned unexpected status:', orderData.status);
                    return {
                              success: false,
                              error: `Unexpected order status: ${orderData.status}`,
                              orderId: orderData.id,
                    };

          } catch (error) {
                    console.error('Create Google Pay Order Failed:', error);
                    throw new functions.https.HttpsError('internal', error.message);
          }
});

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

          const { isSandbox } = getPaypalConfig();
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
                              // OPTIONAL: Update a 'payments' collection here for record keeping
                              const db = admin.firestore();
                              await db.collection('payments').add({
                                        order_id: orderId,
                                        user_id: context.auth.uid,
                                        amount: captureData.purchase_units?.[0]?.payments?.captures?.[0]?.amount?.value,
                                        currency: captureData.purchase_units?.[0]?.payments?.captures?.[0]?.amount?.currency_code,
                                        provider: 'paypal',
                                        status: 'completed',
                                        created_at: admin.firestore.FieldValue.serverTimestamp(),
                              });

                              return { success: true, status: 'COMPLETED' };
                    } else {
                              return { success: false, status: captureData.status };
                    }

          } catch (error) {
                    console.error('Capture Order Failed:', error);
                    throw new functions.https.HttpsError('internal', error.message);
          }
});


