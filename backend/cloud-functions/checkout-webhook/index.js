/**
 * 2Checkout Webhook Handler Cloud Function
 *
 * This function processes webhook events from 2Checkout (Verifone) for payment processing.
 *
 * Events handled:
 * - subscription_activated: Subscription purchased/activated
 * - subscription_renewed: Subscription renewed
 * - subscription_cancelled: Subscription cancelled
 * - charge_disputed: Payment disputed
 * - charge_failed: Payment failed
 *
 * Deploy with:
 * gcloud functions deploy checkoutWebhook --gen2 --runtime nodejs18 --trigger-http --allow-unauthenticated
 */

const functions = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const checkoutWebhook = functions.onRequest(async (req, res) => {
  // Only accept POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // 2Checkout sends event data in different ways depending on event type
    const { event_type, data } = req.body;

    // Log incoming webhook for debugging
    console.log(`2Checkout Webhook Received: ${event_type}`, {
      customProductId: data?.custom_product_id,
      orderId: data?.order_id,
      timestamp: data?.timestamp,
    });

    // Handle different event types
    switch (event_type) {
      case 'subscription_activated':
        await handleSubscriptionActivated(data);
        break;

      case 'subscription_renewed':
        await handleSubscriptionRenewed(data);
        break;

      case 'subscription_cancelled':
        await handleSubscriptionCancelled(data);
        break;

      case 'charge_failed':
        await handleChargeFailed(data);
        break;

      case 'charge_disputed':
        await handleChargeDisputed(data);
        break;

      default:
        console.log(`Unhandled event type: ${event_type}`);
    }

    // Return success response to 2Checkout
    res.json({ success: true });
  } catch (error) {
    console.error('Webhook processing error:', error);
    // Return 500 to signal 2Checkout to retry
    res.status(500).json({ error: error.message });
  }
});

/**
 * Handle subscription activated
 */
