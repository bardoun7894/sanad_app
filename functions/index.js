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

// Import payment modules
const paymentFunctions = require('./payments');
const freemiusFunctions = require('./freemius');

// Export Payment Functions (PayPal + Google Pay/Apple Pay via PayPal)
exports.createPayPalOrder = paymentFunctions.createPayPalOrder;
exports.capturePayPalOrder = paymentFunctions.capturePayPalOrder;
exports.createGooglePayOrder = paymentFunctions.createGooglePayOrder;

// Export Freemius Functions
exports.getFreemiusCheckoutUrl = freemiusFunctions.getFreemiusCheckoutUrl;
exports.verifyFreemiusPurchase = freemiusFunctions.verifyFreemiusPurchase;
exports.freemiusWebhook = freemiusFunctions.freemiusWebhook;
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

    // Only notify therapist after payment is complete.
    // Bookings start with status='awaiting_payment'; the pending→paid
    // transition is handled by onBookingStatusChanged instead.
    if (booking.payment_status !== 'paid' && booking.status !== 'pending') {
      console.log(`Skip onBookingCreated for ${context.params.bookingId}: not yet paid (status=${booking.status})`);
      return null;
    }

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

    // ── Chat access gate stamping ──────────────────────────────────────────
    // Runs for every status change so all transitions (pending, confirmed,
    // completed) are captured. Must run BEFORE the notification branches that
    // return early (e.g. the pending branch returns early for 'pending').
    // Uses _chatTherapistId/_chatClientId to avoid shadowing the later
    // notification-block declarations of the same names at function scope.
    {
      const _chatTherapistId = after.therapist_id;
      const _chatClientId    = after.client_id;

      if (_chatTherapistId && _chatClientId) {
        const _chatDocId = `${_chatTherapistId}_${_chatClientId}`;
        const _chatRef   = db.collection('therapist_chats').doc(_chatDocId);

        let _newAccess = null; // null = no change needed

        if (
          after.payment_status === 'paid' &&
          (after.status === 'pending' || after.status === 'confirmed')
        ) {
          _newAccess = 'full';
        } else if (after.status === 'completed') {
          // Keep 'full' if user has an active subscription with this therapist.
          let _keepFull = false;
          try {
            const _userSnap = await db.collection('users').doc(_chatClientId).get();
            if (_userSnap.exists) {
              const _ud = _userSnap.data();
              _keepFull = _ud.is_premium === true &&
                          _ud.assigned_therapist_id === _chatTherapistId;
            }
          } catch (e) {
            console.warn(
              `onBookingStatusChanged: could not read users/${_chatClientId}: ${e.message}`,
            );
          }
          _newAccess = _keepFull ? 'full' : 'read_only';
        }

        if (_newAccess !== null) {
          try {
            await _chatRef.set(
              {
                user_access: _newAccess,
                user_id: _chatClientId,
                therapist_id: _chatTherapistId,
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
              },
              { merge: true }
            );
            console.log(
              `onBookingStatusChanged: set therapist_chats/${_chatDocId}.user_access='${_newAccess}'`,
            );
          } catch (e) {
            console.warn(
              `onBookingStatusChanged: failed to stamp chat access: ${e.message}`,
            );
          }
        }
      }
    }
    // ── End chat access gate ───────────────────────────────────────────────

    // When status transitions to 'pending', payment is confirmed — notify the
    // therapist (not the client) so they can Accept/Reject the booking.
    if (after.status === 'pending') {
      const therapistId = after.therapist_id;
      if (!therapistId) {
        console.log('No therapist_id in booking for pending notification');
        return null;
      }

      const clientName = after.client_name || 'عميل جديد';
      const scheduledTime = after.scheduled_time?.toDate();
      let timeStr = '';
      if (scheduledTime) {
        timeStr = scheduledTime.toLocaleDateString('ar-SA', {
          weekday: 'long',
          hour: '2-digit',
          minute: '2-digit',
        });
      }

      await sendNotificationToUser(therapistId, {
        title: 'حجز جديد',
        body: `لديك طلب حجز جديد مدفوع من ${clientName}${timeStr ? ' - ' + timeStr : ''}`,
        titleEn: 'New Booking Request',
        bodyEn: `New paid booking request from ${clientName}${timeStr ? ' - ' + timeStr : ''}`,
        type: 'new_booking',
        bookingId: context.params.bookingId,
      });

      await db.collection('notifications').add({
        user_id: therapistId,
        title: 'حجز جديد',
        title_en: 'New Booking Request',
        body: `لديك طلب حجز جديد مدفوع من ${clientName}`,
        body_en: `New paid booking request from ${clientName}`,
        type: 'new_booking',
        data: { bookingId: context.params.bookingId },
        is_read: false,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }

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
 * Callable: Link an admin-created therapists doc to the matching Firebase
 * Auth account by email.
 *
 * The admin creates therapists with a generated Firestore doc ID. Later,
 * the therapist signs into the portal with Firebase Auth, getting a
 * different uid. Result: nothing connects — the therapist's auth uid
 * does not equal the therapists doc ID, so users.assigned_therapist_id
 * (which points at the doc ID) never matches the portal's authUid query.
 *
 * This function fixes one therapist:
 *   1. Look up auth user by therapists/{oldDocId}.email.
 *   2. If found and authUid !== oldDocId, copy the doc to
 *      therapists/{authUid}, copy users/{oldDocId} → users/{authUid}.
 *   3. Rewrite every users.assigned_therapist_id == oldDocId to authUid.
 *   4. Delete the old therapists/{oldDocId} + users/{oldDocId}.
 *   5. Set role:therapist + approvalStatus custom claims on the auth user.
 *
 * Idempotent: if doc ID already equals authUid, returns alreadyLinked:true.
 */
exports.linkTherapistToAuth = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated',
    );
  }
  const callerEmail = context.auth.token.email;
  const isSuperAdmin = callerEmail === 'mbardouni44@gmail.com';
  const hasAdminClaim = context.auth.token.admin === true;
  if (!isSuperAdmin && !hasAdminClaim) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can link therapist accounts',
    );
  }

  const oldDocId = data.therapistDocId;
  if (!oldDocId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'therapistDocId is required',
    );
  }

  const therapistRef = db.collection('therapists').doc(oldDocId);
  const therapistSnap = await therapistRef.get();
  if (!therapistSnap.exists) {
    throw new functions.https.HttpsError(
      'not-found',
      `therapists/${oldDocId} does not exist`,
    );
  }
  const therapistData = therapistSnap.data();
  const email = therapistData.email;
  if (!email || typeof email !== 'string' || email.trim() === '') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'therapist has no email; cannot resolve an auth account',
    );
  }

  let authUser;
  try {
    authUser = await admin.auth().getUserByEmail(email.trim());
  } catch (e) {
    throw new functions.https.HttpsError(
      'not-found',
      `no Firebase Auth account exists for ${email}. Create one first or have the therapist sign up.`,
    );
  }

  const authUid = authUser.uid;
  if (authUid === oldDocId) {
    // Already aligned — just (re)set the custom claims and return.
    await admin.auth().setCustomUserClaims(authUid, {
      therapist: true,
      role: 'therapist',
      approvalStatus: therapistData.approval_status || 'approved',
    });
    return { success: true, alreadyLinked: true, authUid };
  }

  const newTherapistRef = db.collection('therapists').doc(authUid);
  const newTherapistSnap = await newTherapistRef.get();
  if (newTherapistSnap.exists) {
    throw new functions.https.HttpsError(
      'already-exists',
      `therapists/${authUid} already exists. Manual reconciliation needed.`,
    );
  }

  // 1. Copy therapists doc to the auth uid.
  const batch = db.batch();
  batch.set(newTherapistRef, therapistData);
  // 2. Copy users doc to the auth uid (merge so existing claims/profile stay).
  const oldUserRef = db.collection('users').doc(oldDocId);
  const newUserRef = db.collection('users').doc(authUid);
  const oldUserSnap = await oldUserRef.get();
  if (oldUserSnap.exists) {
    batch.set(newUserRef, oldUserSnap.data(), { merge: true });
  } else {
    batch.set(newUserRef, {
      role: 'therapist',
      therapist_status: therapistData.approval_status || 'approved',
      email: email.trim(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  // 3. Delete old docs.
  batch.delete(therapistRef);
  if (oldUserSnap.exists) batch.delete(oldUserRef);

  await batch.commit();

  // 4. Rewrite assigned_therapist_id pointers (separate batch, paginated).
  let rewriteCount = 0;
  let lastDoc = null;
  while (true) {
    let q = db
      .collection('users')
      .where('assigned_therapist_id', '==', oldDocId)
      .limit(400);
    if (lastDoc) q = q.startAfterDocument(lastDoc);
    const snap = await q.get();
    if (snap.empty) break;
    const rb = db.batch();
    for (const doc of snap.docs) {
      rb.update(doc.ref, {
        assigned_therapist_id: authUid,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      rewriteCount++;
    }
    await rb.commit();
    if (snap.size < 400) break;
    lastDoc = snap.docs[snap.docs.length - 1];
  }

  // 5. Set claims on the auth user.
  await admin.auth().setCustomUserClaims(authUid, {
    therapist: true,
    role: 'therapist',
    approvalStatus: therapistData.approval_status || 'approved',
  });

  console.log(
    `linkTherapistToAuth: migrated ${oldDocId} → ${authUid}, rewrote ${rewriteCount} assigned_therapist_id pointers`,
  );

  return {
    success: true,
    alreadyLinked: false,
    oldDocId,
    authUid,
    rewroteAssignments: rewriteCount,
  };
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
 * 6a. onNotificationCreated - FCM fanout for in-app notifications/* docs.
 *
 * Triggered when the app writes directly to notifications/ (therapist
 * assignment, subscription activation, admin broadcast, admin announcement).
 * Gated by push_fcm:true so writes from older code paths — and writes
 * authored by other Cloud Functions in this file that already push via
 * sendNotificationToUser — are not double-sent.
 *
 * After dispatch the trigger sets push_dispatched_at + push_success/failure
 * counts on the same doc for observability.
 */
exports.onNotificationCreated = functions.firestore
  .document('notifications/{notifId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};

    if (data.push_fcm !== true) {
      return null;
    }
    if (data.push_dispatched_at) {
      return null;
    }

    const userId = data.user_id;
    if (!userId) {
      console.warn(`notifications/${context.params.notifId} missing user_id`);
      return null;
    }

    try {
      await sendNotificationToUser(userId, {
        title: data.title || '',
        body: data.body || '',
        titleEn: data.title_en || data.title || '',
        bodyEn: data.body_en || data.body || '',
        type: data.type || 'system',
      });

      await snap.ref.update({
        push_dispatched_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console.warn(
        `onNotificationCreated dispatch failed for ${context.params.notifId}: ${e}`,
      );
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
 * 6b. onPaymentRecorded - Notify admins (admin-only) of EVERY new payment.
 *
 * Fires on every doc written to `payments/` — covers all gateways (PayPal
 * capture, Google Pay via PayPal, and the Freemius webhook all write here),
 * so admins get a single in-dashboard notification per successful payment.
 *
 * Writes one `notifications/` doc per admin with `push_fcm: true`, so the
 * existing onNotificationCreated fan-out also delivers a push. Only users with
 * role == 'admin' receive it — regular users never see these.
 */
exports.onPaymentRecorded = functions.firestore
  .document('payments/{paymentId}')
  .onCreate(async (snap, context) => {
    const p = snap.data() || {};

    const adminsQuery = await db.collection('users')
      .where('role', '==', 'admin')
      .get();
    if (adminsQuery.empty) return null;

    // Resolve payer name for a friendlier message (best-effort).
    let payerName = 'مستخدم';
    if (p.user_id) {
      const u = await db.collection('users').doc(p.user_id).get();
      if (u.exists) {
        const ud = u.data();
        payerName = ud.display_name || ud.name || ud.email || 'مستخدم';
      }
    }

    const amount = p.amount != null ? p.amount : '';
    const currency = p.currency || 'USD';
    // Resolve the gateway from whatever key the writer used. Client-side
    // records set `payment_method`, PayPal/Freemius webhooks set `provider`,
    // and some paths only set `payment_gateway` — so fall back across all
    // three (mirrors PaymentRecord.resolveMethod on the client) instead of
    // reading `provider` alone, which showed "via unknown".
    const rawMethod = String(
      p.payment_method || p.provider || p.payment_gateway || ''
    ).toLowerCase();
    const PROVIDER_LABELS = {
      paypal: 'PayPal',
      google_pay: 'Google Pay',
      google_pay_via_paypal: 'Google Pay',
      apple_pay: 'Apple Pay',
      card: 'Card',
      freemius: 'Card',
      bank_transfer: 'Bank Transfer',
      admin_grant: 'Admin Grant',
    };
    const provider = rawMethod
      ? (PROVIDER_LABELS[rawMethod] || rawMethod)
      : 'unknown';

    const now = admin.firestore.FieldValue.serverTimestamp();
    const batch = db.batch();
    adminsQuery.docs.forEach((adminDoc) => {
      const ref = db.collection('notifications').doc();
      batch.set(ref, {
        user_id: adminDoc.id,
        title: 'دفعة جديدة',
        body: `استلمت دفعة بقيمة ${amount} ${currency} من ${payerName} عبر ${provider}.`,
        title_en: 'New payment',
        body_en: `Received ${amount} ${currency} from ${payerName} via ${provider}.`,
        type: 'payment',
        is_read: false,
        push_fcm: true,
        is_announcement: false,
        created_at: now,
        action_route: '/admin/payments',
        data: {
          payment_id: context.params.paymentId,
          amount: String(amount),
          currency,
          provider,
          payer_id: p.user_id || '',
        },
      });
    });

    await batch.commit();
    console.log(
      `onPaymentRecorded: notified ${adminsQuery.size} admins of payment ${context.params.paymentId} (${amount} ${currency} via ${provider})`,
    );
    return null;
  });

/**
 * 7. chatWithGemini - RAG-aware AI chat (rewritten for mood-aware context)
 *
 * Input: { userId, locale, messages }
 *   - userId: required, must match auth.uid
 *   - locale: 'ar' | 'en' | 'fr' (default 'ar')
 *   - messages: [{role: 'user'|'model', parts: [{text: '...'}]}]
 *   - userMood: optional (ignored, kept for backward-compat)
 *
 * Output: { content, model, tokensUsed, sources: string[] }
 *
 * NOTE: After this deploy, the mobile client must send userId to get the
 * RAG-enriched context. Old clients sending only {messages, userMood} will
 * still get a valid response but without user-specific context.
 */
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { getCachedBriefing } = require('./lib/userBriefing');
const { getCachedPatterns } = require('./lib/patternAnalyzer');
const { matchContent } = require('./lib/contentMatcher');
const { buildSystemPrompt, PERSONAS } = require('./lib/promptTemplates');

const CHAT_MODEL = 'gemini-flash-latest';
const DAILY_TOKEN_CAP = 100_000;

/**
 * Resolve the Gemini API key. Source of truth is Firestore at
 * `system_settings/api_keys.gemini_api_key` — that's the doc the admin
 * dashboard writes to. Falls back to legacy `functions.config().gemini.key`
 * if the doc is missing (so existing deploys keep working).
 *
 * Cached in-memory for 5 min to avoid hitting Firestore on every call.
 */
let _geminiKeyCache = { value: null, fetchedAt: 0 };
async function resolveGeminiKey() {
  const now = Date.now();
  if (_geminiKeyCache.value && (now - _geminiKeyCache.fetchedAt) < 5 * 60_000) {
    return _geminiKeyCache.value;
  }
  let key = null;
  try {
    const doc = await db.doc('system_settings/api_keys').get();
    if (doc.exists) {
      key = (doc.data() || {}).gemini_api_key || null;
    }
  } catch (e) {
    console.warn('resolveGeminiKey: Firestore read failed:', e && e.message);
  }
  if (!key) {
    try {
      key = functions.config().gemini ? functions.config().gemini.key : null;
    } catch (_) {}
  }
  _geminiKeyCache = { value: key, fetchedAt: now };
  return key;
}

exports.chatWithGemini = functions.https.onCall(async (data, context) => {
  // 1. Authentication check
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { messages, userId, locale = 'ar', persona: rawPersona } = data;
  // userMood intentionally ignored (backward-compat field)

  // Validate persona — unknown values fall back to 'companion' (never reject)
  const validPersonas = Object.keys(PERSONAS);
  const persona = validPersonas.includes(rawPersona) ? rawPersona : 'companion';

  // 2. Ownership check — userId must match caller if provided
  if (userId && context.auth.uid !== userId) {
    throw new functions.https.HttpsError('permission-denied', 'You can only chat as yourself');
  }

  // Resolve effective userId (fallback to auth uid for backward compat)
  const effectiveUserId = userId || context.auth.uid;

  // 3. API key check
  const apiKey = await resolveGeminiKey();
  if (!apiKey) {
    console.error('Gemini API key not configured in functions config');
    throw new functions.https.HttpsError('failed-precondition', 'AI Service temporarily unavailable');
  }

  // 4. Daily token cap — read + reset-if-stale
  const usageRef = db.collection('users').doc(effectiveUserId).collection('ai_context').doc('usage_today');
  const usageSnap = await usageRef.get();
  let tokensUsedToday = 0;

  if (usageSnap.exists) {
    const usageData = usageSnap.data();
    const todayStr = new Date().toISOString().split('T')[0]; // UTC date YYYY-MM-DD
    if (usageData.date === todayStr) {
      tokensUsedToday = usageData.tokens || 0;
    }
    // If date differs, treat as 0 (daily reset)
  }

  if (tokensUsedToday >= DAILY_TOKEN_CAP) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Daily AI usage limit reached. Please try again tomorrow.'
    );
  }

  try {
    // 5. Build RAG context
    let briefing = null;
    let patterns = null;
    let matchedContent = [];

    try {
      [briefing, patterns] = await Promise.all([
        getCachedBriefing(db, effectiveUserId, locale),
        getCachedPatterns(db, effectiveUserId),
      ]);

      // Get user subscription state from briefing for content gating
      const subscriptionState = briefing.structured?.user?.subscription_state || null;
      matchedContent = await matchContent(db, patterns, locale, subscriptionState, 5);
    } catch (ragErr) {
      // Non-fatal: degrade gracefully to plain chat if RAG fails
      console.warn('RAG context build failed (degraded gracefully):', ragErr.message);
    }

    // 6. Build system prompt with persona overlay
    const systemPrompt = buildSystemPrompt({
      briefing: briefing || { markdown: '' },
      patterns: patterns || {},
      content: matchedContent,
      locale,
      persona,
    });

    // 7. Call Gemini 2.5 Flash with system prompt + last 20 messages
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: CHAT_MODEL,
      systemInstruction: systemPrompt,
    });

    // Client sends `{ role, content }` (string). Gemini SDK expects
    // `{ role, parts: [{ text }] }` and uses 'user' | 'model' for roles.
    const normalize = (m) => {
      const role = m.role === 'assistant' || m.role === 'bot' ? 'model' : (m.role || 'user');
      const text = typeof m.content === 'string'
        ? m.content
        : (Array.isArray(m.parts) && m.parts[0]?.text) || '';
      return { role, parts: [{ text }] };
    };
    const recentMessages = (messages || []).slice(-20).map(normalize);
    if (recentMessages.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'messages array is required');
    }
    const history = recentMessages.slice(0, -1);
    const lastMessage = recentMessages[recentMessages.length - 1].parts[0].text;

    const chat = model.startChat({
      history,
      generationConfig: {
        maxOutputTokens: 1200,
        temperature: 0.7,
      },
    });

    const result = await chat.sendMessage(lastMessage);
    const response = await result.response;
    const text = response.text();
    const tokensUsed = response.usageMetadata?.totalTokenCount || 0;

    // 8. Update daily token usage
    const todayStr = new Date().toISOString().split('T')[0];
    await usageRef.set({
      date: todayStr,
      tokens: tokensUsedToday + tokensUsed,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      content: text,
      model: CHAT_MODEL,
      tokensUsed,
      sources: matchedContent.map(c => c.id),
      persona,
    };
  } catch (error) {
    if (error.code) throw error; // re-throw HttpsError
    console.error('Gemini API Error:', error);
    throw new functions.https.HttpsError('internal', 'AI generation failed');
  }
});

// ── 10. analyzeUserPatterns ────────────────────────────────────────────────────
/**
 * Returns cached mood pattern analysis for a user.
 * Auth: caller is owner OR admin (custom claim admin == true).
 * Input: { userId }
 */
/**
 * Returns true when context.auth.uid is the assigned therapist for userId.
 * Reads users/{userId}.assigned_therapist_id and compares.
 */
async function _isAssignedTherapistFor(context, userId) {
  if (!context.auth) return false;
  try {
    const snap = await db.collection('users').doc(userId).get();
    if (!snap.exists) return false;
    return snap.data().assigned_therapist_id === context.auth.uid;
  } catch (e) {
    return false;
  }
}

exports.analyzeUserPatterns = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { userId } = data;
  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'userId is required');
  }

  const isAdmin = context.auth.token.admin === true;
  const isOwner = context.auth.uid === userId;
  const isTherapistForUser = await _isAssignedTherapistFor(context, userId);
  if (!isOwner && !isAdmin && !isTherapistForUser) {
    throw new functions.https.HttpsError('permission-denied', 'Not authorized');
  }

  const { getCachedPatterns: _getCachedPatterns } = require('./lib/patternAnalyzer');
  const patterns = await _getCachedPatterns(db, userId);
  return patterns;
});

// ── 11. generateUserBriefing ───────────────────────────────────────────────────
/**
 * Returns cached user briefing.
 * Auth: caller is owner OR admin.
 * Input: { userId, locale }
 */
exports.generateUserBriefing = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { userId, locale = 'ar' } = data;
  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'userId is required');
  }

  const isAdmin = context.auth.token.admin === true;
  const isOwner = context.auth.uid === userId;
  const isTherapistForUser = await _isAssignedTherapistFor(context, userId);
  if (!isOwner && !isAdmin && !isTherapistForUser) {
    throw new functions.https.HttpsError('permission-denied', 'Not authorized');
  }

  const { getCachedBriefing: _getCachedBriefing } = require('./lib/userBriefing');
  const briefing = await _getCachedBriefing(db, userId, locale);
  return { briefing };
});

