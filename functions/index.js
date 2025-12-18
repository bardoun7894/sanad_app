/**
 * Sanad App - Cloud Functions
 * Main entry point for Firebase Cloud Functions.
 */

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

// Initialize Admin SDK once
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Common notification helper
 */
async function sendNotificationToUser(userId, message) {
          try {
                    const userDoc = await db.collection('users').doc(userId).get();
                    const tokens = userDoc.data()?.fcm_tokens || [];
                    const registrationTokens = tokens.filter(token => token && token.length > 0);

                    if (registrationTokens.length > 0) {
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
                              console.log(`Sent notification to ${registrationTokens.length} devices for user ${userId}`);
                    } else {
                              console.log(`No registration tokens found for user ${userId}`);
                    }
          } catch (error) {
                    console.warn(`Failed to send notification to user ${userId}:`, error);
          }
}

/**
 * 1. PayPal Webhook Handler
 */
exports.paypalWebhook = onRequest({ region: 'us-central1' }, async (req, res) => {
          if (req.method !== 'POST') {
                    return res.status(405).json({ error: 'Method not allowed' });
          }

          try {
                    const { event_type, id, resource } = req.body;
                    console.log(`PayPal Webhook Received: ${event_type}`, { webhookId: id, userId: resource?.custom_id });

                    switch (event_type) {
                              case 'BILLING.SUBSCRIPTION.CREATED':
                                        await handlePaypalSubscriptionCreated(resource);
                                        break;
                              case 'BILLING.SUBSCRIPTION.UPDATED':
                                        await handlePaypalSubscriptionUpdated(resource);
                                        break;
                              case 'BILLING.SUBSCRIPTION.EXPIRED':
                              case 'BILLING.SUBSCRIPTION.CANCELLED':
                                        await handlePaypalSubscriptionCancelled(resource, event_type);
                                        break;
                              case 'BILLING.SUBSCRIPTION.SUSPENDED':
                                        await handlePaypalSubscriptionSuspended(resource);
                                        break;
                              default:
                                        console.log(`Unhandled event type: ${event_type}`);
                    }

                    res.json({ success: true, eventId: id });
          } catch (error) {
                    console.error('PayPal Webhook error:', error);
                    res.status(500).json({ error: error.message });
          }
});

/**
 * 2. 2Checkout Webhook Handler
 */
exports.checkoutWebhook = onRequest({ region: 'us-central1' }, async (req, res) => {
          if (req.method !== 'POST') {
                    return res.status(405).json({ error: 'Method not allowed' });
          }

          try {
                    const { event_type, data } = req.body;
                    console.log(`2Checkout Webhook Received: ${event_type}`, { orderId: data?.order_id });

                    switch (event_type) {
                              case 'subscription_activated':
                                        await handleCheckoutSubscriptionActivated(data);
                                        break;
                              case 'subscription_renewed':
                                        await handleCheckoutSubscriptionRenewed(data);
                                        break;
                              case 'subscription_cancelled':
                                        await handleCheckoutSubscriptionCancelled(data);
                                        break;
                              case 'charge_failed':
                                        await handleCheckoutChargeFailed(data);
                                        break;
                              case 'charge_disputed':
                                        await handleCheckoutChargeDisputed(data);
                                        break;
                              default:
                                        console.log(`Unhandled event type: ${event_type}`);
                    }

                    res.json({ success: true });
          } catch (error) {
                    console.error('2Checkout Webhook error:', error);
                    res.status(500).json({ error: error.message });
          }
});

/* --- PayPal Helpers --- */

async function handlePaypalSubscriptionCreated(resource) {
          const userId = resource.custom_id;
          if (!userId) return;

          const expiryDate = new Date();
          expiryDate.setDate(expiryDate.getDate() + 30);

          await db.collection('users').doc(userId).update({
                    subscription_status: 'active',
                    subscription_plan: 'chat_monthly',
                    subscription_expiry_date: admin.firestore.Timestamp.fromDate(expiryDate),
                    payment_gateway: 'paypal',
                    auto_renew: true,
                    paypal_subscription_id: resource.id,
                    updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });

          await sendNotificationToUser(userId, {
                    title: 'سند - اشتراك مفعل',
                    titleEn: 'Sanad - Subscription Active',
                    body: 'تم تفعيل اشتراكك بنجاح! يمكنك الآن الوصول للرسائل غير المحدودة.',
                    bodyEn: 'Your subscription is now active! Enjoy unlimited messaging.',
          });
}

