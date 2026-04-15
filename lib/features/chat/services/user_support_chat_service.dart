import 'package:cloud_firestore/cloud_firestore.dart';
import '../../admin/services/admin_chat_service.dart';

/// Service for user-side support chat functionality
/// Uses the same support_chats collection as AdminChatService
class UserSupportChatService {
  final FirebaseFirestore _firestore;

  UserSupportChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get or create a support chat thread for the user
  Future<void> getOrCreateThread({
    required String userId,
    required String userEmail,
    String? userName,
    String? aiContext,
    String? source, // 'direct' or 'ai_escalation'
  }) async {
    final threadRef = _firestore.collection('support_chats').doc(userId);
    final doc = await threadRef.get();

    if (!doc.exists) {
      await threadRef.set({
        'user_id': userId,
        'user_email': userEmail,
        'user_name': userName ?? 'User',
        'source': source ?? 'direct',
        'status': 'open',
        'priority': 'normal',
        'created_at': FieldValue.serverTimestamp(),
        'last_message_time': FieldValue.serverTimestamp(),
        'unread_count_admin': 0,
        'unread_count_user': 0,
        if (aiContext != null) 'ai_context': aiContext,
      });

      // Add initial system message if escalated from AI
      if (aiContext != null && source == 'ai_escalation') {
        await _firestore
            .collection('support_chats')
            .doc(userId)
            .collection('messages')
            .add({
              'sender_id': 'system',
              'content':
                  'User escalated from AI chat. Previous context has been shared with support team.',
              'timestamp': FieldValue.serverTimestamp(),
              'is_read': true,
              'type': 'system',
            });
      }
    }
  }

  /// Stream messages for the user's support chat
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

  /// Send a message from the user to support
  Future<void> sendUserMessage({
    required String userId,
    required String userEmail,
    required String content,
  }) async {
    final batch = _firestore.batch();

    // 1. Add message to subcollection
    final messageRef = _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .doc(); // Auto-ID

    batch.set(messageRef, {
      'sender_id': userId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
    });

    // 2. Update thread metadata
    final threadRef = _firestore.collection('support_chats').doc(userId);
    batch.set(threadRef, {
      'user_email': userEmail,
      'last_message': content.length > 100
          ? '${content.substring(0, 100)}...'
          : content,
      'last_message_time': FieldValue.serverTimestamp(),
      'unread_count_admin': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Mark messages as read by user
  Future<void> markAsRead(String userId) async {
    await _firestore.collection('support_chats').doc(userId).update({
      'unread_count_user': 0,
    });
  }

  /// Get unread count for user
  Stream<int> getUnreadCount(String userId) {
    return _firestore.collection('support_chats').doc(userId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return 0;
      final data = doc.data();
      return data?['unread_count_user'] as int? ?? 0;
    });
  }

  /// Check if user has an active support chat
  Future<bool> hasActiveChat(String userId) async {
    final doc = await _firestore.collection('support_chats').doc(userId).get();
    return doc.exists;
  }

  /// Get chat thread info
  Stream<SupportChatInfo?> getChatInfo(String userId) {
    return _firestore.collection('support_chats').doc(userId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return SupportChatInfo.fromFirestore(doc);
    });
  }
}

/// Support chat info model (user-side view)
class SupportChatInfo {
  final String status;
  final String priority;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool hasAdminResponse;

  SupportChatInfo({
    required this.status,
    required this.priority,
    required this.unreadCount,
    this.lastMessage,
    this.lastMessageTime,
    required this.hasAdminResponse,
  });

  factory SupportChatInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportChatInfo(
      status: data['status'] as String? ?? 'open',
      priority: data['priority'] as String? ?? 'normal',
      unreadCount: data['unread_count_user'] as int? ?? 0,
      lastMessage: data['last_message'] as String?,
      lastMessageTime: data['last_message_time'] != null
          ? (data['last_message_time'] as Timestamp).toDate()
          : null,
      hasAdminResponse: data['assigned_admin_id'] != null,
    );
  }
}