// ── 12. generateUserReport ────────────────────────────────────────────────────
/**
 * Generates a clinical-style AI report for a user.
 * Auth: admin OR therapist with at least one booking for this user.
 * Input: { userId, locale = 'ar', rangeDays = 90 }
 * Output: { reportId, markdown }
 */
exports.generateUserReport = functions
  .runWith({ timeoutSeconds: 120, memory: '512MB' })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const { userId, locale = 'ar', rangeDays = 90 } = data;
  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'userId is required');
  }

  const callerUid = context.auth.uid;
  const isAdmin = context.auth.token.admin === true;

  // Check therapist authorization: must have at least one booking with this user
  let isAuthorizedTherapist = false;
  if (!isAdmin) {
    const therapistBookingSnap = await db.collection('bookings')
      .where('therapist_id', '==', callerUid)
      .where('client_id', '==', userId)
      .limit(1)
      .get();
    isAuthorizedTherapist = !therapistBookingSnap.empty;
  }

  if (!isAdmin && !isAuthorizedTherapist) {
    throw new functions.https.HttpsError('permission-denied', 'Only admins or assigned therapists can generate reports');
  }

  const apiKey = await resolveGeminiKey();
  if (!apiKey) {
    throw new functions.https.HttpsError('failed-precondition', 'AI Service temporarily unavailable');
  }

  try {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - rangeDays);
    const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

    console.log(`[generateUserReport] start userId=${userId} locale=${locale} rangeDays=${rangeDays}`);

    // Gather all context in parallel — but use allSettled so a single query
    // failure (e.g. missing composite index) doesn't kill the whole report.
    const safe = (label, p) => p.catch(err => {
      console.warn(`[generateUserReport] ${label} failed: ${err && err.message}`);
      return null;
    });

    const [briefing, patterns, matchedContent, completedBookingsSnap, testResultsSnap, activitySnap] = await Promise.all([
      safe('briefing', getCachedBriefing(db, userId, locale)),
      safe('patterns', getCachedPatterns(db, userId)),
      safe('matchContent', (async () => {
        const p = await getCachedPatterns(db, userId);
        const sub = (await db.collection('users').doc(userId).get()).data()?.subscription_state || null;
        return matchContent(db, p, locale, sub, 10);
      })()),
      safe('bookings', db.collection('bookings')
        .where('client_id', '==', userId)
        .where('status', '==', 'completed')
        .where('scheduled_time', '>=', cutoffTs)
        .orderBy('scheduled_time', 'desc')
        .limit(20)
        .get()),
      safe('test_results', db.collection('users').doc(userId).collection('test_results')
        .where('created_at', '>=', cutoffTs)
        .orderBy('created_at', 'desc')
        .limit(20)
        .get()),
      // activity_logs uses field name `timestamp` (see lib/features/admin/models/activity_log.dart)
      safe('activity_logs', db.collection('activity_logs')
        .where('user_id', '==', userId)
        .where('timestamp', '>=', cutoffTs)
        .get()),
    ]);

    console.log(`[generateUserReport] data: briefing=${!!briefing} patterns=${!!patterns} content=${(matchedContent||[]).length} bookings=${completedBookingsSnap?.size||0} tests=${testResultsSnap?.size||0} activity=${activitySnap?.size||0}`);

    // Shape completed bookings (include private_notes) — null-safe
    const completedBookings = (completedBookingsSnap?.docs || []).map(doc => {
      const d = doc.data();
      return {
        date: d.scheduled_time instanceof admin.firestore.Timestamp ? d.scheduled_time.toDate().toISOString().split('T')[0] : '',
        sessionType: d.session_type || 'session',
        privateNotes: d.private_notes || null,
        therapistId: d.therapist_id || null,
      };
    });

    // Shape test results
    const testResults = (testResultsSnap?.docs || []).map(doc => {
      const d = doc.data();
      return {
        type: d.test_type || 'unknown',
        score: d.total_score || 0,
        interpretation: d.interpretation || '',
        date: d.created_at instanceof admin.firestore.Timestamp ? d.created_at.toDate().toISOString().split('T')[0] : '',
      };
    });

    // Activity log summary
    const activityCounts = {};
    (activitySnap?.docs || []).forEach(doc => {
      const t = doc.data().type || 'unknown';
      activityCounts[t] = (activityCounts[t] || 0) + 1;
    });

    // Build clinical report prompt — null-safe
    const safeMatched = matchedContent || [];
    const safeBriefing = briefing || { markdown: '', structured: {} };
    const safePatterns = patterns || { trend: 'stable', dominantMood: 'unknown', riskLevel: 'low' };
    const contentList = safeMatched.map(c => `- "${c.title}" (${c.type})`).join('\n');
    const bookingsList = completedBookings.map(b =>
      `- ${b.date} (${b.sessionType})${b.privateNotes ? ': ' + b.privateNotes : ''}`
    ).join('\n');
    const testList = testResults.map(t => `- ${t.type}: score ${t.score} — ${t.interpretation}`).join('\n');
    const activitySummary = Object.entries(activityCounts).map(([k, v]) => `${k}: ${v}`).join(', ');

    const reportPrompt = `You are a clinical AI assistant generating a structured psychological report for a therapist.

${safeBriefing.markdown}

## Mood Pattern Analysis
- Trend: ${safePatterns.trend}
- Dominant Mood: ${safePatterns.dominantMood}
- Risk Level: ${safePatterns.riskLevel}
- Low Streak: ${safePatterns.lowStreak ?? 0} days
- Weekend Dip: ${safePatterns.weekendDip ?? false}
- Note Themes: ${(safePatterns.noteThemes || []).join(', ')}

## Completed Sessions (last ${rangeDays} days)
${bookingsList || 'None'}

## Psychological Test Results (last ${rangeDays} days)
${testList || 'None'}

## App Engagement (last ${rangeDays} days)
${activitySummary || 'None'}

## Relevant App Content
${contentList || 'None'}

---
Write a clinical-style report in ${locale === 'ar' ? 'Arabic' : locale === 'fr' ? 'French' : 'English'}.
Sections: Summary, Mood Patterns, Test Results, Risk Assessment, Engagement, Recommended Next Steps.
Use markdown. Be professional but compassionate. Cite app content by title when making recommendations.
Do NOT include patient's name in the report. Do NOT invent data not provided above.`;

    // Use gemini-flash-latest (rolling alias — auto-tracks newest stable Flash).
    // Falls back to gemini-2.5-flash if the alias is unavailable on the project.
    const genAI = new GoogleGenerativeAI(apiKey);
    let usedModel = 'gemini-flash-latest';
    let result;
    try {
      const flashModel = genAI.getGenerativeModel({
        model: 'gemini-flash-latest',
        generationConfig: { maxOutputTokens: 4000, temperature: 0.3 },
      });
      result = await flashModel.generateContent(reportPrompt);
    } catch (err) {
      console.warn(`[generateUserReport] gemini-flash-latest failed (${err.status || err.message}); falling back to gemini-2.5-flash`);
      usedModel = 'gemini-2.5-flash';
      const fallback = genAI.getGenerativeModel({
        model: 'gemini-2.5-flash',
        generationConfig: { maxOutputTokens: 4000, temperature: 0.3 },
      });
      result = await fallback.generateContent(reportPrompt);
    }
    const response = await result.response;
    const markdown = response.text();
    const tokensUsed = response.usageMetadata?.totalTokenCount || 0;

    // Save report to Firestore
    const reportRef = db.collection('users').doc(userId).collection('reports').doc();
    await reportRef.set({
      markdown,
      locale,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      generatedBy: callerUid,
      rangeDays,
      model: usedModel,
      tokensUsed,
    });

    // Write activity log entry — field is `timestamp` (matches the
    // ActivityLog model in lib/features/admin/models/activity_log.dart).
    await db.collection('activity_logs').add({
      type: 'reportGenerated',
      actor_uid: callerUid,
      user_id: userId,
      report_id: reportRef.id,
      description: 'AI report generated',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { reportId: reportRef.id, markdown };
  } catch (error) {
    if (error.code) throw error;
    console.error('generateUserReport error:', error);
    throw new functions.https.HttpsError('internal', 'Report generation failed');
  }
});

