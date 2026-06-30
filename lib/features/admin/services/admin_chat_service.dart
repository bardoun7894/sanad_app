import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/user_display_name.dart';

class BroadcastReport {
  final int sentCount;
  final int failedCount;
  final List<String> failedUserIds;
  final List<String> errors;

  const BroadcastReport({
    required this.sentCount,
    required this.failedCount,
    required this.failedUserIds,
    required this.errors,
  });

  bool get isSuccess => failedCount == 0;
}

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  /// Optional attached image (download URL). Null for plain text messages.
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['is_read'] ?? false,
      imageUrl: data['image_url'] as String?,
    );
  }
}

class ChatThread {
  final String userId;
  final String userEmail;
  final String userName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatThread({
    required this.userId,
    required this.userEmail,
    this.userName = '',
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatThread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatThread(
      userId: doc.id,
      userEmail: data['user_email'] ?? 'Unknown User',
      userName: data['user_name'] ?? '',
      lastMessage: data['last_message'] ?? '',
      lastMessageTime:
          (data['last_message_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unread_count_admin'] ?? 0,
    );
  }

  /// Best-effort display name using only the data already on this thread.
  /// Treats the legacy 'User' placeholder as absent so the caller can fall
  /// back to the user's email or resolve the real name from `users/{userId}`.
  String get fallbackDisplayName {
    final resolved = resolveDisplayName(displayName: userName);
    if (resolved != null && resolved.isNotEmpty) return resolved;
    return userEmail.isNotEmpty && userEmail != 'Unknown User'
        ? userEmail
        : 'Unknown User';
  }
}

/// Page size for paginated user fetching in broadcast (M6.1).
const int _kBroadcastUserPageSize = 400;

class AdminChatService {
  /// Allow injecting a custom [FirebaseFirestore] instance (e.g. for tests).
  AdminChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Stream of all chat threads
  Stream<List<ChatThread>> getChatThreads() {
    return _firestore
        .collection('support_chats')
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatThread.fromFirestore(doc))
              .toList(),
        );
  }

