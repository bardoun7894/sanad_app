const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

// ----------------------------------------------------------------------------
// CONFIGURATION
// ----------------------------------------------------------------------------

// firebase functions:config:set freemius.bearer_token="sk_..." \
//   freemius.secret_key="sk_..." freemius.product_id="1234" freemius.sandbox="true"

const getFreemiusConfig = () => {
  const config = functions.config().freemius || {};
  return {
    bearerToken: config.bearer_token || '',
    secretKey: config.secret_key || '',
    productId: config.product_id || '',
    isSandbox: config.sandbox === 'true' || config.sandbox === true,
  };
};

const FREEMIUS_API = 'https://api.freemius.com/v1';
const FREEMIUS_CHECKOUT = 'https://checkout.freemius.com';

// ----------------------------------------------------------------------------
// HELPERS
// ----------------------------------------------------------------------------

/**
 * Look up a Firebase user by email.
 * Supports both real emails and synthetic ones (uid@domain).
 */
async function findUserByEmail(email) {
  if (!email) return null;

  // Synthetic email: uid@sanad-app.firebaseapp.com → extract UID
  const syntheticMatch = email.match(/^(.+)@sanad-app\.firebaseapp\.com$/);
  if (syntheticMatch) {
    const uid = syntheticMatch[1];
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    return userDoc.exists ? { uid, email } : null;
  }

  // Real email: query users collection
  const snapshot = await admin
    .firestore()
    .collection('users')
    .where('email', '==', email)
    .limit(1)
    .get();

  if (snapshot.empty) return null;
  const doc = snapshot.docs[0];
  return { uid: doc.id, email };
}

/**
 * Resolve billing cycle string for Freemius checkout.
 * 'weekly' → '7', 'monthly' → 'monthly', 'annual' → 'annual'
 */
function billingCycleForPlan(productId) {
  if (productId === 'weekly') return '7';
  return 'monthly';
}

/**
 * Resolve the number of valid days for a plan.
 */
function daysForPlan(productId) {
  if (productId === 'weekly') return 7;
  return 30;
}

// ----------------------------------------------------------------------------
// EXPORTED: getFreemiusCheckoutUrl (callable)
// ----------------------------------------------------------------------------

/**
 * Generate a hosted-checkout URL for a Freemius plan.
 *
 * Called by the Flutter app (FreemiusCheckoutService.getCheckoutUrl).
 * Constructs the URL server-side so Freemius API secrets stay hidden.
 * Stores a pending-purchase record so the webhook can link back to the
 * correct Firebase user.
 */
exports.getFreemiusCheckoutUrl = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be logged in.',
    );
  }

  const userId = context.auth.uid;
  const {
    email,
    planId,
    productId,
    sanadProductId,
    currency = 'USD',
    brandName = 'Sanad',
    sandbox = true,
    coupon,
    price, // optional — only honoured by Freemius on Pay-What-You-Want plans
  } = data;

  if (!planId) {
    throw new functions.https.HttpsError('invalid-argument', 'planId is required');
  }
  if (!productId) {
    throw new functions.https.HttpsError('invalid-argument', 'productId is required');
  }

  const safeEmail = email || `${userId}@sanad-app.firebaseapp.com`;
  const { isSandbox } = getFreemiusConfig();

  // Build the hosted-checkout URL.
  // Format (per Freemius dashboard "No-code Links"):
  //   https://checkout.freemius.com/product/<product_id>/plan/<plan_id>/?<query>
  const params = new URLSearchParams();
  if (safeEmail) params.set('user_email', safeEmail);
  if (currency) params.set('currency', currency);
  if (sandbox || isSandbox) params.set('sandbox', 'true');
  if (coupon) params.set('coupon', coupon);
  // `price` is only respected by Freemius when the plan is configured as
  // Pay-What-You-Want in the Freemius dashboard. On fixed-price plans
  // Freemius silently ignores this parameter and charges the plan's price.
  if (price !== undefined && price !== null && Number(price) > 0) {
    params.set('price', Number(price).toFixed(2));
  }

  const qs = params.toString();
  const checkoutUrl =
    `${FREEMIUS_CHECKOUT}/product/${productId}/plan/${planId}/` +
    (qs ? `?${qs}` : '');

  // Store a pending-purchase record so the webhook can link the Freemius
  // user back to our Firebase user
  const db = admin.firestore();
  try {
    await db.collection('freemius_pending_purchases').doc(userId).set({
      user_id: userId,
      email: safeEmail,
      product_id: productId,
      plan_id: planId,
      currency,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.warn('Failed to store pending purchase record:', e.message);
    // Non-fatal — webhook can still match by email
  }

  return {
    success: true,
    checkoutUrl,
  };
});