// ── runWithConcurrency — inline concurrency pool helper ───────────────────────
/**
 * Run `fn` on each item in `items` with at most `limit` concurrent invocations.
 * Results array preserves input order. Does not swallow errors — callers wrap
 * individual invocations in try/catch if per-item resilience is needed.
 *
 * @param {any[]} items
 * @param {number} limit
 * @param {(item: any, idx: number) => Promise<any>} fn
 * @returns {Promise<any[]>}
 */
async function runWithConcurrency(items, limit, fn) {
  const results = new Array(items.length);
  let i = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (i < items.length) { const idx = i++; results[idx] = await fn(items[idx], idx); }
  });
  await Promise.all(workers);
  return results;
}

// ── 13. analyzeAllUsers ───────────────────────────────────────────────────────
/**
 * Admin-only callable: bulk mood-pattern analytics across all users.
 *
 * Input:  { pageSize?: number (default 200), cursor?: string|null }
 * Output: { users, nextCursor, summary }
 *
 * Auth: caller must have custom claim admin === true.
 * Processes users in pages (ordered by created_at desc).
 * Per-user errors are swallowed — returns null patterns and hasPatterns:false.
 */
exports.analyzeAllUsers = functions
  .runWith({ timeoutSeconds: 540, memory: '512MB' })
  .https.onCall(async (data, context) => {
    // 1. Auth gate — admin claim required
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    if (context.auth.token.admin !== true) {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    const { pageSize = 200, cursor = null } = data || {};

    // 2. Build paginated query on users collection
    let query = db.collection('users')
      .orderBy('created_at', 'desc')
      .limit(pageSize);

    if (cursor) {
      // cursor is a doc id — fetch snapshot to use as startAfter anchor
      const cursorSnap = await db.collection('users').doc(cursor).get();
      if (cursorSnap.exists) {
        query = query.startAfter(cursorSnap);
      }
      // If cursor doc doesn't exist, silently ignore — start from beginning
    }

    const usersSnap = await query.get();
    if (usersSnap.empty) {
      return {
        users: [],
        nextCursor: null,
        summary: {
          total: 0,
          byRisk: { low: 0, moderate: 0, high: 0, critical: 0 },
          activeLoggers7d: 0,
        },
      };
    }

    const userDocs = usersSnap.docs;
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    // 3. Per-user fetch: patterns + name/email + lastMoodAt + totalMoodEntries
    //    Concurrency cap of 10 to avoid thundering-herd on Firestore.
    const userResults = await runWithConcurrency(userDocs, 10, async (userDoc) => {
      const userId = userDoc.id;
      const userData = userDoc.data() || {};
      const name = userData.name || userData.display_name || null;
      const email = userData.email || null;

      try {
        // Fetch patterns, lastMoodAt, and totalMoodEntries in parallel
        const moodRef = db.collection('users').doc(userId).collection('mood_entries');

        const [patterns, lastMoodSnap, moodCountSnap] = await Promise.all([
          getCachedPatterns(db, userId).catch(err => {
            console.error(`analyzeAllUsers: getCachedPatterns failed for ${userId}:`, err.message);
            return null;
          }),
          moodRef.orderBy('date', 'desc').limit(1).get(),
          moodRef.count().get(),
        ]);

        const hasPatterns = patterns !== null;
        const lastMoodDoc = lastMoodSnap.docs[0];
        let lastMoodAt = null;
        if (lastMoodDoc) {
          const d = lastMoodDoc.data();
          const rawDate = d.date;
          if (rawDate && typeof rawDate.toDate === 'function') {
            lastMoodAt = rawDate.toDate().toISOString();
          } else if (rawDate) {
            lastMoodAt = new Date(rawDate).toISOString();
          }
        }

        const totalMoodEntries = moodCountSnap.data().count;

        return {
          userId,
          name,
          email,
          dominantMood: hasPatterns ? (patterns.dominantMood || null) : null,
          trend: hasPatterns ? (patterns.trend || 'stable') : null,
          riskLevel: hasPatterns ? (patterns.riskLevel || 'low') : null,
          lastMoodAt,
          totalMoodEntries,
          hasPatterns,
        };
      } catch (err) {
        console.error(`analyzeAllUsers: failed for user ${userId}:`, err.message);
        return {
          userId,
          name,
          email,
          dominantMood: null,
          trend: null,
          riskLevel: null,
          lastMoodAt: null,
          totalMoodEntries: 0,
          hasPatterns: false,
        };
      }
    });

    // 4. Build summary
    const byRisk = { low: 0, moderate: 0, high: 0, critical: 0 };
    let activeLoggers7d = 0;

    for (const u of userResults) {
      if (u.hasPatterns && u.riskLevel && byRisk.hasOwnProperty(u.riskLevel)) {
        byRisk[u.riskLevel]++;
      }
      if (u.lastMoodAt && new Date(u.lastMoodAt) >= sevenDaysAgo) {
        activeLoggers7d++;
      }
    }

    // 5. nextCursor: last doc id if page was full, else null
    const nextCursor = userDocs.length === pageSize ? userDocs[userDocs.length - 1].id : null;

    return {
      users: userResults,
      nextCursor,
      summary: {
        total: userResults.length,
        byRisk,
        activeLoggers7d,
      },
    };
  });

// ── 14. setUserBlocked ────────────────────────────────────────────────────────
/**
 * Admin-only callable: block or unblock a user account.
 *
 * Input:  { userId: string, blocked: boolean }
 * Output: { ok: true, userId, blocked }
 *
 * Auth: caller must have custom claim admin === true.
 * Side-effects:
 *   - Firebase Auth: sets disabled flag on the user's auth account.
 *   - Firestore users/{userId}: sets is_blocked + blocked_at.
 *   - activity_logs: writes a userBlocked / userUnblocked entry.
 */
exports.setUserBlocked = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  const { userId, blocked } = data || {};

  if (!userId || typeof userId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'userId must be a non-empty string');
  }
  if (typeof blocked !== 'boolean') {
    throw new functions.https.HttpsError('invalid-argument', 'blocked must be a boolean');
  }

  const actorUid = context.auth.uid;

  try {
    // 1. Flip auth account disabled state
    await admin.auth().updateUser(userId, { disabled: blocked });
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.warn(`setUserBlocked: auth user ${userId} not found — skipping auth update`);
    } else {
      throw new functions.https.HttpsError('internal', `Failed to update auth: ${err.message}`);
    }
  }

  // 2. Update Firestore user document
  try {
    await db.collection('users').doc(userId).update({
      is_blocked: blocked,
      blocked_at: blocked ? admin.firestore.FieldValue.serverTimestamp() : null,
    });
  } catch (err) {
    console.warn(`setUserBlocked: failed to update users/${userId}: ${err.message}`);
  }

  // 3. Write activity log
  try {
    await db.collection('activity_logs').add({
      type: blocked ? 'userBlocked' : 'userUnblocked',
      actor_uid: actorUid,
      user_id: userId,
      description: blocked ? `Admin blocked user ${userId}` : `Admin unblocked user ${userId}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.warn(`setUserBlocked: failed to write activity log: ${err.message}`);
  }

  return { ok: true, userId, blocked };
});

// ── 15. deleteUserAccount ─────────────────────────────────────────────────────
/**
 * Admin-only callable: hard-delete a user account and all personal data.
 *
 * Input:  { userId: string }
 * Output: { ok: true, userId, deletedSubcollections: string[] }
 *
 * Auth: caller must have custom claim admin === true.
 * Deletion steps (all wrapped defensively):
 *   1. Delete Firebase Auth user (tolerates user-not-found).
 *   2. Delete subcollections of users/{userId} in batches of 500:
 *      mood_entries, test_results, ai_context, reports, engagement.
 *   3. Delete users/{userId} document itself.
 *   4. Mark bookings where client_id == userId as cancelled + cancelled_reason.
 *   5. Soft-delete community_posts where author_id == userId (is_deleted: true).
 *   6. Write activity_logs entry type: userDeleted.
 *
 * Idempotent: re-running on a missing user returns ok with empty deletedSubcollections.
 */
exports.deleteUserAccount = functions
  .runWith({ timeoutSeconds: 300, memory: '256MB' })
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  const { userId } = data || {};

  if (!userId || typeof userId !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'userId must be a non-empty string');
  }

  const actorUid = context.auth.uid;
  const deletedSubcollections = [];

  // ── Inline batch-delete helper ────────────────────────────────────────────
  async function deleteCollectionInBatches(collRef, batchSize) {
    let totalDeleted = 0;
    while (true) {
      const snap = await collRef.limit(batchSize).get();
      if (snap.empty) break;
      const batch = db.batch();
      snap.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      totalDeleted += snap.docs.length;
      if (snap.docs.length < batchSize) break;
    }
    return totalDeleted;
  }

  // 1. Delete Firebase Auth user
  try {
    await admin.auth().deleteUser(userId);
    console.log(`deleteUserAccount: auth user ${userId} deleted`);
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.warn(`deleteUserAccount: auth user ${userId} not found — continuing`);
    } else {
      console.warn(`deleteUserAccount: failed to delete auth user ${userId}: ${err.message}`);
    }
  }

  // 2. Delete subcollections
  const subcollections = ['mood_entries', 'test_results', 'ai_context', 'reports', 'engagement'];
  for (const subcollName of subcollections) {
    try {
      const collRef = db.collection('users').doc(userId).collection(subcollName);
      const count = await deleteCollectionInBatches(collRef, 500);
      console.log(`deleteUserAccount: deleted ${count} docs from users/${userId}/${subcollName}`);
      deletedSubcollections.push(subcollName);
    } catch (err) {
      console.warn(`deleteUserAccount: failed to delete subcollection ${subcollName} for ${userId}: ${err.message}`);
    }
  }

  // 3. Delete the user document itself
  try {
    await db.collection('users').doc(userId).delete();
    console.log(`deleteUserAccount: deleted users/${userId} document`);
  } catch (err) {
    console.warn(`deleteUserAccount: failed to delete users/${userId}: ${err.message}`);
  }

  // 4. Mark bookings as cancelled (keep for therapist history — do NOT delete)
  try {
    const bookingsSnap = await db.collection('bookings')
      .where('client_id', '==', userId)
      .get();

    if (!bookingsSnap.empty) {
      // Chunk into batches of 500
      const docs = bookingsSnap.docs;
      for (let start = 0; start < docs.length; start += 500) {
        const chunk = docs.slice(start, start + 500);
        const batch = db.batch();
        chunk.forEach(doc => {
          batch.update(doc.ref, {
            status: 'cancelled',
            cancelled_reason: 'user_deleted',
          });
        });
        await batch.commit();
      }
      console.log(`deleteUserAccount: marked ${docs.length} bookings cancelled for ${userId}`);
    }
  } catch (err) {
    console.warn(`deleteUserAccount: failed to cancel bookings for ${userId}: ${err.message}`);
  }

  // 5. Soft-delete community posts (posts collection uses author_id field)
  try {
    const postsSnap = await db.collection('posts')
      .where('author_id', '==', userId)
      .get();

    if (!postsSnap.empty) {
      const docs = postsSnap.docs;
      for (let start = 0; start < docs.length; start += 500) {
        const chunk = docs.slice(start, start + 500);
        const batch = db.batch();
        chunk.forEach(doc => {
          batch.update(doc.ref, { is_deleted: true });
        });
        await batch.commit();
      }
      console.log(`deleteUserAccount: soft-deleted ${docs.length} posts for ${userId}`);
    }
  } catch (err) {
    console.warn(`deleteUserAccount: failed to soft-delete posts for ${userId}: ${err.message}`);
  }

  // 6. Write activity log
  try {
    await db.collection('activity_logs').add({
      type: 'userDeleted',
      actor_uid: actorUid,
      user_id: userId,
      description: `Admin deleted user account ${userId}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.warn(`deleteUserAccount: failed to write activity log: ${err.message}`);
  }

  return { ok: true, userId, deletedSubcollections };
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
 * remindIncompleteProfiles - nudge users who signed up but never finished
 * profile completion. Only reliable now that `has_complete_profile` is always
 * written at signup (see ensureUserDocument + client signup paths).
 *
 * Guardrails (no spam):
 *  - only role == 'user'
 *  - only signups in the last 7 days (skip dead/old accounts) and at least
 *    1h old (don't interrupt someone mid-completion)
 *  - at most 2 reminders per user, spaced >= 24h apart
 * Uses the composite index (has_complete_profile ASC, created_at DESC).
 */
/**
 * Core logic for nudging users with incomplete profiles.
 *
 * Shared by the daily scheduled job (remindIncompleteProfiles) and the admin
 * on-demand callable (sendIncompleteProfileRemindersNow) so both apply the
 * IDENTICAL guardrails: role == 'user', account created in the last 7 days,
 * at least 1h old, max 2 reminders, spaced >= 24h apart.
 *
 * Returns { scanned, nudged }.
 */
async function runIncompleteProfileReminders() {
  const now = admin.firestore.Timestamp.now();
  const sevenDaysAgo = new admin.firestore.Timestamp(now.seconds - 7 * 24 * 3600, 0);
  const oneHourAgo = new admin.firestore.Timestamp(now.seconds - 3600, 0);
  const MAX_REMINDERS = 2;
  const MIN_GAP_SECONDS = 24 * 3600;

  const snap = await db.collection('users')
    .where('has_complete_profile', '==', false)
    .where('created_at', '>=', sevenDaysAgo)
    .where('created_at', '<=', oneHourAgo)
    .orderBy('created_at', 'desc') // reuse the (has_complete_profile, created_at DESC) index
    .get();

  if (snap.empty) {
    console.log('runIncompleteProfileReminders: no incomplete profiles to nudge');
    return { scanned: 0, nudged: 0 };
  }

  const jobs = [];
  let nudged = 0;
  for (const doc of snap.docs) {
    const d = doc.data();
    if ((d.role || 'user') !== 'user') continue;

    const count = d.profile_reminder_count || 0;
    if (count >= MAX_REMINDERS) continue;

    const last = d.profile_reminder_sent_at;
    if (last && (now.seconds - last.seconds) < MIN_GAP_SECONDS) continue;

    nudged++;
    jobs.push((async () => {
      await sendNotificationToUser(doc.id, {
        title: 'أكمل ملفك الشخصي',
        body: 'بقيت خطوة واحدة لتبدأ رحلتك مع سند. أكمل ملفك الآن.',
        titleEn: 'Complete your profile',
        bodyEn: "You're one step away from starting with Sanad — finish your profile now.",
        type: 'profile_incomplete',
      });
      await doc.ref.set(
        {
          profile_reminder_count: count + 1,
          profile_reminder_sent_at: now,
        },
        { merge: true }
      );
      await db.collection('notifications').add({
        user_id: doc.id,
        title: 'أكمل ملفك الشخصي',
        title_en: 'Complete your profile',
        body: 'بقيت خطوة واحدة لتبدأ رحلتك مع سند.',
        body_en: "You're one step away from starting with Sanad.",
        type: 'profile_incomplete',
        is_read: false,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    })());
  }

  await Promise.all(jobs);
  console.log(`runIncompleteProfileReminders: nudged ${nudged} of ${snap.size} scanned`);
  return { scanned: snap.size, nudged };
}

exports.remindIncompleteProfiles = functions.pubsub
  .schedule('0 18 * * *') // daily at 18:00 UTC
  .onRun(async () => {
    await runIncompleteProfileReminders();
    return null;
  });

/**
 * Admin-triggered, on-demand version of remindIncompleteProfiles.
 * Same guardrails as the daily job — it just runs now instead of at 18:00 UTC.
 * Requires the caller to have the admin custom claim.
 */
exports.sendIncompleteProfileRemindersNow = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'You must be signed in.'
      );
    }
    if (context.auth.token.admin !== true) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin privileges required.'
      );
    }
    const result = await runIncompleteProfileReminders();
    return { ok: true, ...result };
  }
);

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