  /// Fetches the real user name from `users/{userId}` when the thread only
  /// holds a placeholder ('User') or empty name. Returns null when the user
  /// doc does not exist or no real name can be resolved.
  Future<String?> resolveRealName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return resolveDisplayNameFromUserDoc(userDoc.data()!);
      }
    } catch (e) {
      debugPrint('[AdminChatService] failed to resolve name for $userId: $e');
    }
    return null;
  }

  /// Resolves the best display name for a thread, reading from `users/{userId}`
  /// only when the cached thread name is missing or the legacy placeholder.
  ///
  /// Fallback order: cached name → real name from users doc → email →
  /// phone number → 'Unknown User'. The phone fallback keeps phone-only
  /// signups (no name, no email) from rendering as "Unknown User".
  Future<String> resolveDisplayNameForThread(ChatThread thread) async {
    final current = resolveDisplayName(displayName: thread.userName);
    if (current != null && current.isNotEmpty) return current;

    // Read the user doc once and try name, then phone.
    String? phone;
    try {
      final userDoc =
          await _firestore.collection('users').doc(thread.userId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final realName = resolveDisplayNameFromUserDoc(data);
        if (realName != null && realName.isNotEmpty) return realName;
        phone = _phoneFromUserData(data);
      }
    } catch (e) {
      debugPrint(
        '[AdminChatService] failed to resolve name for ${thread.userId}: $e',
      );
    }

    if (thread.userEmail.isNotEmpty && thread.userEmail != 'Unknown User') {
      return thread.userEmail;
    }
    if (phone != null && phone.isNotEmpty) return phone;
    return 'Unknown User';
  }

  /// Extracts a non-empty phone number from a `users/{uid}` data map, trying
  /// the common field aliases. Returns null when none is present.
  String? _phoneFromUserData(Map<String, dynamic> data) {
    for (final key in ['phone', 'phone_number', 'phoneNumber', 'whatsapp']) {
      final v = (data[key] as String?)?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Stream of a single [ChatThread] by userId. Emits null when no doc exists.
  /// Used as a fallback in AdminChatDetailScreen when GoRouter state.extra is
  /// lost on Flutter Web URL rehydration.
  Stream<ChatThread?> getChatThread(String userId) {
    return _firestore
        .collection('support_chats')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? ChatThread.fromFirestore(doc) : null);
  }

  // Stream of messages for a specific user chat
  // Returns newest first to work with reverse: true in UI (index 0 = newest = bottom)
  Stream<List<ChatMessage>> getMessages(String userId) {
    return _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  // Send a message from Admin
  Future<void> sendAdminMessage(
    String userId,
    String content, {
    String? userEmail,
    String? userName,
    String? imageUrl,
  }) async {
    final batch = _firestore.batch();

    // 1. Add message to subcollection
    final messageRef = _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .doc(); // Auto-ID

    // For image-only messages, store '📷' as the content so OLDER app builds
    // (which don't yet render image_url) show a placeholder instead of an empty
    // bubble. New builds detect image_url and suppress this placeholder text.
    final msgContent = (content.isEmpty && imageUrl != null) ? '📷' : content;

    batch.set(messageRef, {
      'sender_id': 'admin',
      'content': msgContent,
      if (imageUrl != null) 'image_url': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
    });

    // 2. Update thread metadata
    final threadRef = _firestore.collection('support_chats').doc(userId);

    // Show a sensible preview in the inbox list for image-only messages.
    final preview = (content.isEmpty && imageUrl != null) ? '📷 صورة' : content;

    final threadData = {
      'last_message': preview,
      'last_message_time': FieldValue.serverTimestamp(),
      'unread_count_user': FieldValue.increment(1),
    };

    if (userEmail != null) threadData['user_email'] = userEmail;

    // Never write placeholder 'User' as name — only write real names.
    final hasRealName = userName != null &&
        userName.trim().isNotEmpty &&
        userName.toLowerCase() != 'user';
    if (hasRealName) threadData['user_name'] = userName;

    batch.set(threadRef, threadData, SetOptions(merge: true));

    await batch.commit();
  }

  // Mark messages as read by admin
  Future<void> markAsRead(String userId) async {
    await _firestore.collection('support_chats').doc(userId).set({
      'unread_count_admin': 0,
    }, SetOptions(merge: true));
  }

  // Search users by email, name, or phone number
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    // 1. Exact Email Search
    final emailQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: query)
        .limit(5)
        .get();

    // 2. Name Range Search (approximate)
    final nameQuery = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .limit(5)
        .get();

    // 3. Phone Search (Exact)
    final phoneQuery = await _firestore
        .collection('users')
        .where('phone', isEqualTo: query)
        .limit(5)
        .get();

    // Merge results by UID to remove duplicates
    final Map<String, Map<String, dynamic>> merged = {};

    for (var doc in emailQuery.docs) {
      merged[doc.id] = {...doc.data(), 'uid': doc.id};
    }
    for (var doc in nameQuery.docs) {
      merged[doc.id] = {...doc.data(), 'uid': doc.id};
    }
    for (var doc in phoneQuery.docs) {
      merged[doc.id] = {...doc.data(), 'uid': doc.id};
    }

    return merged.values.toList();
  }

  /// Broadcast a message to ALL users
  /// Returns the count of users who received the message
  Future<int> broadcastMessage(String content) async {
    final report = await broadcastMessageWithReport(content);
    return report.sentCount;
  }

  /// Broadcast a message using paginated user fetching (M6.1).
  /// Instead of loading all users at once, fetches in pages of
  /// [_kBroadcastUserPageSize] using cursor-based pagination.
  Future<BroadcastReport> broadcastMessageWithReport(String content) async {
    int sentCount = 0;
    int failedCount = 0;
    final failedUserIds = <String>[];
    final errors = <String>[];

    DocumentSnapshot? lastDoc;
    bool hasMore = true;

    while (hasMore) {
      // Fetch a page of users using cursor pagination
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .orderBy(FieldPath.documentId)
          .limit(_kBroadcastUserPageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final usersSnapshot = await query.get();
      final users = usersSnapshot.docs;

      if (users.isEmpty) break;
      hasMore = users.length >= _kBroadcastUserPageSize;
      lastDoc = users.last;

      // Process this page in a Firestore batch
      final batch = _firestore.batch();
      final batchUserIds = <String>[];

      for (final user in users) {
        final userId = user.id;
        final userData = user.data();
        batchUserIds.add(userId);

        // 1. Add message to user's chat
        final messageRef = _firestore
            .collection('support_chats')
            .doc(userId)
            .collection('messages')
            .doc();

        batch.set(messageRef, {
          'sender_id': 'admin',
          'content': content,
          'timestamp': FieldValue.serverTimestamp(),
          'is_read': false,
          'is_broadcast': true,
        });

        // 2. Update/create thread metadata
        final threadRef = _firestore.collection('support_chats').doc(userId);
        final broadcastName = resolveDisplayNameFromUserDoc(userData) ?? '';
        batch.set(threadRef, {
          'user_email': userData['email'] ?? 'Unknown',
          'user_name': broadcastName,
          'last_message': content,
          'last_message_time': FieldValue.serverTimestamp(),
          'unread_count_user': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // 3. Create in-app notification for the user
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'user_id': userId,
          'title': 'New Message from Admin',
          'body': content,
          'type': 'system',
          'created_at': FieldValue.serverTimestamp(),
          'is_read': false,
          'data': {
            'is_broadcast': true,
          },
          'action_route': '/support-chat',
          'push_fcm': true,
        });

        sentCount++;
      }

      try {
        await batch.commit();
      } catch (e, st) {
        debugPrint('Broadcast batch commit failed: $e');
        debugPrintStack(stackTrace: st);

        sentCount -= batchUserIds.length;
        failedCount += batchUserIds.length;
        failedUserIds.addAll(batchUserIds);
        errors.add('Batch error: $e');
      }
    }

    return BroadcastReport(
      sentCount: sentCount,
      failedCount: failedCount,
      failedUserIds: failedUserIds,
      errors: errors,
    );
  }

  /// Broadcast a standalone announcement to every user's bell.
  ///
  /// Writes a single doc to `notifications/` per user — no chat thread,
  /// no message in support chat. This is the path the admin uses for
  /// general announcements, distinct from a chat broadcast.
  ///
  /// Returns the per-page progress as a [BroadcastReport]. Optional
  /// [actionRoute] lets the announcement deep-link somewhere on tap.
  Future<BroadcastReport> broadcastNotificationToAllUsers({
    required String title,
    required String body,
    String? actionRoute,
  }) async {
    int sentCount = 0;
    int failedCount = 0;
    final failedUserIds = <String>[];
    final errors = <String>[];

    DocumentSnapshot? lastDoc;
    bool hasMore = true;

    while (hasMore) {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .orderBy(FieldPath.documentId)
          .limit(_kBroadcastUserPageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final usersSnapshot = await query.get();
      final users = usersSnapshot.docs;
      if (users.isEmpty) break;
      hasMore = users.length >= _kBroadcastUserPageSize;
      lastDoc = users.last;

      final batch = _firestore.batch();
      final batchUserIds = <String>[];
      for (final user in users) {
        batchUserIds.add(user.id);
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'user_id': user.id,
          'title': title,
          'body': body,
          'type': 'system',
          'created_at': FieldValue.serverTimestamp(),
          'is_read': false,
          'data': {'is_announcement': true},
          if (actionRoute != null && actionRoute.isNotEmpty)
            'action_route': actionRoute,
          'push_fcm': true,
        });
        sentCount++;
      }

      try {
        await batch.commit();
      } catch (e, st) {
        debugPrint('Notification broadcast batch failed: $e');
        debugPrintStack(stackTrace: st);
        sentCount -= batchUserIds.length;
        failedCount += batchUserIds.length;
        failedUserIds.addAll(batchUserIds);
        errors.add('Batch error: $e');
      }
    }

    return BroadcastReport(
      sentCount: sentCount,
      failedCount: failedCount,
      failedUserIds: failedUserIds,
      errors: errors,
    );
  }

  /// Get users for broadcast selection — paginated (M6.1).
  /// Returns first page; use [getAllUsersPage] for subsequent pages.
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('name')
        .limit(100)
        .get();

    return snapshot.docs.map((doc) => {...doc.data(), 'uid': doc.id}).toList();
  }

  /// Permanently deletes a support-chat thread for both sides.
  ///
  /// Both the admin inbox and the client's support-chat screen read from the
  /// same `support_chats/{userId}` doc and its `messages` subcollection, so
  /// removing both makes the conversation disappear everywhere.
  ///
  /// Messages are deleted in batches of [_kDeleteBatchSize] (Firestore caps a
  /// batch at 500 writes) and the thread doc is removed last.
  Future<void> deleteChatThread(String userId) async {
    final messagesRef = _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages');

    // Delete messages in pages so threads with >500 messages don't exceed the
    // Firestore batch limit.
    while (true) {
      final page = await messagesRef.limit(_kDeleteBatchSize).get();
      if (page.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (page.docs.length < _kDeleteBatchSize) break;
    }

    // Finally remove the thread doc itself.
    await _firestore.collection('support_chats').doc(userId).delete();
  }

  /// Firestore hard-caps a batched write at 500 operations.
  static const int _kDeleteBatchSize = 450;

  // Create a dummy chat for testing (Seeding)
  Future<void> createDummyChat(String userId, String email) async {
    await _firestore.collection('support_chats').doc(userId).set({
      'user_email': email,
      'user_name': 'Test User',
      'last_message': 'Help needed with booking',
      'last_message_time': FieldValue.serverTimestamp(),
      'unread_count_admin': 1,
      'unread_count_user': 0,
    });

    await _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .add({
          'sender_id': userId,
          'content': 'Help needed with booking',
          'timestamp': FieldValue.serverTimestamp(),
          'is_read': false,
        });
  }
}
