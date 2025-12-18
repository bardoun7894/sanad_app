/**
 * PayPal Webhook Handler Cloud Function
 *
 * This function processes webhook events from PayPal for subscription payments.
 *
 * Events handled:
 * - BILLING.SUBSCRIPTION.CREATED: Initial subscription purchase
 * - BILLING.SUBSCRIPTION.UPDATED: Subscription updated
 * - BILLING.SUBSCRIPTION.EXPIRED: Subscription expired
 * - BILLING.SUBSCRIPTION.CANCELLED: User cancelled subscription
 * - BILLING.SUBSCRIPTION.SUSPENDED: Subscription suspended (payment failed)
 *
 * Deploy with:
 * gcloud functions deploy paypalWebhook --gen2 --runtime nodejs18 --trigger-http --allow-unauthenticated
 */

const functions = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const paypalWebhook = functions.onRequest(async (req, res) => {
  // Only accept POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { event_type, id, resource } = req.body;

    // Log incoming webhook for debugging
    console.log(`PayPal Webhook Received: ${event_type}`, {
      webhookId: id,
      userId: resource?.custom_id,
      subscriptionId: resource?.id,
    });

    // Handle different event types
    switch (event_type) {
      case 'BILLING.SUBSCRIPTION.CREATED':
        await handleSubscriptionCreated(resource);
        break;

      case 'BILLING.SUBSCRIPTION.UPDATED':
        await handleSubscriptionUpdated(resource);
        break;

      case 'BILLING.SUBSCRIPTION.EXPIRED':
      case 'BILLING.SUBSCRIPTION.CANCELLED':
        await handleSubscriptionCancelled(resource);
        break;

      case 'BILLING.SUBSCRIPTION.SUSPENDED':
        await handleSubscriptionSuspended(resource);
        break;

      default:
        console.log(`Unhandled event type: ${event_type}`);
    }

    // Return success response to PayPal
    res.json({ success: true, eventId: id });
  } catch (error) {
    console.error('Webhook processing error:', error);
    // Return 500 to signal PayPal to retry
    res.status(500).json({ error: error.message });
  }
});

/**
 * Handle subscription created event
 */
async function handleSubscriptionCreated(resource) {
  const userId = resource.custom_id;
  const subscriptionId = resource.id;
  const status = resource.status; // APPROVAL_PENDING, ACTIVE, SUSPENDED, CANCELLED, EXPIRED

  console.log(`Subscription created for user ${userId}:`, { subscriptionId, status });

  if (status !== 'ACTIVE' && status !== 'APPROVAL_PENDING') {
    console.warn(`Subscription not active. Status: ${status}`);
    return;
  }

  try {
    // Calculate expiry date (30 days from now)
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + 30);

    // Update user subscription status
    await db.collection('users').doc(userId).update({
      subscription_status: 'active',
      subscription_plan: 'chat_monthly',
      subscription_expiry_date: admin.firestore.Timestamp.fromDate(expiryDate),
      payment_gateway: 'paypal',
      auto_renew: true,
      paypal_subscription_id: subscriptionId,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send push notification to user
    await sendNotificationToUser(userId, {
      title: 'سند - اشتراك مفعل',
      titleEn: 'Sanad - Subscription Active',
      body: 'تم تفعيل اشتراكك بنجاح! يمكنك الآن الوصول للرسائل غير المحدودة.',
      bodyEn: 'Your subscription is now active! Enjoy unlimited messaging.',
    });

    console.log(`Subscription activated for user ${userId}`);
  } catch (error) {
    console.error(`Failed to update subscription for user ${userId}:`, error);
    throw error;
  }
}

/**
 * Handle subscription updated event
 */
async function handleSubscriptionUpdated(resource) {
  const userId = resource.custom_id;
  const subscriptionId = resource.id;
  const status = resource.status;

  console.log(`Subscription updated for user ${userId}:`, { status });

  try {
    // Update subscription status
    await db.collection('users').doc(userId).update({
      subscription_status: status === 'ACTIVE' ? 'active' : 'pending',
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error(`Failed to update subscription for user ${userId}:`, error);
  }
}

/**
 * Handle subscription cancelled or expired
 */
async function handleSubscriptionCancelled(resource) {
  const userId = resource.custom_id;
  const eventType = resource.event_type || 'cancelled';

  console.log(`Subscription ${eventType} for user ${userId}`);

  try {
    // Update user subscription status
    await db.collection('users').doc(userId).update({
      subscription_status: 'expired',
      subscription_plan: null,
      auto_renew: false,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification
    const isExpired = eventType.includes('EXPIRED');
    await sendNotificationToUser(userId, {
      title: isExpired ? 'سند - انتهى الاشتراك' : 'سند - تم الغاء الاشتراك',
      titleEn: isExpired ? 'Sanad - Subscription Expired' : 'Sanad - Subscription Cancelled',
      body: isExpired
        ? 'انتهت فترة اشتراكك. يمكنك التجديد في أي وقت.'
        : 'تم الغاء اشتراكك. يمكنك إعادة الاشتراك في أي وقت.',
      bodyEn: isExpired
        ? 'Your subscription has expired. You can renew anytime.'
        : 'Your subscription has been cancelled. You can resubscribe anytime.',
    });

    console.log(`Subscription ${eventType} for user ${userId}`);
  } catch (error) {
    console.error(
      `Failed to handle subscription ${eventType} for user ${userId}:`,
      error
    );
  }
}

/**
 * Handle subscription suspended (payment failed)
 */
async function handleSubscriptionSuspended(resource) {
  const userId = resource.custom_id;

  console.log(`Subscription suspended for user ${userId}`);

  try {
    // Update subscription to suspended
    await db.collection('users').doc(userId).update({
      subscription_status: 'pending',
      auto_renew: false,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification about payment failure
    await sendNotificationToUser(userId, {
      title: 'سند - فشل الدفع',
      titleEn: 'Sanad - Payment Failed',
      body: 'فشل الدفع لتجديد اشتراكك. يرجى تحديث بيانات الدفع.',
      bodyEn: 'Payment failed for your subscription renewal. Please update your payment method.',
    });

    console.log(`Sent payment failure notification to user ${userId}`);
  } catch (error) {
    console.error(`Failed to handle suspended subscription for user ${userId}:`, error);
  }
}

/**
 * Send push notification to user
 */
async function sendNotificationToUser(userId, message) {
  try {
    // Subscribe user to their UID topic for targeted messages
    const registrationTokens = await getRegistrationTokens(userId);

    if (registrationTokens && registrationTokens.length > 0) {
      await messaging.sendMulticast({
        notification: {
          title: message.titleEn, // Default to English for FCM
          body: message.bodyEn,
        },
        data: {
          titleAr: message.title,
          bodyAr: message.body,
          type: 'subscription_update',
        },
        tokens: registrationTokens,
      });

      console.log(`Sent notification to ${registrationTokens.length} devices`);
    } else {
      console.log(`No registration tokens found for user ${userId}`);
    }
  } catch (error) {
    console.warn(`Failed to send notification to user ${userId}:`, error);
    // Don't throw - notification failure shouldn't fail the webhook
  }
}

/**
 * Get FCM registration tokens for user
 * In production, store these in a separate collection
 */
async function getRegistrationTokens(userId) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const tokens = userDoc.data()?.fcm_tokens || [];
    // Remove expired tokens
    return tokens.filter(token => token && token.length > 0);
  } catch (error) {
    console.error(`Failed to get tokens for user ${userId}:`, error);
    return [];
  }
}

module.exports = { paypalWebhook };
