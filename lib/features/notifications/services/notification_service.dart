import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';

class NotificationActionResult {
  final bool success;
  final int processedCount;
  final int failedCount;
  final String? error;

  const NotificationActionResult({
    required this.success,
    this.processedCount = 0,
    this.failedCount = 0,
    this.error,
  });

  bool get hasPartialFailure => failedCount > 0;
}

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _notificationsRef =>
      _firestore.collection('notifications');

  /// Delete old notifications that have no action_route set
  Future<void> deleteNotificationsWithoutRoute(String userId) async {
    try {
      final docs = await _notificationsRef
          .where('user_id', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      int count = 0;
      for (final doc in docs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final route = data['action_route'];
        if (route == null || (route is String && route.isEmpty)) {
          batch.delete(doc.reference);
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
        debugPrint('🗑️ Deleted $count old notifications without routes');
      }
    } catch (e, st) {
      _logError('deleteNotificationsWithoutRoute', e, st);
    }
  }

  /// Stream of notifications for a user
  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _notificationsRef
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get unread count for a user
  Stream<int> getUnreadCountStream(String userId) {
    return _notificationsRef
        .where('user_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a notification as read
  Future<NotificationActionResult> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({
        'is_read': true,
        'read_at': FieldValue.serverTimestamp(),
      });
      return const NotificationActionResult(success: true, processedCount: 1);
    } catch (e, st) {
      _logError('markAsRead', e, st);
      return NotificationActionResult(
        success: false,
        failedCount: 1,
        error: 'Failed to mark notification as read',
      );
    }
  }

  /// Mark all notifications as read for a user
  Future<NotificationActionResult> markAllAsRead(String userId) async {
    try {
      final unreadDocs = await _notificationsRef
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      if (unreadDocs.docs.isEmpty) {
        return const NotificationActionResult(success: true);
      }

      final batch = _firestore.batch();
      for (final doc in unreadDocs.docs) {
        batch.update(doc.reference, {
          'is_read': true,
          'read_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      return NotificationActionResult(
        success: true,
        processedCount: unreadDocs.docs.length,
      );
    } catch (e, st) {
      _logError('markAllAsRead.batch', e, st);

      final fallback = await _markAllAsReadFallback(userId);
      return fallback;
    }
  }

  /// Delete a notification
  Future<NotificationActionResult> deleteNotification(
    String notificationId,
  ) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
      return const NotificationActionResult(success: true, processedCount: 1);
    } catch (e, st) {
      _logError('deleteNotification', e, st);
      return NotificationActionResult(
        success: false,
        failedCount: 1,
        error: 'Failed to delete notification',
      );
    }
  }

  /// Clear all notifications for a user
  Future<NotificationActionResult> clearAllNotifications(String userId) async {
    try {
      final docs = await _notificationsRef
          .where('user_id', isEqualTo: userId)
          .get();
      if (docs.docs.isEmpty) {
        return const NotificationActionResult(success: true);
      }

      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return NotificationActionResult(
        success: true,
        processedCount: docs.docs.length,
      );
    } catch (e, st) {
      _logError('clearAllNotifications.batch', e, st);
      return _clearAllNotificationsFallback(userId);
    }
  }

  /// Validate that a user exists
  Future<bool> _validateUserExists(String userId) async {
    if (userId.isEmpty) return false;
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.exists;
    } catch (e, st) {
      _logError('validateUserExists', e, st);
      return false;
    }
  }

  /// Create a notification (usually called from backend/cloud functions)
  /// Only creates if target user exists
  Future<NotificationActionResult> createNotification(
    AppNotification notification,
  ) async {
    // Validate target user exists before creating notification
    if (!await _validateUserExists(notification.userId)) {
      return const NotificationActionResult(
        success: false,
        failedCount: 1,
        error: 'Target user does not exist',
      );
    }
    try {
      await _notificationsRef.add(notification.toFirestore());
      return const NotificationActionResult(success: true, processedCount: 1);
    } catch (e, st) {
      _logError('createNotification', e, st);
      return NotificationActionResult(
        success: false,
        failedCount: 1,
        error: 'Failed to create notification',
      );
    }
  }

  /// Create a booking notification
  Future<NotificationActionResult> createBookingNotification({
    required String userId,
    required String title,
    required String body,
    String? bookingId,
  }) async {
    return createNotification(
      AppNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: NotificationType.booking,
        createdAt: DateTime.now(),
        data: bookingId != null ? {'booking_id': bookingId} : null,
        // Route to general bookings screen (no specific booking detail route for users)
        actionRoute: '/bookings',
      ),
    );
  }

  /// Create a message notification
  Future<NotificationActionResult> createMessageNotification({
    required String userId,
    required String title,
    required String body,
    String? chatId,
    String? senderId,
  }) async {
    return createNotification(
      AppNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: NotificationType.message,
        createdAt: DateTime.now(),
        data: {
          if (chatId != null) 'chat_id': chatId,
          if (senderId != null) 'sender_id': senderId,
        },
        actionRoute: chatId != null ? '/chat/therapist/$chatId' : '/chat',
      ),
    );
  }

  /// Create a call notification (missed, declined, etc.)
  Future<NotificationActionResult> createCallNotification({
    required String userId,
    required String title,
    required String body,
    required String chatId,
    String? callerName,
    String? inviteId,
  }) async {
    return createNotification(
      AppNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: NotificationType.call,
        createdAt: DateTime.now(),
        data: {
          'chat_id': chatId,
          if (callerName != null) 'caller_name': callerName,
          if (inviteId != null) 'invite_id': inviteId,
        },
        actionRoute: '/chat/therapist/$chatId',
      ),
    );
  }

  /// Create a community notification (for comments or reactions)
  Future<NotificationActionResult> createCommunityNotification({
    required String userId,
    required String title,
    required String body,
    required String postId,
    String? commenterId,
    String? reactorId,
    bool isComment = false,
  }) async {
    // Don't notify the user about their own actions
    if (userId == commenterId || userId == reactorId) {
      return const NotificationActionResult(success: true);
    }

    return createNotification(
      AppNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: NotificationType.community,
        createdAt: DateTime.now(),
        data: {
          'post_id': postId,
          if (commenterId != null) 'commenter_id': commenterId,
          if (reactorId != null) 'reactor_id': reactorId,
          'is_comment': isComment,
        },
        // Route to general community screen (no specific post detail route)
        // The community screen can potentially scroll to the specific post if needed
        actionRoute: '/community',
      ),
    );
  }

  Future<NotificationActionResult> _markAllAsReadFallback(String userId) async {
    int processed = 0;
    int failed = 0;

    try {
      final unreadDocs = await _notificationsRef
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      for (final doc in unreadDocs.docs) {
        try {
          await doc.reference.update({
            'is_read': true,
            'read_at': FieldValue.serverTimestamp(),
          });
          processed++;
        } catch (_) {
          failed++;
        }
      }
    } catch (e, st) {
      _logError('markAllAsRead.fallback', e, st);
      return NotificationActionResult(
        success: false,
        failedCount: failed,
        error: 'Failed to mark notifications as read',
      );
    }

    return NotificationActionResult(
      success: failed == 0,
      processedCount: processed,
      failedCount: failed,
      error: failed > 0 ? 'Some notifications were not updated' : null,
    );
  }

  Future<NotificationActionResult> _clearAllNotificationsFallback(
    String userId,
  ) async {
    int processed = 0;
    int failed = 0;

    try {
      final docs = await _notificationsRef
          .where('user_id', isEqualTo: userId)
          .get();
      for (final doc in docs.docs) {
        try {
          await doc.reference.delete();
          processed++;
        } catch (_) {
          failed++;
        }
      }
    } catch (e, st) {
      _logError('clearAllNotifications.fallback', e, st);
      return NotificationActionResult(
        success: false,
        failedCount: failed,
        error: 'Failed to clear notifications',
      );
    }

    return NotificationActionResult(
      success: failed == 0,
      processedCount: processed,
      failedCount: failed,
      error: failed > 0 ? 'Some notifications could not be deleted' : null,
    );
  }

  void _logError(String phase, Object error, StackTrace stackTrace) {
    debugPrint('NotificationService Error [$phase]: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
