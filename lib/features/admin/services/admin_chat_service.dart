import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['is_read'] ?? false,
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
}

/// Page size for paginated user fetching in broadcast (M6.1).
const int _kBroadcastUserPageSize = 400;

class AdminChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // Stream of messages for a specific user chat
  // Returns oldest first to work with reverse: true in UI
  Stream<List<ChatMessage>> getMessages(String userId) {
    return _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
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
  }) async {
    final batch = _firestore.batch();

    // 1. Add message to subcollection
    final messageRef = _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .doc(); // Auto-ID

    batch.set(messageRef, {
      'sender_id': 'admin',
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
    });

    // 2. Update thread metadata
    final threadRef = _firestore.collection('support_chats').doc(userId);

    final threadData = {
      'last_message': content,
      'last_message_time': FieldValue.serverTimestamp(),
      'unread_count_user': FieldValue.increment(1),
    };

    if (userEmail != null) threadData['user_email'] = userEmail;
    if (userName != null) threadData['user_name'] = userName;

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
        batch.set(threadRef, {
          'user_email': userData['email'] ?? 'Unknown',
          'user_name': userData['name'] ?? '',
          'last_message': content,
          'last_message_time': FieldValue.serverTimestamp(),
          'unread_count_user': FieldValue.increment(1),
        }, SetOptions(merge: true));

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
