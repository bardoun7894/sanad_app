/**
 * Sanad App - Cloud Functions
 * Main entry point for Firebase Cloud Functions.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Admin SDK once
admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Import payment module
const paymentFunctions = require('./payments');

// Export Payment Functions (PayPal + Google Pay/Apple Pay via PayPal)
exports.createPayPalOrder = paymentFunctions.createPayPalOrder;
exports.capturePayPalOrder = paymentFunctions.capturePayPalOrder;
exports.createGooglePayOrder = paymentFunctions.createGooglePayOrder;
/**
 * Common notification helper - Enhanced with dynamic data payload
 * Fixed: Now reads from user_fcm_tokens collection
 */
async function sendNotificationToUser(userId, message) {
  try {
    // Check if user exists
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log(`User ${userId} not found`);
      return;
    }

    // Get FCM tokens from user_fcm_tokens collection
    const tokenDoc = await db.collection('user_fcm_tokens').doc(userId).get();
    if (!tokenDoc.exists) {
      console.log(`No FCM token document found for user ${userId}`);
      return;
    }

    const tokenData = tokenDoc.data();
    const tokenObjects = tokenData?.tokens || [];

    // Extract token strings from token objects
    const registrationTokens = tokenObjects
      .map(t => t?.token)
      .filter(token => token && typeof token === 'string' && token.length > 0);

    if (registrationTokens.length === 0) {
      console.log(`No valid FCM tokens found for user ${userId}`);
      return;
    }

    // Build data payload with all provided fields
    const dataPayload = {
      titleAr: message.title || '',
      bodyAr: message.body || '',
      type: message.type || 'general',
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    };

    // Add optional fields if provided
    if (message.bookingId) dataPayload.bookingId = message.bookingId;
    if (message.chatId) dataPayload.chatId = message.chatId;
    if (message.status) dataPayload.status = message.status;
    if (message.chatUserId) dataPayload.chatUserId = message.chatUserId;
    if (message.therapistId) dataPayload.therapistId = message.therapistId;

    const payload = {
      notification: {
        title: message.titleEn || message.title,
        body: message.bodyEn || message.body,
      },
      data: dataPayload,
      tokens: registrationTokens,
    };

    const response = await messaging.sendEachForMulticast(payload);

    // Clean up invalid tokens
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(registrationTokens[idx]);
        }
      });

      if (failedTokens.length > 0) {
        // Remove failed tokens from the tokens array
        const validTokenObjects = tokenObjects.filter(t => !failedTokens.includes(t?.token));
        await db.collection('user_fcm_tokens').doc(userId).update({
          tokens: validTokenObjects,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Removed ${failedTokens.length} invalid tokens for user ${userId}`);
      }
    }

    console.log(`✅ Sent notification to ${response.successCount}/${registrationTokens.length} devices for user ${userId}`);
  } catch (error) {
    console.warn(`❌ Failed to send notification to user ${userId}:`, error);
  }
}

// ============================================================================
// FIRESTORE TRIGGERS FOR PUSH NOTIFICATIONS
// ============================================================================

/**
 * 1. onBookingCreated - Notify therapist when new booking is created
 */
exports.onBookingCreated = functions.firestore
  .document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    const therapistId = booking.therapist_id;

    if (!therapistId) {
      console.log('No therapist_id in booking');
      return null;
    }

    const clientName = booking.client_name || 'عميل جديد';
    const scheduledTime = booking.scheduled_time?.toDate();

    let timeStr = '';
    if (scheduledTime) {
      timeStr = scheduledTime.toLocaleDateString('ar-SA', {
        weekday: 'long',
        hour: '2-digit',
        minute: '2-digit'
      });
    }

    await sendNotificationToUser(therapistId, {
      title: 'حجز جديد',
      body: `لديك طلب حجز جديد من ${clientName}${timeStr ? ' - ' + timeStr : ''}`,
      titleEn: 'New Booking Request',
      bodyEn: `New booking request from ${clientName}${timeStr ? ' - ' + timeStr : ''}`,
      type: 'new_booking',
      bookingId: context.params.bookingId,
    });

    // Also create an in-app notification
    await db.collection('notifications').add({
      user_id: therapistId,
      title: 'حجز جديد',
      title_en: 'New Booking Request',
      body: `لديك طلب حجز جديد من ${clientName}`,
      body_en: `New booking request from ${clientName}`,
      type: 'new_booking',
      data: { bookingId: context.params.bookingId },
      is_read: false,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });

/**
 * 2. onBookingStatusChanged - Notify client when booking status changes
 */
exports.onBookingStatusChanged = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only trigger if status actually changed
    if (before.status === after.status) return null;

    const clientId = after.client_id;
    if (!clientId) {
      console.log('No client_id in booking');
      return null;
    }

    const therapistName = after.therapist_name || 'المعالج';

    const statusMessages = {
      'confirmed': {
        ar: 'تم تأكيد حجزك',
        arBody: `تم قبول طلب الحجز مع ${therapistName}`,
        en: 'Booking Confirmed',
        enBody: `Your booking with ${therapistName} has been confirmed`
      },
      'cancelled': {
        ar: 'تم إلغاء الحجز',
        arBody: `تم إلغاء الحجز مع ${therapistName}`,
        en: 'Booking Cancelled',
        enBody: `Your booking with ${therapistName} has been cancelled`
      },
      'completed': {
        ar: 'تم إكمال الجلسة',
        arBody: `تمت جلستك مع ${therapistName} بنجاح`,
        en: 'Session Completed',
        enBody: `Your session with ${therapistName} has been completed`
      },
      'rejected': {
        ar: 'تم رفض الحجز',
        arBody: after.rejection_reason || `للأسف تم رفض طلب الحجز مع ${therapistName}`,
        en: 'Booking Declined',
        enBody: after.rejection_reason || `Your booking request with ${therapistName} was declined`
      },
    };

    const msg = statusMessages[after.status];
    if (!msg) return null;

    await sendNotificationToUser(clientId, {
      title: msg.ar,
      body: msg.arBody,
      titleEn: msg.en,
      bodyEn: msg.enBody,
      type: 'booking_status_changed',
      status: after.status,
      bookingId: context.params.bookingId,
    });

    // Also create in-app notification
    await db.collection('notifications').add({
      user_id: clientId,
      title: msg.ar,
      title_en: msg.en,
      body: msg.arBody,
      body_en: msg.enBody,
      type: 'booking_status_changed',
      data: { bookingId: context.params.bookingId, status: after.status },
      is_read: false,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });

/**
 * 3. onTherapistChatMessage - Notify recipient of new chat message
 */
exports.onTherapistChatMessage = functions.firestore
  .document('therapist_chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = context.params.chatId;

    // Get chat document to find participants
    const chatDoc = await db.collection('therapist_chats').doc(chatId).get();
    if (!chatDoc.exists) {
      console.log(`Chat ${chatId} not found`);
      return null;
    }

    const chat = chatDoc.data();
    const senderId = message.sender_id;

    // Determine recipient (the one who didn't send)
    const recipientId = senderId === chat.user_id
      ? chat.therapist_id
      : chat.user_id;

    if (!recipientId) {
      console.log('Could not determine recipient');
      return null;
    }

    const senderName = message.sender_name || 'مستخدم';
    const preview = message.content?.substring(0, 50) || 'رسالة جديدة';

    // CRITICAL FIX: Update chat thread metadata
    // This ensures the chat appears in the list and is sorted correctly
    const updateData = {
      last_message: message.content?.substring(0, 100) || '',
      last_message_time: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Increment unread count for the recipient
    if (senderId === chat.user_id) {
      // Message from user -> increment therapist unread count
      updateData.unread_count_therapist = admin.firestore.FieldValue.increment(1);
    } else {
      // Message from therapist -> increment user unread count
      updateData.unread_count_user = admin.firestore.FieldValue.increment(1);
    }

    // Update chat thread
    await db.collection('therapist_chats').doc(chatId).update(updateData);

    // Send notification to recipient
    await sendNotificationToUser(recipientId, {
      title: 'رسالة جديدة',
      body: `${senderName}: ${preview}${message.content?.length > 50 ? '...' : ''}`,
      titleEn: 'New Message',
      bodyEn: `${senderName}: ${preview}${message.content?.length > 50 ? '...' : ''}`,
      type: 'therapist_chat_message',
      chatId: chatId,
    });

    return null;
  });

/**
 * 4. onTherapistApprovalChanged - Notify therapist when approval status changes
 */
exports.onTherapistApprovalChanged = functions.firestore
  .document('therapists/{therapistId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only trigger if approval_status changed
    if (before.approval_status === after.approval_status) return null;

    const therapistId = context.params.therapistId;

    const statusMessages = {
      'approved': {
        title: 'مبروك! تمت الموافقة',
        body: 'تم اعتماد ملفك كمعالج. يمكنك الآن استقبال الحجوزات.',
        titleEn: 'Congratulations! Approved',
        bodyEn: 'Your therapist profile has been approved. You can now receive bookings.',
      },
      'rejected': {
        title: 'تم رفض الطلب',
        body: after.rejection_reason || 'للأسف لم تتم الموافقة على طلبك. يرجى التواصل مع الدعم.',
        titleEn: 'Application Rejected',
        bodyEn: after.rejection_reason || 'Unfortunately your application was not approved. Please contact support.',
      },
      'suspended': {
        title: 'تم تعليق الحساب',
        body: 'تم تعليق حسابك مؤقتاً. تواصل مع الدعم لمزيد من المعلومات.',
        titleEn: 'Account Suspended',
        bodyEn: 'Your account has been suspended. Contact support for more information.',
      },
    };

    const msg = statusMessages[after.approval_status];
    if (!msg) return null;

    await sendNotificationToUser(therapistId, {
      ...msg,
      type: 'therapist_approval_status',
      status: after.approval_status,
      therapistId: therapistId,
    });

    // Also create in-app notification
    await db.collection('notifications').add({
      user_id: therapistId,
      title: msg.title,
      title_en: msg.titleEn,
      body: msg.body,
      body_en: msg.bodyEn,
      type: 'therapist_approval_status',
      data: { status: after.approval_status },
      is_read: false,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return null;
  });

/**
 * 5. onSupportChatMessage - Notify admins of new support message from user
 */
exports.onSupportChatMessage = functions.firestore
  .document('support_chats/{userId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const userId = context.params.userId;

    // Case 1: Message is from USER -> notify all ADMINS
    if (message.sender_id === userId) {
      // Get all admin users
      const adminsQuery = await db.collection('users')
        .where('role', '==', 'admin')
        .get();

      if (adminsQuery.empty) {
        console.log('No admin users found');
        return null;
      }

      // Get user info for the notification
      const userDoc = await db.collection('users').doc(userId).get();
      const userName = userDoc.exists ? (userDoc.data().display_name || userDoc.data().name || 'مستخدم') : 'مستخدم';
      const preview = message.content?.substring(0, 50) || 'رسالة دعم جديدة';

      // Notify all admins
      const notifications = adminsQuery.docs.map(adminDoc =>
        sendNotificationToUser(adminDoc.id, {
          title: 'رسالة دعم جديدة',
          body: `${userName}: ${preview}${message.content?.length > 50 ? '...' : ''}`,
          titleEn: 'New Support Message',
          bodyEn: `${userName}: ${preview}${message.content?.length > 50 ? '...' : ''}`,
          type: 'support_chat_message',
          chatUserId: userId,
        })
      );

      await Promise.all(notifications);
      return null;
    }

    // Case 2: Message is from ADMIN -> notify the USER
    if (message.sender_id === 'admin') {
      const preview = message.content?.substring(0, 50) || 'رسالة جديدة من الدعم';

      await sendNotificationToUser(userId, {
        title: 'رد من الدعم',
        body: preview + (message.content?.length > 50 ? '...' : ''),
        titleEn: 'Support Reply',
        bodyEn: preview + (message.content?.length > 50 ? '...' : ''),
        type: 'support_chat_message',
        chatUserId: userId,
      });

      // Also create in-app notification
      await db.collection('notifications').add({
        user_id: userId,
        title: 'رد من الدعم',
        title_en: 'Support Reply',
        body: preview,
        body_en: preview,
        type: 'support_chat_reply',
        data: { chatUserId: userId },
        is_read: false,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }

    return null;
  });

// ============================================================================
// FIREBASE CUSTOM CLAIMS FOR ROLE-BASED ACCESS
// ============================================================================

/**
 * Callable function to set admin custom claim
 * Can only be called by existing admins or super admin email
 */
exports.setAdminClaim = functions.https.onCall(async (data, context) => {
  // Verify caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to set admin claims'
    );
  }

  const callerUid = context.auth.uid;
  const callerEmail = context.auth.token.email;
  const targetUid = data.uid;
  const makeAdmin = data.admin === true;

  // Check if caller is authorized (super admin email or has admin claim)
  const isSuperAdmin = callerEmail === 'mbardouni44@gmail.com';
  const hasAdminClaim = context.auth.token.admin === true;

  if (!isSuperAdmin && !hasAdminClaim) {
    // Also check Firestore as fallback
    const callerDoc = await db.collection('users').doc(callerUid).get();
    if (!callerDoc.exists || callerDoc.data().role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can set admin claims'
      );
    }
  }

  if (!targetUid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Target user UID is required'
    );
  }

  try {
    // Set custom claims
    await admin.auth().setCustomUserClaims(targetUid, {
      admin: makeAdmin,
      role: makeAdmin ? 'admin' : 'user',
    });

    // Also update Firestore for consistency
    await db.collection('users').doc(targetUid).update({
      role: makeAdmin ? 'admin' : 'user',
      custom_claims_synced: true,
      claims_updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Set admin claim for user ${targetUid}: ${makeAdmin}`);

    return {
      success: true,
      message: `Admin claim ${makeAdmin ? 'granted' : 'revoked'} for user ${targetUid}`,
    };
  } catch (error) {
    console.error('Error setting admin claim:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Callable function to set therapist custom claim
 * Can only be called by admins
 */
exports.setTherapistClaim = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated'
    );
  }

  const callerEmail = context.auth.token.email;
  const isSuperAdmin = callerEmail === 'mbardouni44@gmail.com';
  const hasAdminClaim = context.auth.token.admin === true;

  if (!isSuperAdmin && !hasAdminClaim) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can set therapist claims'
    );
  }

  const targetUid = data.uid;
  const makeTherapist = data.therapist === true;
  const approvalStatus = data.approvalStatus || 'pending';

  if (!targetUid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Target user UID is required'
    );
  }

  try {
    await admin.auth().setCustomUserClaims(targetUid, {
      therapist: makeTherapist,
      role: makeTherapist ? 'therapist' : 'user',
      approvalStatus: makeTherapist ? approvalStatus : null,
    });

    console.log(`Set therapist claim for user ${targetUid}: ${makeTherapist}`);

    return {
      success: true,
      message: `Therapist claim ${makeTherapist ? 'granted' : 'revoked'} for user ${targetUid}`,
    };
  } catch (error) {
    console.error('Error setting therapist claim:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Trigger: Sync custom claims when user role changes in Firestore
 */
exports.onUserRoleChanged = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    // Only trigger if role actually changed
    if (before.role === after.role) return null;

    const newRole = after.role;
    console.log(`User ${userId} role changed from ${before.role} to ${newRole}`);

    try {
      // Build claims based on new role
      const claims = {
        role: newRole,
      };

      if (newRole === 'admin') {
        claims.admin = true;
        claims.therapist = false;
      } else if (newRole === 'therapist') {
        claims.admin = false;
        claims.therapist = true;
        claims.approvalStatus = after.therapist_status || 'pending';
      } else {
        claims.admin = false;
        claims.therapist = false;
      }

      await admin.auth().setCustomUserClaims(userId, claims);

      // Mark as synced
      await db.collection('users').doc(userId).update({
        custom_claims_synced: true,
        claims_updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Custom claims synced for user ${userId}:`, claims);
    } catch (error) {
      console.error(`Error syncing claims for user ${userId}:`, error);
    }

    return null;
  });

/**
 * Trigger: Sync approval status to claims when therapist status changes
 */
exports.onTherapistStatusChanged = functions.firestore
  .document('therapists/{therapistId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const therapistId = context.params.therapistId;

    // Only trigger if approval_status changed
    if (before.approval_status === after.approval_status) return null;

    const newStatus = after.approval_status;
    console.log(`Therapist ${therapistId} status changed to ${newStatus}`);

    try {
      // Get current claims
      const user = await admin.auth().getUser(therapistId);
      const currentClaims = user.customClaims || {};

      // Update claims with new approval status
      const newClaims = {
        ...currentClaims,
        therapist: true,
        role: 'therapist',
        approvalStatus: newStatus,
      };

      await admin.auth().setCustomUserClaims(therapistId, newClaims);

      // Also sync to users collection
      await db.collection('users').doc(therapistId).update({
        therapist_status: newStatus,
        custom_claims_synced: true,
        claims_updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Therapist claims synced for ${therapistId}:`, newClaims);
    } catch (error) {
      console.error(`Error syncing therapist claims for ${therapistId}:`, error);
    }

    return null;
  });

/**
 * 6. onPaymentVerificationCreated - Notify admins when a user uploads a bank receipt
 */
exports.onPaymentVerificationCreated = functions.firestore
  .document('payment_verifications/{verificationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userId = data.user_id;

    // Get all admin users
    const adminsQuery = await db.collection('users')
      .where('role', '==', 'admin')
      .get();

    if (adminsQuery.empty) return null;

    // Get user info
    const userDoc = await db.collection('users').doc(userId).get();
    const userName = userDoc.exists ? (userDoc.data().display_name || userDoc.data().name || 'مستخدم') : 'مستخدم';

    // Notify all admins
    const notifications = adminsQuery.docs.map(adminDoc =>
      sendNotificationToUser(adminDoc.id, {
        title: 'إيصال دفع جديد',
        body: `قام ${userName} بتحميل إيصال دعم جديد للمراجعة`,
        titleEn: 'New Payment Receipt',
        bodyEn: `${userName} uploaded a new payment receipt for verification`,
        type: 'payment_verification',
        verificationId: context.params.verificationId,
      })
    );

    await Promise.all(notifications);
    return null;
  });

