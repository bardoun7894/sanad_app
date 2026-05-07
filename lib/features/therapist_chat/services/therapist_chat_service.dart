import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/therapist_chat.dart';
import '../models/therapist_message.dart';

class TherapistChatException implements Exception {
  final String code;
  final String message;

  const TherapistChatException({required this.code, required this.message});

  @override
  String toString() => message;
}

/// Service for managing therapist-user chat functionality
class TherapistChatService {
  final FirebaseFirestore _firestore;

  static const String _chatsCollection = 'therapist_chats';
  static const String _messagesSubcollection = 'messages';

  TherapistChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get reference to a chat document
  DocumentReference _chatDoc(String chatId) =>
      _firestore.collection(_chatsCollection).doc(chatId);

  /// Get reference to messages subcollection
  CollectionReference _messagesCollection(String chatId) =>
      _chatDoc(chatId).collection(_messagesSubcollection);

  // ============= Chat Thread Operations =============

  /// Get or create a chat thread between therapist and user
  Future<TherapistChatThread> getOrCreateChat({
    required String therapistId,
    required String userId,
    required String therapistName,
    required String userName,
    String? therapistPhotoUrl,
    String? userPhotoUrl,
    String? bookingId,
    ChatSource source = ChatSource.booking,
    String? aiContext,
  }) async {
    try {
      final chatId = TherapistChatThread.generateChatId(therapistId, userId);
      final docRef = _chatDoc(chatId);
      final doc = await docRef.get();

      if (doc.exists) {
        final existingThread = TherapistChatThread.fromFirestore(doc);
        if (bookingId != null &&
            !existingThread.bookingIds.contains(bookingId)) {
          await docRef.update({
            'booking_ids': FieldValue.arrayUnion([bookingId]),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
        return existingThread;
      }

      final now = DateTime.now();
      final newThread = TherapistChatThread(
        chatId: chatId,
        therapistId: therapistId,
        userId: userId,
        therapistName: therapistName,
        therapistPhotoUrl: therapistPhotoUrl,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        bookingId: bookingId,
        bookingIds: bookingId != null ? [bookingId] : [],
        source: source,
        aiContext: aiContext,
        createdAt: now,
        updatedAt: now,
        lastMessageTime: now,
      );

      await docRef.set(newThread.toFirestore());

      if (aiContext != null && aiContext.isNotEmpty) {
        await _addSystemMessage(
          chatId: chatId,
          content: 'Previous conversation context:\n$aiContext',
        );
      }

      return newThread;
    } on FirebaseException catch (e, st) {
      debugPrint('TherapistChat getOrCreateChat failed: ${e.message}');
      debugPrintStack(stackTrace: st);
      throw const TherapistChatException(
        code: 'chat_thread_create_failed',
        message: 'Unable to open chat right now. Please try again.',
      );
    } catch (e, st) {
      debugPrint('TherapistChat getOrCreateChat unexpected: $e');
      debugPrintStack(stackTrace: st);
      throw const TherapistChatException(
        code: 'chat_thread_create_failed',
        message: 'Unable to open chat right now. Please try again.',
      );
    }
  }

  /// Get chat thread by ID
  Future<TherapistChatThread?> getChatThread(String chatId) async {
    final doc = await _chatDoc(chatId).get();
    if (!doc.exists) return null;
    return TherapistChatThread.fromFirestore(doc);
  }

  /// Stream all chats for a therapist
  Stream<List<TherapistChatThread>> getChatsForTherapist(String therapistId) {
    return _firestore
        .collection(_chatsCollection)
        .where('therapist_id', isEqualTo: therapistId)
        .where('status', isEqualTo: ChatThreadStatus.active.name)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading therapist chats: $error');
          debugPrint(
            'This may be due to missing Firestore indexes or no data.',
          );
          debugPrint('Check Firebase Console > Firestore > Indexes');
          return <TherapistChatThread>[];
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TherapistChatThread.fromFirestore(doc))
              .toList();
        });
  }