/**
 * 9a. notifySupportTrialEnded - Daily job: send a paywall nudge message in
 *     support_chats for users whose free intro trial has ended and who are
 *     not yet subscribed.
 *
 * Logic:
 *   1. Read `support_trial_days` from system_settings/config (default 3).
 *   2. Candidate = created_at < cutoff AND subscription_state != 'active'
 *      AND is_premium != true (subscription filter applied in-code after the
 *      Firestore range query, since Firestore can't combine two inequality
 *      predicates on different fields).
 *   3. Dedupe: skip if support_chats/{uid}.support_trial_message_sent == true.
 *   4. Write a system message + update the thread doc (merge).
 *   5. Capped at 500 users per run; idempotent.
 */
exports.notifySupportTrialEnded = functions.pubsub
  .schedule('0 0 * * *') // Every day at midnight
  .onRun(async (context) => {
    const BATCH_CAP = 500;

    // 1. Read trial length from config
    const configSnap = await db.collection('system_settings').doc('config').get();
    const configData = configSnap.exists ? configSnap.data() : {};
    const trialDays = (typeof configData.support_trial_days === 'number' && configData.support_trial_days > 0)
      ? configData.support_trial_days
      : 3;

    // Grandfather rule: only accounts created ON OR AFTER this date are in the
    // trial program. If unset, the paywall is OFF for everyone — bail out so
    // existing users are never messaged.
    const trialStart = configData.support_trial_start_date;
    if (!trialStart || typeof trialStart.seconds !== 'number') {
      console.log('notifySupportTrialEnded: support_trial_start_date unset — paywall off, nothing to do');
      return null;
    }
    const trialStartSeconds = trialStart.seconds;

    const now = admin.firestore.Timestamp.now();
    const cutoffSeconds = now.seconds - trialDays * 86400;
    const cutoffTs = new admin.firestore.Timestamp(cutoffSeconds, 0);

    // 2. Query users whose trial has ended (created_at < cutoff)
    const usersSnap = await db.collection('users')
      .where('created_at', '<', cutoffTs)
      .limit(BATCH_CAP)
      .get();

    if (usersSnap.empty) {
      console.log('notifySupportTrialEnded: no candidate users found');
      return null;
    }

    // Filter out already-subscribed users in code (can't combine inequalities in Firestore)
    const candidates = [];
    usersSnap.forEach(doc => {
      const u = doc.data();
      if (u.subscription_state === 'active') return;
      if (u.is_premium === true) return;
      // Grandfather: skip accounts created before the program start date.
      const createdAt = u.created_at;
      if (!createdAt || typeof createdAt.seconds !== 'number'
          || createdAt.seconds < trialStartSeconds) return;
      candidates.push(doc.id);
    });

    if (candidates.length === 0) {
      console.log('notifySupportTrialEnded: all queried users are subscribed — nothing to do');
      return null;
    }

    const MESSAGE_CONTENT =
      'عزيزي العميل.. أهلاً بك في سند ثيرابي 🤍\n' +
      'لقد انتهت رسائل باقة التعارف المجانية المخصصة لحسابك. معالجك في انتظارك الآن للاستماع إليك ومساعدتك في تخطي ما يمر بك بدون قيود.\n' +
      'اضغط على زر الاشتراك بالأسفل 👇 لتفعيل اشتراكك ومتابعة الدردشة غير المحدودة فوراً.';

    const LAST_MESSAGE_PREVIEW = 'عزيزي العميل.. أهلاً بك في سند ثيرابي 🤍';

    let notified = 0;
    let skipped = 0;

    const jobs = candidates.map(async (uid) => {
      // 3. Dedupe: check thread doc flag
      const threadRef = db.collection('support_chats').doc(uid);
      const threadSnap = await threadRef.get();
      if (threadSnap.exists && threadSnap.data().support_trial_message_sent === true) {
        skipped++;
        return;
      }

      // 4a. Add system message to subcollection
      const messagesRef = threadRef.collection('messages');
      await messagesRef.add({
        sender_id: 'system',
        content: MESSAGE_CONTENT,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        is_read: false,
      });

      // 4b. Update thread doc (merge so we don't clobber existing fields)
      await threadRef.set({
        support_trial_message_sent: true,
        last_message: LAST_MESSAGE_PREVIEW,
        last_message_time: admin.firestore.FieldValue.serverTimestamp(),
        unread_count_user: admin.firestore.FieldValue.increment(1),
      }, { merge: true });

      notified++;
    });

    // 5. Run all concurrently
    await Promise.all(jobs);

    console.log(
      `notifySupportTrialEnded: notified=${notified} skipped=${skipped} ` +
      `(trialDays=${trialDays} cutoff=${new Date(cutoffSeconds * 1000).toISOString()})`
    );
    return null;
  });