/**
 * 7. chatWithGemini - Secure backend-only Gemini API proxy
 */
const { GoogleGenerativeAI } = require("@google/generative-ai");

exports.chatWithGemini = functions.https.onCall(async (data, context) => {
  // 1. Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { messages, userMood } = data;

  // 2. Secret Configuration check
  // Note: Set this in CLI via: firebase functions:config:set gemini.key="YOUR_KEY"
  const apiKey = functions.config().gemini ? functions.config().gemini.key : null;

  if (!apiKey) {
    console.error('Gemini API key not configured in functions config');
    throw new functions.https.HttpsError('failed-precondition', 'AI Service temporarily unavailable');
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    // Format history for Gemini SDK
    // Sanad messages are {role: 'user'|'model', parts: [{text: '...'}]}
    const chat = model.startChat({
      history: messages.slice(0, -1), // Everything but last message
      generationConfig: {
        maxOutputTokens: 1000,
      },
    });

    const lastMessage = messages[messages.length - 1].parts[0].text;
    const result = await chat.sendMessage(lastMessage);
    const response = await result.response;
    const text = response.text();

    return {
      content: text,
      model: "gemini-1.5-flash",
      tokensUsed: response.usageMetadata?.totalTokenCount || 0
    };
  } catch (error) {
    console.error('Gemini API Error:', error);
    throw new functions.https.HttpsError('internal', 'AI generation failed');
  }
});