async function handlePaypalSubscriptionUpdated(resource) {
          const userId = resource.custom_id;
          if (!userId) return;
          await db.collection('users').doc(userId).update({
                    subscription_status: resource.status === 'ACTIVE' ? 'active' : 'pending',
                    updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
}

async function handlePaypalSubscriptionCancelled(resource, type) {
          const userId = resource.custom_id;
          if (!userId) return;
          await db.collection('users').doc(userId).update({
                    subscription_status: 'expired',
                    subscription_plan: null,
                    auto_renew: false,
                    updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });

          const isExpired = type.includes('EXPIRED');
          await sendNotificationToUser(userId, {
                    title: isExpired ? 'سند - انتهى الاشتراك' : 'سند - تم الغاء الاشتراك',
                    titleEn: isExpired ? 'Sanad - Subscription Expired' : 'Sanad - Subscription Cancelled',
                    body: isExpired ? 'انتهت فترة اشتراكك. يمكنك التجديد في أي وقت.' : 'تم الغاء اشتراكك. يمكنك إعادة الاشتراك في أي وقت.',
                    bodyEn: isExpired ? 'Your subscription has expired. You can renew anytime.' : 'Your subscription has been cancelled. You can resubscribe anytime.',
          });
}

async function handlePaypalSubscriptionSuspended(resource) {
          const userId = resource.custom_id;
          if (!userId) return;
          await db.collection('users').doc(userId).update({
                    subscription_status: 'pending',
                    auto_renew: false,
                    updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });

          await sendNotificationToUser(userId, {
                    title: 'سند - فشل الدفع',
                    titleEn: 'Sanad - Payment Failed',
                    body: 'فشل الدفع لتجديد اشتراكك. يرجى تحديث بيانات الدفع.',
                    bodyEn: 'Payment failed for your subscription renewal. Please update your payment method.',
          });
}

/* --- 2Checkout Helpers --- */

async function handleCheckoutSubscriptionActivated(data) {
          const userId = data.custom_product_id;
          if (!userId) return;

          const expiryDate = new Date();
          expiryDate.setDate(expiryDate.getDate() + 30);

          await db.collection('users').doc(userId).update({
                    subscription_status: 'active',
                    subscription_plan: 'chat_monthly',
                    subscription_expiry_date: admin.firestore.Timestamp.fromDate(expiryDate),
                    payment_gateway: '2checkout',
                    auto_renew: true,
                    order_id: data.order_id,
                    subscription_id: data.subscription_id,
                    updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });

          await db.collection('payments').add({
                    user_id: userId,
                    amount: 5.0,
                    currency: 'USD',
                    status: 'completed',
                    payment_method: 'card',
                    gateway_transaction_id: data.order_id,
                    created_at: admin.firestore.FieldValue.serverTimestamp(),
          });

          await sendNotificationToUser(userId, {
                    title: 'سند - اشتراك مفعل',
                    titleEn: 'Sanad - Subscription Active',
                    body: 'تم تفعيل اشتراكك بنجاح! يمكنك الآن الوصول للرسائل غير المحدودة.',
                    bodyEn: 'Your subscription is now active! Enjoy unlimited messaging.',
          });
}

async function handleCheckoutSubscriptionRenewed(data) {
          const userId = data.custom_product_id;
          if (!userId) return;

          const expiryDate = new Date();
          expiryDate.setDate(expiryDate.getDate() + 30);

          await db.collection('users').doc(userId).update({
                    subscription_status: 'active',
                    subscription_expiry_date: admin.firestore.Timestamp.fromDate(expiryDate),
                    updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });

          await db.collection('payments').add({
                    user_id: userId,
                    amount: 5.0,
                    currency: 'USD',
                    status: 'completed',
                    payment_method: 'card',
                    gateway_transaction_id: data.order_id,
                    created_at: admin.firestore.FieldValue.serverTimestamp(),
          });
}

async function handleCheckoutSubscriptionCancelled(data) {
          const userId = data.custom_product_id;
          if (!userId) return;
          await db.collection('users').doc(userId).update({
                    subscription_status: 'cancelled',
                    auto_renew: false,
                    updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
}

async function handleCheckoutChargeFailed(data) {
          const userId = data.custom_product_id;
          if (!userId) return;
          await db.collection('users').doc(userId).update({
                    subscription_status: 'pending',
                    auto_renew: false,
                    updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
}

async function handleCheckoutChargeDisputed(data) {
          const userId = data.custom_product_id;
          if (!userId) return;
          await db.collection('users').doc(userId).update({
                    subscription_status: 'disputed',
                    updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
}