/**
 * onUserSubscriptionChanged - recompute therapist chat access when a user's
 * subscription state changes.
 *
 * Fires on every update to users/{userId}. Guards:
 *   - Only acts when is_premium OR subscription_status actually changed.
 *   - Only acts when assigned_therapist_id is set.
 *   - On downgrade: only sets read_only if the chat doc already exists
 *     (never creates a chat document on downgrade).
 *   - Does NOT update is_premium or subscription_status on users/{userId},
 *     so there is no write-back loop with onUserRoleChanged.
 */
exports.onUserSubscriptionChanged = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();
    const userId = context.params.userId;

    // Guard: only act when subscription-relevant fields changed
    const premiumChanged = before.is_premium !== after.is_premium;
    const statusChanged  = before.subscription_status !== after.subscription_status;
    if (!premiumChanged && !statusChanged) return null;

    const assignedTherapistId = after.assigned_therapist_id || null;
    if (!assignedTherapistId) return null;

    const chatId  = `${assignedTherapistId}_${userId}`;
    const chatRef = db.collection('therapist_chats').doc(chatId);

    const isPremiumNow = after.is_premium === true;
    const wasPremium   = before.is_premium === true;

    if (isPremiumNow) {
      // Gained / retained premium with an assigned therapist → full access.
      try {
        await chatRef.set(
          {
            user_access: 'full',
            user_id: userId,
            therapist_id: assignedTherapistId,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        console.log(
          `onUserSubscriptionChanged: set therapist_chats/${chatId}.user_access='full' (premium gained)`,
        );
      } catch (e) {
        console.warn(`onUserSubscriptionChanged: failed to stamp full access: ${e.message}`);
      }
    } else if (wasPremium && !isPremiumNow) {
      // Premium lost → downgrade to read_only, but only if the doc exists.
      // Never create a chat doc during a downgrade.
      try {
        const snap = await chatRef.get();
        if (snap.exists) {
          await chatRef.update({
            user_access: 'read_only',
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(
            `onUserSubscriptionChanged: set therapist_chats/${chatId}.user_access='read_only' (premium lost)`,
          );
        } else {
          console.log(
            `onUserSubscriptionChanged: chat ${chatId} does not exist — skip downgrade`,
          );
        }
      } catch (e) {
        console.warn(`onUserSubscriptionChanged: failed to stamp read_only access: ${e.message}`);
      }
    }

    return null;
  });

/**
 * 10. autoCompleteBookings - Auto-flip confirmed bookings to 'completed'
 *     once scheduled_time + duration_minutes + grace has elapsed.
 *
 * The therapist is supposed to mark sessions completed manually from
 * their portal. When they don't, the booking stays 'confirmed' forever
 * and the post-session rating prompt never fires for the client.
 *
 * Grace period: 15 minutes after the session's nominal end.
 */
exports.autoCompleteBookings = functions.pubsub
  .schedule('every 30 minutes')
  .onRun(async (context) => {
    const GRACE_MINUTES = 15;
    const now = admin.firestore.Timestamp.now();
    // Cheap pre-filter: only consider sessions whose scheduled_time is at
    // least 15 minutes in the past (shortest plausible session). The exact
    // end-time check happens client-side per booking.
    const cutoffTs = new admin.firestore.Timestamp(
      now.seconds - GRACE_MINUTES * 60,
      now.nanoseconds,
    );

    const snapshot = await db.collection('bookings')
      .where('status', '==', 'confirmed')
      .where('scheduled_time', '<', cutoffTs)
      .get();

    if (snapshot.empty) return null;

    const nowMs = now.toMillis();
    const updates = [];
    let completedCount = 0;

    snapshot.forEach(doc => {
      const booking = doc.data();
      const scheduledTime = booking.scheduled_time;
      if (!(scheduledTime instanceof admin.firestore.Timestamp)) return;

      const durationMinutes = typeof booking.duration_minutes === 'number'
        ? booking.duration_minutes
        : 60;
      const endMs = scheduledTime.toMillis()
        + (durationMinutes + GRACE_MINUTES) * 60 * 1000;

      if (endMs > nowMs) return; // session not over yet

      completedCount++;
      updates.push(doc.ref.update({
        status: 'completed',
        completed_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        auto_completed: true,
      }));

      // Nudge the client to leave a rating.
      if (booking.client_id) {
        const therapistName = booking.therapist_name || '';
        updates.push(sendNotificationToUser(booking.client_id, {
          title: 'كيف كانت جلستك؟',
          body: therapistName
            ? `قيّم جلستك مع ${therapistName}`
            : 'قيّم جلستك',
          titleEn: 'How was your session?',
          bodyEn: therapistName
            ? `Rate your session with ${therapistName}`
            : 'Rate your session',
          type: 'rate_session',
          bookingId: doc.id,
        }));
      }
    });

    await Promise.all(updates);
    console.log(`Auto-completed ${completedCount} bookings`);
    return null;
  });

/**
 * Maintenance mode changed — notify subscribers when maintenance ends.
 * Trigger: system_settings/config document is updated.
 * When maintenance_mode changes from true to false AND
 * maintenance_notify_pending is true, send push to all subscribers.
 */
exports.onMaintenanceModeChanged = functions.firestore
  .document('system_settings/config')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    const wasActive = before.maintenance_mode === true;
    const isActive = after.maintenance_mode === true;
    const notifyPending = after.maintenance_notify_pending === true;

    // Only fire when transitioning from active → inactive with notify flag
    if (!wasActive || isActive || !notifyPending) {
      return null;
    }

    console.log('Maintenance ended — sending notifications to subscribers');

    try {
      // Read all subscribers
      const subscribersSnap = await db.collection('maintenance_subscribers').get();
      
      if (subscribersSnap.empty) {
        console.log('No maintenance subscribers to notify');
        // Clear the flag
        await change.after.ref.update({
          maintenance_notify_pending: admin.firestore.FieldValue.delete(),
        });
        return null;
      }

      const tokens = [];
      const subscriberIds = [];

      subscribersSnap.forEach(doc => {
        subscriberIds.push(doc.id);
        const token = doc.data().fcm_token;
        if (token && typeof token === 'string' && token.length > 0) {
          tokens.push(token);
        }
      });

      if (tokens.length === 0) {
        console.log('No valid FCM tokens among subscribers');
        // Clean up subscribers and flag
        await _deleteSubscribers(subscriberIds);
        await change.after.ref.update({
          maintenance_notify_pending: admin.firestore.FieldValue.delete(),
        });
        return null;
      }

      // Send FCM to all subscribers via multicast
      const payload = {
        notification: {
          title: 'نعود من جديد',
          body: 'انتهت أعمال الصيانة بنجاح. يمكنك الآن استخدام كافة مميزات التطبيق بشكل طبيعي. شكراً لكونك جزءاً من مجتمعنا..!',
        },
        data: {
          titleAr: 'نعود من جديد',
          bodyAr: 'انتهت أعمال الصيانة بنجاح. يمكنك الآن استخدام كافة مميزات التطبيق بشكل طبيعي. شكراً لكونك جزءاً من مجتمعنا..!',
          titleEn: "We're Back",
          bodyEn: 'Maintenance has been completed successfully. You can now use all app features normally. Thank you for being part of our community!',
          type: 'maintenance_ended',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        tokens: tokens,
      };

      const response = await messaging.sendEachForMulticast(payload);
      console.log(
        `✅ Maintenance notification sent to ${response.successCount}/${tokens.length} devices`,
      );

      // Clean up subscribers and flag
      await _deleteSubscribers(subscriberIds);
      await change.after.ref.update({
        maintenance_notify_pending: admin.firestore.FieldValue.delete(),
      });
    } catch (e) {
      console.error('Failed to send maintenance notifications:', e);
    }

    return null;
  });

/**
 * Auth onCreate safety net — guarantees every new Firebase Auth user has a
 * matching users/{uid} document with the fields the admin dashboard query
 * (orderBy created_at) requires.
 *
 * Background: the Flutter client writes users/{uid} from _syncUserData() but
 * silently swallows any exception. Slow networks or transient permission
 * lookups can leave Auth users with no Firestore doc, making them invisible
 * to the admin panel. This trigger backstops that path.
 */
exports.ensureUserDocument = functions.auth.user().onCreate(async user => {
  const uid = user.uid;
  const userRef = db.collection('users').doc(uid);

  try {
    const existing = await userRef.get();
    if (existing.exists) {
      // The client (or another path) already created the doc. NEVER re-seed it
      // — the full seed below would merge has_complete_profile / name / email
      // over real values (e.g. reset has_complete_profile to false when Auth
      // displayName hasn't synced yet). Only backfill a missing created_at so
      // the admin's orderBy('created_at') ordering still includes this user.
      if (!existing.data()?.created_at) {
        await userRef.set(
          {
            created_at: user.metadata?.creationTime
              ? admin.firestore.Timestamp.fromDate(new Date(user.metadata.creationTime))
              : admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      }
      return null;
    }

    const providerId = user.providerData?.[0]?.providerId || 'unknown';
    const authProvider = providerId.includes('phone')
      ? 'phone'
      : providerId.includes('google')
        ? 'google'
        : providerId.includes('apple')
          ? 'apple'
          : providerId.includes('password')
            ? 'email'
            : providerId;

    const seed = {
      email: user.email || null,
      // Leave null (not the literal 'User') for nameless signups so abandoned
      // accounts never show as a fake user named "User" in the dashboard.
      name: user.displayName || null,
      avatar_url: user.photoURL || null,
      phone: user.phoneNumber || null,
      role: 'user',
      auth_provider: authProvider,
      // Derive from what Auth gave us; defaults false so the admin
      // incomplete-profiles query (where has_complete_profile == false)
      // matches abandoned signups instead of silently skipping them.
      has_complete_profile: !!(user.displayName && user.phoneNumber),
      created_at: user.metadata?.creationTime
        ? admin.firestore.Timestamp.fromDate(new Date(user.metadata.creationTime))
        : admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      last_login: admin.firestore.FieldValue.serverTimestamp(),
      created_by: 'auth_oncreate_trigger',
      settings: {
        notifications_enabled: true,
        daily_reminders: true,
        mood_tracking_reminders: true,
        reminder_time: '09:00',
        dark_mode: false,
        language: 'English',
      },
    };

    await userRef.set(seed, { merge: true });
    console.log(`ensureUserDocument: seeded users/${uid} (provider=${authProvider})`);
  } catch (err) {
    console.error(`ensureUserDocument failed for ${uid}:`, err);
  }
  return null;
});

/**
 * Safety net: mark a profile complete once it carries the FULL set of fields the
 * registration form collects.
 *
 * The client sets has_complete_profile=true via an explicit "Complete" button.
 * When that final step is missed (or a transient error skips it) the autosave
 * still persists every field, but the flag stays false — so the gate re-prompts
 * on every launch even though the data is all there. This trigger makes
 * completion data-driven and only UPGRADES false→true (never downgrades), and
 * skips the write when the flag is already correct so it can't self-loop.
 *
 * IMPORTANT — it requires the COMPLETE set (name + phone + gender + goals +
 * relationship_status + preferred_therapist_gender), not just the page-1 fields.
 * If it fired on a partial (page-1) autosave it would flip the user to
 * "authenticated" mid-wizard, the app would redirect them to Home, and pages
 * 2-3 (matching preferences) would be abandoned unwritten. Requiring the full
 * set guarantees every field is already persisted before completion, so nothing
 * is lost when the user is sent home.
 */
exports.syncProfileCompletion = functions.firestore
  .document('users/{userId}')
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    if (!after) return null; // deleted

    // Already complete → nothing to do (also stops this trigger re-looping on
    // its own write).
    if (after.has_complete_profile === true) return null;

    const str = (v) => (v == null ? '' : String(v).trim());
    // 'User'/'مستخدم' are placeholder names seeded for nameless signups — they
    // do not count as a real name.
    const realName = (v) => {
      const t = str(v).toLowerCase();
      return !!t && t !== 'user' && t !== 'مستخدم';
    };

    const hasName =
      realName(after.first_name) ||
      realName(after.display_name) ||
      realName(after.name);
    // whatsapp_number is an acceptable contact fallback (mirrors the backfill).
    const hasPhone = !!str(after.phone) || !!str(after.whatsapp_number);
    const hasGender = !!str(after.gender);

    const mp = after.matching_preferences || {};
    const hasGoals = Array.isArray(mp.goals) && mp.goals.length > 0;
    const hasRelationship = !!str(mp.relationship_status);
    const hasPreferredGender = !!str(mp.preferred_therapist_gender);

    const complete =
      hasName &&
      hasPhone &&
      hasGender &&
      hasGoals &&
      hasRelationship &&
      hasPreferredGender;
    if (!complete) return null;

    try {
      await change.after.ref.update({
        has_complete_profile: true,
        completed_via: 'auto_sync_trigger',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`syncProfileCompletion: marked users/${context.params.userId} complete`);
    } catch (err) {
      console.error(`syncProfileCompletion failed for ${context.params.userId}:`, err);
    }
    return null;
  });

/**
 * One-off backfill: reconcile Firebase Auth ↔ Firestore. For every Auth user
 * without a users/{uid} doc, seed one from Auth metadata. Idempotent — safe
 * to run multiple times. Admin-only.
 *
 * Run from the Firebase console (Functions → Run on demand) with empty data,
 * or via:
 *   firebase functions:shell
 *   > backfillOrphanUsers({dryRun: false})
 */
exports.backfillOrphanUsers = functions
  .runWith({ timeoutSeconds: 540, memory: '512MB' })
  .https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.token.admin) {
      const email = context.auth?.token?.email;
      const adminEmails = ['mbardouni44@gmail.com', 'sanadpsy@gmail.com'];
      if (!email || !adminEmails.includes(email)) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Admin access required.'
        );
      }
    }

    const dryRun = data?.dryRun === true;
    const stats = {
      totalAuth: 0,
      orphans: 0,
      missingCreatedAt: 0,
      seeded: 0,
      repaired: 0,
    };

    let pageToken;
    const orphans = [];
    const missingCreatedAt = [];

    do {
      const page = await admin.auth().listUsers(1000, pageToken);
      for (const user of page.users) {
        stats.totalAuth++;
        const doc = await db.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          orphans.push(user);
          stats.orphans++;
        } else if (!doc.data().created_at) {
          missingCreatedAt.push(user);
          stats.missingCreatedAt++;
        }
      }
      pageToken = page.pageToken;
    } while (pageToken);

    if (dryRun) {
      return { ...stats, dryRun: true };
    }

    // Seed orphans in batches of 400
    for (let i = 0; i < orphans.length; i += 400) {
      const batch = db.batch();
      const chunk = orphans.slice(i, i + 400);
      for (const user of chunk) {
        const providerId = user.providerData?.[0]?.providerId || 'unknown';
        const authProvider = providerId.includes('phone')
          ? 'phone'
          : providerId.includes('google')
            ? 'google'
            : providerId.includes('apple')
              ? 'apple'
              : providerId.includes('password')
                ? 'email'
                : providerId;
        const createdAt = user.metadata?.creationTime
          ? admin.firestore.Timestamp.fromDate(new Date(user.metadata.creationTime))
          : admin.firestore.FieldValue.serverTimestamp();
        batch.set(
          db.collection('users').doc(user.uid),
          {
            email: user.email || null,
            // Leave null (not the literal 'User') for nameless signups.
            name: user.displayName || null,
            phone: user.phoneNumber || null,
            avatar_url: user.photoURL || null,
            role: 'user',
            auth_provider: authProvider,
            created_at: createdAt,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
            last_login: user.metadata?.lastSignInTime
              ? admin.firestore.Timestamp.fromDate(new Date(user.metadata.lastSignInTime))
              : admin.firestore.FieldValue.serverTimestamp(),
            created_by: 'backfill_callable',
            settings: {
              notifications_enabled: true,
              daily_reminders: true,
              mood_tracking_reminders: true,
              reminder_time: '09:00',
              dark_mode: false,
              language: 'English',
            },
          },
          { merge: true }
        );
      }
      await batch.commit();
      stats.seeded += chunk.length;
    }

    // Repair missing created_at in batches of 400
    for (let i = 0; i < missingCreatedAt.length; i += 400) {
      const batch = db.batch();
      const chunk = missingCreatedAt.slice(i, i + 400);
      for (const user of chunk) {
        const createdAt = user.metadata?.creationTime
          ? admin.firestore.Timestamp.fromDate(new Date(user.metadata.creationTime))
          : admin.firestore.FieldValue.serverTimestamp();
        batch.set(
          db.collection('users').doc(user.uid),
          {
            created_at: createdAt,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
            repaired_by: 'backfill_callable',
          },
          { merge: true }
        );
      }
      await batch.commit();
      stats.repaired += chunk.length;
    }

    functions.logger.info('backfillOrphanUsers complete', stats);
    return stats;
  });