/**
 * 8. scheduledBookingReminders - Send reminders 1 hour before session
 * Runs every 15 minutes
 */
exports.scheduledBookingReminders = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const sixtyMinsFromNow = new admin.firestore.Timestamp(now.seconds + 3600, now.nanoseconds);
    const seventyFiveMinsFromNow = new admin.firestore.Timestamp(now.seconds + 4500, now.nanoseconds);

    // Find sessions starting in the next 60-75 mins
    const bookings = await db.collection('bookings')
      .where('status', '==', 'confirmed')
      .where('scheduled_time', '>=', sixtyMinsFromNow)
      .where('scheduled_time', '<=', seventyFiveMinsFromNow)
      .get();

    if (bookings.empty) return null;

    const reminders = [];
    bookings.forEach(doc => {
      const booking = doc.data();

      // Notify Client
      reminders.push(sendNotificationToUser(booking.client_id, {
        title: 'تذكير بجلسة',
        body: `تبدأ جلستك مع ${booking.therapist_name} خلال ساعة`,
        titleEn: 'Session Reminder',
        bodyEn: `Your session with ${booking.therapist_name} starts in 1 hour`,
        type: 'session_reminder',
        bookingId: doc.id,
      }));

      // Notify Therapist
      reminders.push(sendNotificationToUser(booking.therapist_id, {
        title: 'تذكير بجلسة قادمة',
        body: `تبدأ جلستك مع ${booking.client_name} خلال ساعة`,
        titleEn: 'Upcoming Session Reminder',
        bodyEn: `Your session with ${booking.client_name} starts in 1 hour`,
        type: 'session_reminder',
        bookingId: doc.id,
      }));
    });

    await Promise.all(reminders);
    console.log(`Sent ${reminders.length} session reminders`);
    return null;
  });

/**
 * 9. checkSubscriptionExpirations - Daily cleanup of expired subscriptions
 */
exports.checkSubscriptionExpirations = functions.pubsub
  .schedule('0 0 * * *') // Every day at midnight
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // Find active subscriptions that have expired
    const expiredUsers = await db.collection('users')
      .where('subscription_state', '==', 'active')
      .where('subscription_expiry', '<', now)
      .get();

    if (expiredUsers.empty) return null;

    const updates = [];
    expiredUsers.forEach(doc => {
      updates.push(doc.ref.update({
        subscription_state: 'free',
        subscription_plan: 'free',
        subscription_expiry: null,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }));

      // Notify the user
      updates.push(sendNotificationToUser(doc.id, {
        title: 'انتهى اشتراكك',
        body: 'انتهت صلاحية اشتراكك المميز. انقر هنا للتجديد.',
        titleEn: 'Subscription Expired',
        bodyEn: 'Your premium subscription has expired. Click here to renew.',
        type: 'subscription_expired',
      }));
    });

    await Promise.all(updates);
    console.log(`Processed ${expiredUsers.size} expired subscriptions`);
    return null;
  });