// ----------------------------------------------------------------------------
// EXPORTED: verifyFreemiusPurchase (callable)
// ----------------------------------------------------------------------------

/**
 * Check whether a Freemius purchase has been confirmed for a user.
 *
 * After the webhook processes a payment, it writes the purchase data into
 * `freemius_purchases/{userId}`. The Flutter app polls this function to
 * know when to activate the subscription client-side.
 */
exports.verifyFreemiusPurchase = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be logged in.',
    );
  }

  const userId = context.auth.uid;
  const { planId } = data;

  const db = admin.firestore();
  const purchaseDoc = await db
    .collection('freemius_purchases')
    .doc(userId)
    .get();

  if (!purchaseDoc.exists) {
    return { success: false, error: 'No purchase found' };
  }

  const purchase = purchaseDoc.data();

  // If a planId filter is provided, verify it matches
  if (planId && purchase.plan_id !== planId) {
    return { success: false, error: 'Plan mismatch' };
  }

  return {
    success: true,
    purchase: {
      payment_id: purchase.payment_id,
      user_id: purchase.user_id,
      plan_id: purchase.plan_id,
      product_id: purchase.product_id,
      amount: purchase.amount,
      currency: purchase.currency,
      status: purchase.status,
      license_id: purchase.license_id || null,
    },
  };
});

// ----------------------------------------------------------------------------
// EXPORTED: freemiusWebhook (HTTP endpoint)
// ----------------------------------------------------------------------------

/**
 * Receive webhook events from Freemius.
 *
 * URL: https://<region>-<project>.cloudfunctions.net/freemiusWebhook
 *
 * Configure this URL in the Freemius Developer Dashboard under
 * Settings → Webhooks. Freemius sends events like:
 *   - payment.created
 *   - license.created / license.expired / license.cancelled
 *   - subscription.*
 *
 * Security: validates the HMAC-SHA256 signature using the product secret key.
 */
exports.freemiusWebhook = functions.https.onRequest(async (req, res) => {
  // Only accept POST
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const { secretKey } = getFreemiusConfig();

  // Validate webhook signature (skip if no secret key configured)
  if (secretKey) {
    const rawBody = req.rawBody ? req.rawBody.toString('utf8') : JSON.stringify(req.body);
    const signature = (req.headers['x-signature'] || '').toString();
    const hash = crypto
      .createHmac('sha256', secretKey)
      .update(rawBody)
      .digest('hex');

    const isValid = crypto.timingSafeEqual(
      Buffer.from(hash, 'hex'),
      Buffer.from(signature, 'hex'),
    );

    if (!isValid) {
      console.warn('Freemius webhook: invalid signature');
      res.status(200).send(); // Don't reveal signature mismatch
      return;
    }
  } else {
    console.warn('Freemius webhook: no secret key configured — skipping signature check');
  }

  const event = req.body;
  if (!event || !event.type) {
    console.warn('Freemius webhook: invalid or empty body');
    res.status(200).send();
    return;
  }

  const eventType = event.type;

  console.log(`Freemius webhook received: ${eventType}`);

  try {
    switch (eventType) {
      case 'payment.created':
        await handlePaymentCreated(event);
        break;

      case 'license.created':
        await handleLicenseCreated(event);
        break;

      case 'license.expired':
      case 'license.cancelled':
      case 'license.deleted':
        await handleLicenseRevoked(event);
        break;

      case 'license.plan.changed':
      case 'license.extended':
        await handleLicenseChanged(event);
        break;

      default:
        console.log(`Freemius webhook: unhandled event type "${eventType}"`);
    }

    res.status(200).send('OK');
  } catch (e) {
    console.error(`Freemius webhook error [${eventType}]:`, e);
    // Always 200 to prevent Freemius from retrying indefinitely
    res.status(200).send('Processed with errors');
  }
});

// ----------------------------------------------------------------------------
// WEBHOOK EVENT HANDLERS
// ----------------------------------------------------------------------------

/**
 * payment.created — A payment was completed on Freemius.
 *
 * Activates the subscription in Firestore, stores purchase data, and
 * cleans up the pending-purchase record.
 */