/**
 * completeProfile — single server-side authority for writing user-identity
 * and profile-completion fields. The client never writes these directly;
 * it calls this callable instead. The callable validates input, ensures the
 * caller owns the doc, and updates atomically. Errors return typed
 * HttpsError codes the client can branch on.
 *
 * Input shape (all optional, only present fields are written):
 *   {
 *     first_name?: string,
 *     last_name?: string,
 *     display_name?: string,
 *     phone?: string,
 *     whatsapp_number?: string,
 *     whatsapp_consent?: boolean,
 *     whatsapp_ads_consent?: boolean,
 *     date_of_birth?: ISO8601 string,
 *     gender?: 'male' | 'female' | 'other' | 'prefer_not_to_say',
 *     avatar_url?: string,
 *     matching_preferences?: object,
 *   }
 *
 * Always sets: has_complete_profile=true (if display_name+phone present),
 * profile_completion_percentage (computed), updated_at, completed_via='callable'.
 *
 * Auth provider (phone/email/google) and role come from the auth.onCreate
 * trigger; this callable never touches them. created_at, role, is_premium,
 * subscription_*, assigned_therapist_* are admin-only.
 */
exports.completeProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Sign in is required to update your profile.'
    );
  }

  const uid = context.auth.uid;
  const input = data || {};

  // Whitelist — anything not here is silently dropped. Prevents client from
  // smuggling role/created_at/is_premium etc through this callable.
  const ALLOWED_TEXT = [
    'first_name',
    'last_name',
    'display_name',
    'phone',
    'whatsapp_number',
    'avatar_url',
  ];
  const ALLOWED_BOOL = ['whatsapp_consent', 'whatsapp_ads_consent'];
  const ALLOWED_ENUM_GENDER = ['male', 'female', 'other', 'prefer_not_to_say'];

  const update = {};
  for (const key of ALLOWED_TEXT) {
    if (typeof input[key] === 'string' && input[key].trim().length > 0) {
      const v = input[key].trim();
      if (v.length > 200) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `${key} must be 200 characters or fewer.`
        );
      }
      update[key] = v;
    }
  }
  for (const key of ALLOWED_BOOL) {
    if (typeof input[key] === 'boolean') {
      update[key] = input[key];
    }
  }
  if (typeof input.gender === 'string' && ALLOWED_ENUM_GENDER.includes(input.gender)) {
    update.gender = input.gender;
  }
  if (typeof input.date_of_birth === 'string') {
    const dob = new Date(input.date_of_birth);
    if (Number.isNaN(dob.getTime())) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'date_of_birth must be a valid ISO 8601 string.'
      );
    }
    update.date_of_birth = admin.firestore.Timestamp.fromDate(dob);
  }
  if (input.matching_preferences && typeof input.matching_preferences === 'object') {
    // Shallow copy only — reject nested functions/circular refs.
    update.matching_preferences = JSON.parse(JSON.stringify(input.matching_preferences));
  }

  // Compose display_name if first_name + last_name supplied without display_name
  if (!update.display_name && (update.first_name || update.last_name)) {
    update.display_name = [update.first_name, update.last_name]
      .filter(Boolean)
      .join(' ')
      .trim();
  }

  if (Object.keys(update).length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'No valid profile fields provided.'
    );
  }

  const userRef = db.collection('users').doc(uid);

  try {
    await db.runTransaction(async tx => {
      const snap = await tx.get(userRef);
      if (!snap.exists) {
        // The auth.onCreate trigger should have created this. If it has not
        // landed yet (very rare race on cold start), create the baseline so
        // the callable still succeeds.
        const authUser = await admin.auth().getUser(uid);
        const seed = {
          email: authUser.email || null,
          name: authUser.displayName || null,
          phone: authUser.phoneNumber || null,
          avatar_url: authUser.photoURL || null,
          role: 'user',
          auth_provider: (authUser.providerData?.[0]?.providerId || 'unknown')
            .replace('.com', '')
            .replace('password', 'email'),
          created_at: authUser.metadata?.creationTime
            ? admin.firestore.Timestamp.fromDate(new Date(authUser.metadata.creationTime))
            : admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          last_login: admin.firestore.FieldValue.serverTimestamp(),
          created_by: 'complete_profile_callable',
          settings: {
            notifications_enabled: true,
            daily_reminders: true,
            mood_tracking_reminders: true,
            reminder_time: '09:00',
            dark_mode: false,
            language: 'English',
          },
        };
        tx.set(userRef, { ...seed, ...update, has_complete_profile: true });
        return;
      }

      const existing = snap.data() || {};
      const merged = { ...existing, ...update };
      // Mark complete only against the SAME full mandatory set the app gate and
      // syncProfileCompletion trigger require — otherwise a callable invocation
      // with just {display_name, phone} would wave a user past the gate with no
      // gender/goals/matching preferences, breaking therapist matching.
      const s = (v) => (v == null ? '' : String(v).trim());
      const mp = merged.matching_preferences || {};
      const isComplete =
        (!!s(merged.display_name) || !!s(merged.first_name)) &&
        (!!s(merged.phone) || !!s(merged.whatsapp_number)) &&
        !!s(merged.gender) &&
        Array.isArray(mp.goals) && mp.goals.length > 0 &&
        !!s(mp.relationship_status) &&
        !!s(mp.preferred_therapist_gender);

      // UPGRADE-ONLY: never flip an already-complete user back to incomplete
      // (that would re-prompt an existing user = losing them). Only ever move
      // false → true.
      const finalUpdate = {
        ...update,
        has_complete_profile: existing.has_complete_profile === true || isComplete,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        completed_via: 'callable',
      };
      tx.update(userRef, finalUpdate);
    });

    functions.logger.info('completeProfile success', {
      uid,
      fields: Object.keys(update),
    });

    return { success: true, uid };
  } catch (err) {
    if (err instanceof functions.https.HttpsError) throw err;
    functions.logger.error('completeProfile failed', { uid, error: err.message });
    throw new functions.https.HttpsError(
      'internal',
      'Profile update failed. Please try again.'
    );
  }
});