async function handleSubscriptionActivated(data) {
  const userId = data.custom_product_id;
  const orderId = data.order_id;
  const subscriptionId = data.subscription_id;

  console.log(`Subscription activated for user ${userId}:`, {
    orderId,
    subscriptionId,
  });

  try {
    // Calculate expiry date (30 days from now)
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + 30);

    // Update user subscription status
    await db.collection('users').doc(userId).update({
      subscription_status: 'active',
      subscription_plan: 'chat_monthly',
      subscription_expiry_date: admin.firestore.Timestamp.fromDate(expiryDate),
      payment_gateway: '2checkout',
      auto_renew: true,
      order_id: orderId,
      subscription_id: subscriptionId,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create payment record
    await db.collection('payments').add({
      user_id: userId,
      amount: 5.0,
      currency: 'USD',
      status: 'completed',
      payment_method: 'card',
      gateway_transaction_id: orderId,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
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
    console.error(`Failed to activate subscription for user ${userId}:`, error);
    throw error;
  }
}

/**
 * Handle subscription renewed
 */
async function handleSubscriptionRenewed(data) {
  const userId = data.custom_product_id;
  const orderId = data.order_id;

  console.log(`Subscription renewed for user ${userId}:`, { orderId });

  try {
    // Calculate new expiry date (30 days from now)
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + 30);

    // Update user subscription status
    await db.collection('users').doc(userId).update({
      subscription_status: 'active',
      subscription_expiry_date: admin.firestore.Timestamp.fromDate(expiryDate),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create payment record
    await db.collection('payments').add({
      user_id: userId,
      amount: 5.0,
      currency: 'USD',
      status: 'completed',
      payment_method: 'card',
      gateway_transaction_id: orderId,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification
    await sendNotificationToUser(userId, {
      title: 'سند - تم تجديد الاشتراك',
      titleEn: 'Sanad - Subscription Renewed',
      body: 'تم تجديد اشتراكك بنجاح.',
      bodyEn: 'Your subscription has been renewed successfully.',
    });

    console.log(`Subscription renewed for user ${userId}`);
  } catch (error) {
    console.error(`Failed to renew subscription for user ${userId}:`, error);
  }
}

/**
 * Handle subscription cancelled
 */
async function handleSubscriptionCancelled(data) {
  const userId = data.custom_product_id;
  const subscriptionId = data.subscription_id;

  console.log(`Subscription cancelled for user ${userId}:`, { subscriptionId });

  try {
    // Update subscription status
    await db.collection('users').doc(userId).update({
      subscription_status: 'cancelled',
      auto_renew: false,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification
    await sendNotificationToUser(userId, {
      title: 'سند - تم الغاء الاشتراك',
      titleEn: 'Sanad - Subscription Cancelled',
      body: 'تم الغاء اشتراكك. يمكنك إعادة الاشتراك في أي وقت.',
      bodyEn: 'Your subscription has been cancelled. You can resubscribe anytime.',
    });

    console.log(`Subscription cancelled for user ${userId}`);
  } catch (error) {
    console.error(`Failed to cancel subscription for user ${userId}:`, error);
  }
}

/**
 * Handle charge failed
 */
async function handleChargeFailed(data) {
  const userId = data.custom_product_id;
  const orderId = data.order_id;
  const reason = data.reason || 'Unknown reason';

  console.log(`Charge failed for user ${userId}:`, { orderId, reason });

  try {
    // Update subscription to pending (payment failed)
    await db.collection('users').doc(userId).update({
      subscription_status: 'pending',
      auto_renew: false,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create failed payment record
    await db.collection('payments').add({
      user_id: userId,
      amount: 5.0,
      currency: 'USD',
      status: 'failed',
      payment_method: 'card',
      gateway_transaction_id: orderId,
      error_reason: reason,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification
    await sendNotificationToUser(userId, {
      title: 'سند - فشل الدفع',
      titleEn: 'Sanad - Payment Failed',
      body: `فشل الدفع: ${reason}. يرجى تحديث بيانات الدفع.`,
      bodyEn: `Payment failed: ${reason}. Please update your payment method.`,
    });

    console.log(`Charge failed notification sent to user ${userId}`);
  } catch (error) {
    console.error(`Failed to handle charge failure for user ${userId}:`, error);
  }
}

/**
 * Handle charge disputed
 */
async function handleChargeDisputed(data) {
  const userId = data.custom_product_id;
  const orderId = data.order_id;
  const reason = data.reason || 'Charge disputed';

  console.log(`Charge disputed for user ${userId}:`, { orderId, reason });

  try {
    // Create dispute record in payments
    await db.collection('payments').add({
      user_id: userId,
      amount: 5.0,
      currency: 'USD',
      status: 'disputed',
      payment_method: 'card',
      gateway_transaction_id: orderId,
      dispute_reason: reason,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification about dispute
    await sendNotificationToUser(userId, {
      title: 'سند - نزاع في الدفع',
      titleEn: 'Sanad - Payment Dispute',
      body: 'تم تسجيل نزاع على دفعتك. سيتصل بك فريق الدعم قريباً.',
      bodyEn: 'A dispute has been filed on your payment. Our team will contact you soon.',
    });

    console.log(`Dispute notification sent to user ${userId}`);
  } catch (error) {
    console.error(`Failed to handle dispute for user ${userId}:`, error);
  }
}

/**
 * Send push notification to user
 */
async function sendNotificationToUser(userId, message) {
  try {
    // Get registration tokens for user
    const registrationTokens = await getRegistrationTokens(userId);

    if (registrationTokens && registrationTokens.length > 0) {
      await messaging.sendMulticast({
        notification: {
          title: message.titleEn,
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
 */
async function getRegistrationTokens(userId) {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    const tokens = userDoc.data()?.fcm_tokens || [];
    return tokens.filter(token => token && token.length > 0);
  } catch (error) {
    console.error(`Failed to get tokens for user ${userId}:`, error);
    return [];
  }
}

module.exports = { checkoutWebhook };