  /// Stream all chats for a user
  Stream<List<TherapistChatThread>> getChatsForUser(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: ChatThreadStatus.active.name)
        .orderBy('last_message_time', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading user chats: $error');
          debugPrint(
            'This may be due to missing Firestore indexes or no data.',
          );
          debugPrint('Check Firebase Console > Firestore > Indexes');
          return <TherapistChatThread>[];
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TherapistChatThread.fromFirestore(doc))
              .toList();
        });
  }

  /// Get total unread count for therapist
  Stream<int> getUnreadCountForTherapist(String therapistId) {
    return _firestore
        .collection(_chatsCollection)
        .where('therapist_id', isEqualTo: therapistId)
        .where('unread_count_therapist', isGreaterThan: 0)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            total += (doc.data()['unread_count_therapist'] as int?) ?? 0;
          }
          return total;
        });
  }

  /// Get total unread count for user
  Stream<int> getUnreadCountForUser(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('user_id', isEqualTo: userId)
        .where('unread_count_user', isGreaterThan: 0)
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (final doc in snapshot.docs) {
            total += (doc.data()['unread_count_user'] as int?) ?? 0;
          }
          return total;
        });
  }

  // ============= Message Operations =============

  /// Stream messages for a chat
  Stream<List<TherapistMessage>> getMessages(String chatId) {
    return _messagesCollection(
      chatId,
    ).orderBy('timestamp', descending: false).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TherapistMessage.fromFirestore(doc))
          .toList();
    });
  }

  /// Send a message
  Future<TherapistMessage> sendMessage({
    required String chatId,
    required String senderId,
    String? senderName,
    required SenderType senderType,
    required String content,
    TherapistMessageType messageType = TherapistMessageType.text,
    List<MessageAttachment>? attachments,
    MessageMetadata? metadata,
  }) async {
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();

      final message = TherapistMessage(
        id: messageId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        content: content,
        messageType: messageType,
        timestamp: DateTime.now(),
        status: MessageDeliveryStatus.sent,
        attachments: attachments,
        metadata: metadata,
      );

      final batch = _firestore.batch();
      batch.set(
        _messagesCollection(chatId).doc(messageId),
        message.toFirestore(),
      );

      await batch.commit();
      return message;
    } on FirebaseException catch (e, st) {
      debugPrint('TherapistChat sendMessage failed: ${e.message}');
      debugPrintStack(stackTrace: st);
      throw const TherapistChatException(
        code: 'message_send_failed',
        message: 'Failed to send message. Please try again.',
      );
    } catch (e, st) {
      debugPrint('TherapistChat sendMessage unexpected: $e');
      debugPrintStack(stackTrace: st);
      throw const TherapistChatException(
        code: 'message_send_failed',
        message: 'Failed to send message. Please try again.',
      );
    }
  }

  /// Add a system message (for context transfer, notifications, etc.)
  Future<void> addSystemMessage({
    required String chatId,
    required String content,
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    final message = TherapistMessage(
      id: messageId,
      senderId: 'system',
      senderType: SenderType.system,
      content: content,
      messageType: TherapistMessageType.system,
      timestamp: DateTime.now(),
      isRead: true,
    );

    await _messagesCollection(chatId).doc(messageId).set(message.toFirestore());
  }

  /// Legacy private wrapper
  Future<void> _addSystemMessage({
    required String chatId,
    required String content,
  }) async {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    final message = TherapistMessage(
      id: messageId,
      senderId: 'system',
      senderType: SenderType.system,
      content: content,
      messageType: TherapistMessageType.system,
      timestamp: DateTime.now(),
      isRead: true,
    );

    await _messagesCollection(chatId).doc(messageId).set(message.toFirestore());
  }

  /// Mark messages as read
  Future<void> markAsRead({
    required String chatId,
    required SenderType readerType,
  }) async {
    try {
      // Check if chat document exists before updating
      final chatDoc = await _chatDoc(chatId).get();
      if (!chatDoc.exists) return;

      final batch = _firestore.batch();

      // Update chat unread count
      if (readerType == SenderType.therapist) {
        batch.update(_chatDoc(chatId), {'unread_count_therapist': 0});
      } else {
        batch.update(_chatDoc(chatId), {'unread_count_user': 0});
      }

      // Mark all unread messages as read
      final otherSenderType = readerType == SenderType.therapist
          ? SenderType.user
          : SenderType.therapist;

      final unreadMessages = await _messagesCollection(chatId)
          .where('sender_type', isEqualTo: otherSenderType.name)
          .where('is_read', isEqualTo: false)
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'is_read': true,
          'read_at': FieldValue.serverTimestamp(),
          'status': MessageDeliveryStatus.read.name,
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // ============= Typing Indicators =============

  /// Update typing status
  Future<void> updateTypingStatus({
    required String chatId,
    required SenderType senderType,
    required bool isTyping,
  }) async {
    try {
      // Check if chat document exists before updating
      final chatDoc = await _chatDoc(chatId).get();
      if (!chatDoc.exists) return;

      final field = senderType == SenderType.therapist ? 'therapist' : 'user';
      final timestampField = senderType == SenderType.therapist
          ? 'therapist_timestamp'
          : 'user_timestamp';

      await _chatDoc(chatId).update({
        'typing.$field': isTyping,
        'typing.$timestampField': isTyping
            ? FieldValue.serverTimestamp()
            : null,
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  /// Stream typing status for a chat
  Stream<TypingStatus> getTypingStatus(String chatId) {
    return _chatDoc(chatId).snapshots().map((doc) {
      if (!doc.exists) return const TypingStatus();
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['typing'] == null) return const TypingStatus();
      return TypingStatus.fromFirestore(data['typing'] as Map<String, dynamic>);
    });
  }

  // ============= Chat Management =============

  /// Archive a chat thread
  Future<void> archiveChat(String chatId) async {
    await _chatDoc(chatId).update({
      'status': ChatThreadStatus.archived.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Unarchive a chat thread
  Future<void> unarchiveChat(String chatId) async {
    await _chatDoc(chatId).update({
      'status': ChatThreadStatus.active.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a chat thread and all messages (admin only)
  Future<void> deleteChat(String chatId) async {
    // Delete all messages first
    final messages = await _messagesCollection(chatId).get();
    final batch = _firestore.batch();

    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete the chat document
    batch.delete(_chatDoc(chatId));

    await batch.commit();
  }

  /// Replace the old therapist chat with a new one.
  /// Deletes the old chat thread (if any) and creates a new one.
  Future<TherapistChatThread> replaceChat({
    required String oldTherapistId,
    required String newTherapistId,
    required String userId,
    required String newTherapistName,
    required String newTherapistPhotoUrl,
    required String userName,
    String? userPhotoUrl,
    ChatSource source = ChatSource.direct,
  }) async {
    // Delete old chat if exists
    if (oldTherapistId.isNotEmpty) {
      final oldChatId = TherapistChatThread.generateChatId(
        oldTherapistId,
        userId,
      );
      try {
        await deleteChat(oldChatId);
      } catch (e) {
        debugPrint('[TherapistChatService] replaceChat delete old failed: $e');
      }
    }

    // Create new chat
    return getOrCreateChat(
      therapistId: newTherapistId,
      userId: userId,
      therapistName: newTherapistName,
      therapistPhotoUrl: newTherapistPhotoUrl,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      source: source,
    );
  }

  /// Check if chat exists between therapist and user
  Future<bool> chatExists(String therapistId, String userId) async {
    final chatId = TherapistChatThread.generateChatId(therapistId, userId);
    final doc = await _chatDoc(chatId).get();
    return doc.exists;
  }

  /// Get chat ID for a therapist-user pair (null if doesn't exist)
  Future<String?> getChatId(String therapistId, String userId) async {
    final chatId = TherapistChatThread.generateChatId(therapistId, userId);
    final doc = await _chatDoc(chatId).get();
    return doc.exists ? chatId : null;
  }
}