async function handlePaymentCreated(event) {
  const payment = event.objects?.payment;
  const user = event.objects?.user;

  if (!payment || !user) {
    console.warn('payment.created missing payment or user object');
    return;
  }

  const email = user.email;
  const amount = Number(payment.gross || payment.amount || 0);
  const currency = payment.currency || 'USD';
  const licenseId = payment.license_id || event.data?.license_id || null;
  const planId = payment.plan_id || '';
  const productId = payment.product_id || '';

  // Link back to Firebase user
  const fbUser = await findUserByEmail(email);
  if (!fbUser) {
    console.warn(`Freemius webhook: no Firebase user found for email "${email}"`);
    return;
  }

  const userId = fbUser.uid;
  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Idempotency guard — Freemius retries failed webhooks. If we have already
  // recorded this payment ID, exit early so we don't double-extend the
  // subscription or insert a duplicate payment row.
  if (payment.id) {
    const existing = await db
      .collection('payments')
      .where('freemius_payment_id', '==', payment.id)
      .limit(1)
      .get();
    if (!existing.empty) {
      console.log(`Freemius: payment ${payment.id} already processed — skipping`);
      return;
    }
  }

  // 1. Activate subscription on user document
  const days = daysForPlan(planId);
  const expiryDate = new Date();
  expiryDate.setDate(expiryDate.getDate() + days);

  await db.collection('users').doc(userId).update({
    subscription_status: 'active',
    subscription_plan: planId || productId,
    subscription_expiry_date: admin.firestore.Timestamp.fromDate(expiryDate),
    payment_gateway: 'freemius',
    is_premium: true,
    auto_renew: true,
    updated_at: now,
  });

  // 2. Record the payment
  await db.collection('payments').add({
    user_id: userId,
    amount,
    currency,
    provider: 'freemius',
    product_id: planId || productId,
    status: 'completed',
    freemius_payment_id: payment.id,
    freemius_license_id: licenseId,
    created_at: now,
  });

  // 3. Store purchase data for client-side polling (verifyFreemiusPurchase)
  await db.collection('freemius_purchases').doc(userId).set({
    payment_id: payment.id?.toString() || '',
    user_id: userId,
    plan_id: planId || productId,
    product_id: productId,
    amount,
    currency,
    status: 'completed',
    license_id: licenseId,
    created_at: now,
  });

  // 4. Clean up pending-purchase record
  try {
    await db.collection('freemius_pending_purchases').doc(userId).delete();
  } catch (_) {
    // Non-fatal
  }

  console.log(`Freemius: subscription activated for user ${userId} (${planId}, ${currency} ${amount})`);
}

/**
 * license.created — A license was issued (may or may not have payment).
 */
async function handleLicenseCreated(event) {
  const license = event.objects?.license;
  const user = event.objects?.user;

  if (!license || !user) return;

  const email = user.email;
  const fbUser = await findUserByEmail(email);
  if (!fbUser) return;

  const userId = fbUser.uid;
  const db = admin.firestore();

  // Store the license ID on the user document for future upgrade/downgrade flows
  await db.collection('users').doc(userId).update({
    freemius_license_id: license.id?.toString() || null,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Freemius: license ${license.id} linked to user ${userId}`);
}

/**
 * license.expired / license.cancelled / license.deleted — Revoke access.
 */
async function handleLicenseRevoked(event) {
  const license = event.objects?.license;
  const user = event.objects?.user;

  if (!license || !user) return;

  const email = user.email;
  const fbUser = await findUserByEmail(email);
  if (!fbUser) return;

  const userId = fbUser.uid;
  const db = admin.firestore();

  await db.collection('users').doc(userId).update({
    subscription_status: 'expired',
    is_premium: false,
    auto_renew: false,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Freemius: subscription revoked for user ${userId} (${license.id})`);
}

/**
 * license.plan.changed / license.extended — Update plan details.
 */
async function handleLicenseChanged(event) {
  const license = event.objects?.license;

  if (!license) return;

  // Track down the Firebase user by license ID stored on user doc
  const db = admin.firestore();
  const snapshot = await db
    .collection('users')
    .where('freemius_license_id', '==', license.id?.toString())
    .limit(1)
    .get();

  if (snapshot.empty) {
    console.warn(`Freemius: license.changed — no user found for license ${license.id}`);
    return;
  }

  const userId = snapshot.docs[0].id;
  const planId = license.plan_id || '';

  await db.collection('users').doc(userId).update({
    subscription_plan: planId,
    subscription_status: 'active',
    is_premium: true,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Freemius: plan changed for user ${userId} → ${planId}`);
}