/**
 * Delete all documents in a list from maintenance_subscribers collection.
 */
async function _deleteSubscribers(subscriberIds) {
  if (!subscriberIds.length) return;
  const batch = db.batch();
  subscriberIds.forEach(id => {
    batch.delete(db.collection('maintenance_subscribers').doc(id));
  });
  await batch.commit();
  console.log(`Cleaned up ${subscriberIds.length} maintenance subscribers`);
}



// ============================================================================
// ACCOUNT DELETION (GDPR / Play Store data-deletion compliance)
// ============================================================================

/**
 * Permanently delete a user account and erase all associated data.
 *
 * Callable by:
 *   - The user themselves (deletes own account) — no `uid` arg needed.
 *   - An admin (pass `data.uid` to delete another user's account) — used to
 *     action manual deletion requests from the dashboard.
 *
 * Wipes, in order:
 *   1. users/{uid} + ALL subcollections (clinical_notes, mood_entries, …) via
 *      recursiveDelete.
 *   2. support_chats/{uid} + its messages subcollection.
 *   3. Top-level user-owned docs across known collections (queried by the
 *      collection's user-key field), each recursively deleted so nested
 *      subcollections (e.g. therapist_chats/{id}/messages) go too.
 *   4. user_fcm_tokens/{uid}.
 *   5. The Firebase Auth record (last — irreversible).
 *
 * Idempotent: missing docs / empty queries are skipped silently.
 */
exports.deleteAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to delete an account'
    );
  }

  const callerUid = context.auth.uid;
  const requestedUid = (data && typeof data.uid === 'string' && data.uid.trim())
    ? data.uid.trim()
    : null;

  // Resolve the target. Deleting someone else requires an admin caller.
  let targetUid = callerUid;
  if (requestedUid && requestedUid !== callerUid) {
    const hasAdminClaim = context.auth.token.admin === true;
    let isAdmin = hasAdminClaim;
    if (!isAdmin) {
      const callerDoc = await db.collection('users').doc(callerUid).get();
      isAdmin = callerDoc.exists && callerDoc.data().role === 'admin';
    }
    if (!isAdmin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can delete another user\'s account'
      );
    }
    targetUid = requestedUid;
  }

  // Collections holding top-level docs owned by the user, with the field that
  // references them. Each matched doc is recursively deleted.
  const ownedCollections = [
    { name: 'bookings', fields: ['client_id', 'user_id'] },
    { name: 'mood_entries', fields: ['user_id'] },
    { name: 'payments', fields: ['user_id'] },
    { name: 'payment_verifications', fields: ['user_id'] },
    { name: 'notifications', fields: ['user_id'] },
    { name: 'therapist_chats', fields: ['user_id'] },
    { name: 'call_invites', fields: ['caller_id', 'callee_id'] },
    { name: 'ai_chats', fields: ['user_id'] },
    { name: 'test_results', fields: ['user_id'] },
    { name: 'reviews', fields: ['user_id'] },
    { name: 'bookmarks', fields: ['user_id'] },
    { name: 'user_reactions', fields: ['user_id'] },
    { name: 'challenge_completions', fields: ['user_id'] },
    { name: 'freemius_purchases', fields: ['user_id'] },
  ];

  try {
    // 1. Profile doc + all its subcollections.
    await db.recursiveDelete(db.collection('users').doc(targetUid));

    // 2. Support chat thread + messages.
    await db.recursiveDelete(db.collection('support_chats').doc(targetUid));

    // 3. Top-level owned docs.
    let deletedDocs = 0;
    for (const col of ownedCollections) {
      for (const field of col.fields) {
        let snap;
        try {
          snap = await db
            .collection(col.name)
            .where(field, '==', targetUid)
            .get();
        } catch (e) {
          // Field/index may not exist on this collection — skip safely.
          console.warn(`deleteAccount: skip ${col.name}.${field}: ${e.message}`);
          continue;
        }
        for (const doc of snap.docs) {
          await db.recursiveDelete(doc.ref);
          deletedDocs++;
        }
      }
    }

    // 4. FCM token doc (keyed by uid).
    await db.collection('user_fcm_tokens').doc(targetUid).delete().catch(() => {});

    // 5. Auth record — irreversible, do it last.
    try {
      await admin.auth().deleteUser(targetUid);
    } catch (e) {
      // user-not-found is fine (already gone); rethrow anything else.
      if (e.code !== 'auth/user-not-found') throw e;
    }

    console.log(
      `deleteAccount: erased user ${targetUid} (by ${callerUid}), ` +
      `${deletedDocs} owned docs removed`
    );

    return { success: true, uid: targetUid, deletedDocs };
  } catch (error) {
    console.error(`deleteAccount failed for ${targetUid}:`, error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
