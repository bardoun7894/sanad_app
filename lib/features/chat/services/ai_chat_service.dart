import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../../mood/models/mood_enums.dart';
// GeminiService still used for static crisis/escalation helpers only.
import '../../../core/services/gemini_service.dart';

// ── Public pure helpers (exported for unit tests) ──────────────────────────

/// Error kinds that can come back from the chatWithGemini callable.
enum CloudFunctionErrorKind {
  dailyLimitReached,
  permissionDenied,
  unauthenticated,
  generic,
}

/// Maps a [FirebaseFunctionsException.code] string to a typed enum.
CloudFunctionErrorKind classifyFunctionError(String code) {
  switch (code) {
    case 'resource-exhausted':
      return CloudFunctionErrorKind.dailyLimitReached;
    case 'permission-denied':
      return CloudFunctionErrorKind.permissionDenied;
    case 'unauthenticated':
      return CloudFunctionErrorKind.unauthenticated;
    default:
      return CloudFunctionErrorKind.generic;
  }
}

/// Friendly message shown when the user has hit their daily AI token cap.
String buildDailyLimitMessage() =>
    'Daily AI usage limit reached. Try again tomorrow.';

/// Maps a list of [Message]s to the payload format expected by chatWithGemini.
///
/// Rules:
/// - Keeps only the last [maxMessages] (default 20) to bound context size.
/// - [MessageType.user] → role 'user'; [MessageType.bot] → role 'model'.
/// - Other types (system, handoff) fall back to role 'user'.
List<Map<String, String>> prepareCloudPayload(
  List<Message> messages, {
  int maxMessages = 20,
}) {
  final windowed = messages.length > maxMessages
      ? messages.sublist(messages.length - maxMessages)
      : messages;

  return windowed.map((m) {
    final role = m.type == MessageType.bot ? 'model' : 'user';
    return {'role': role, 'content': m.content};
  }).toList();
}

/// Builds the payload map for the chatWithGemini callable.
///
/// Extracted as a pure function so it can be tested without a live service.
/// [persona] defaults to 'companion' if not provided.
Map<String, dynamic> buildPersonaPayload({
  required String userId,
  required String locale,
  required List<Map<String, String>> messages,
  String? persona,
}) {
  return {
    'userId': userId,
    'locale': locale,
    'messages': messages,
    'persona': persona ?? 'companion',
  };
}

// ── Callable typedef (injectable for tests) ────────────────────────────────

/// A callable that wraps FirebaseFunctions.httpsCallable.
/// Signature matches `HttpsCallable.call(data).then((r) => r.data)`.
typedef ChatCallable = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> payload,
);

/// Default production callable — uses us-central1 region.
ChatCallable _productionCallable() {
  final fn = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  ).httpsCallable('chatWithGemini');
  return (payload) async {
    final result = await fn.call(payload);
    final data = result.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  };
}

// ── AiChatService ──────────────────────────────────────────────────────────

class AiChatException implements Exception {
  final String code;
  final String message;

  const AiChatException({required this.code, required this.message});

  @override
  String toString() => message;
}

/// AI Chat Service — routes AI calls through the [chatWithGemini] Cloud
/// Function instead of calling the Gemini SDK directly.
///
/// The [chatCallable] parameter is injectable for unit testing; production
/// code defaults to [_productionCallable].
class AiChatService {
  final FirebaseFirestore _firestore;
  final ChatCallable _chatCallable;

  static const String _collection = 'ai_chats';
  static const String _messagesSubcollection = 'messages';

  AiChatService({
    FirebaseFirestore? firestore,
    ChatCallable? chatCallable,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _chatCallable = chatCallable ?? _productionCallable();

  /// Whether the AI backend is available (user is authenticated).
  bool get isAvailable => FirebaseAuth.instance.currentUser != null;

  // ── Firestore helpers ──────────────────────────────────────────────────

  DocumentReference _chatDoc(String userId) =>
      _firestore.collection(_collection).doc(userId);

  CollectionReference _messagesCollection(String userId) =>
      _chatDoc(userId).collection(_messagesSubcollection);

  // ── Chat lifecycle ─────────────────────────────────────────────────────

  /// Initialize or get existing chat for user.
  Future<AiChatDocument> getOrCreateChat(
    String userId, {
    MoodType? mood,
  }) async {
    try {
      final docRef = _chatDoc(userId);
      final doc = await docRef.get();

      if (doc.exists) {
        return AiChatDocument.fromFirestore(doc);
      }

      final newChat = AiChatDocument(
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentMood: mood?.name,
      );

      await docRef.set(newChat.toFirestore());
      return newChat;
    } catch (e, st) {
      debugPrint('AI getOrCreateChat failed: $e');
      debugPrintStack(stackTrace: st);
      throw const AiChatException(
        code: 'chat_init_failed',
        message: 'Could not start chat right now. Please try again.',
      );
    }
  }

  /// Load chat history for a user.
  Future<List<Message>> loadChatHistory(String userId, {int limit = 50}) async {
    final snapshot = await _messagesCollection(userId)
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Message.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Stream chat messages in real-time.
  Stream<List<Message>> streamMessages(String userId) {
    return _messagesCollection(userId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Message.fromFirestore(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  // ── Send message & get AI response ─────────────────────────────────────

  /// Send a message and get an AI response via the chatWithGemini Cloud
  /// Function.  Falls back to static responses on failure.
  ///
  /// [language] - 'ar', 'en', or 'fr' for response language.
  /// [persona] - AI persona id (e.g. 'companion', 'cbt_therapist'). Defaults
  ///   to 'companion'. Passed directly to the callable and stored in the
  ///   returned message metadata for audit purposes.
  /// [userContext] - Retained for API compat; Cloud Function computes its own
  ///   context from Firestore, so this field is ignored server-side but kept
  ///   to avoid a breaking change for callers.
  Future<Message> sendMessage({
    required String userId,
    required String content,
    required List<Message> conversationHistory,
    MoodType? currentMood,
    String language = 'ar',
    String persona = 'companion',
    Map<String, dynamic>? userContext,
  }) async {
    // 1. Save user message to Firestore
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    await _saveMessage(userId, userMessage);

    // 2. Inline crisis/escalation detection (static helpers — no API call)
    final isCrisis = GeminiService.detectCrisis(content);
    final shouldEscalate = GeminiService.shouldSuggestEscalation(content);

    // 3. Guard: require authenticated user
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('AI Chat: no authenticated user — skipping Cloud Function');
      const errorContent =
          'Please sign in to use the AI chat feature.';
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: errorContent,
        type: MessageType.bot,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        metadata: const MessageMetadata(model: 'fallback'),
      );
      await _saveMessage(userId, errorMessage);
      return errorMessage;
    }

    // 4. Build payload for chatWithGemini
    //    Include history + current message as last entry.
    final historyWithCurrent = [...conversationHistory, userMessage];
    final messagesPayload = prepareCloudPayload(historyWithCurrent);

    final payload = buildPersonaPayload(
      userId: userId,
      locale: language,
      messages: messagesPayload,
      persona: persona,
    );

    try {
      // 5. Call the Cloud Function
      final data = await _chatCallable(payload);

      final responseContent = data['content'] as String? ?? '';
      final responseModel = data['model'] as String? ?? 'gemini';
      final responseTokens = data['tokensUsed'] as int? ?? 0;
      final responseSources = (data['sources'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList();
      // Echo the persona back from the response (or fall back to what was sent).
      final responsePersona = data['persona'] as String? ?? persona;

      // 6. Create and save bot message
      final botMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: responseContent,
        type: MessageType.bot,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        metadata: MessageMetadata(
          tokensUsed: responseTokens,
          model: responseModel,
          moodDetected: currentMood?.name,
          escalationSuggested: shouldEscalate,
          crisisDetected: isCrisis,
          sources: responseSources,
          persona: responsePersona,
        ),
      );

      await _saveMessage(userId, botMessage);

      // 7. Update chat document metadata
      await _updateChatMetadata(
        userId: userId,
        lastMessage: responseContent,
        mood: currentMood,
      );

      return botMessage;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('Cloud Function Error [${e.code}]: ${e.message}');
      debugPrintStack(stackTrace: st);

      final kind = classifyFunctionError(e.code);

      if (kind == CloudFunctionErrorKind.dailyLimitReached) {
        // Surface a system message for daily limit rather than a generic error
        final limitMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: buildDailyLimitMessage(),
          type: MessageType.system,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
          metadata: const MessageMetadata(model: 'system'),
        );
        await _saveMessage(userId, limitMessage);
        return limitMessage;
      }

      // All other function errors → generic fallback
      return _saveFallback(userId, content);
    } catch (e, st) {
      debugPrint('AI Chat Error: $e');
      debugPrintStack(stackTrace: st);
      return _saveFallback(userId, content);
    }
  }

  /// Persist and return a static fallback bot message.
  Future<Message> _saveFallback(String userId, String userContent) async {
    final fallbackContent = ChatResponses.getBotResponse(userContent);
    final fallbackMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: fallbackContent,
      type: MessageType.bot,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      metadata: const MessageMetadata(model: 'fallback'),
    );
    await _saveMessage(userId, fallbackMessage);
    return fallbackMessage;
  }

  // ── Internal helpers ───────────────────────────────────────────────────

  Future<void> _saveMessage(String userId, Message message) async {
    await _messagesCollection(userId).doc(message.id).set(message.toFirestore());
  }

  Future<void> _updateChatMetadata({
    required String userId,
    required String lastMessage,
    MoodType? mood,
  }) async {
    await _chatDoc(userId).update({
      'last_message': lastMessage.length > 100
          ? '${lastMessage.substring(0, 100)}...'
          : lastMessage,
      'last_message_time': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'message_count': FieldValue.increment(2),
      if (mood != null) 'current_mood': mood.name,
    });
  }

  // ── Escalation ─────────────────────────────────────────────────────────

  Future<void> markAsEscalated({
    required String userId,
    required String escalatedTo,
    String? therapistId,
  }) async {
    await _chatDoc(userId).update({
      'escalated': true,
      'escalated_to': escalatedTo,
      'escalation_time': FieldValue.serverTimestamp(),
      if (therapistId != null) 'escalated_therapist_id': therapistId,
    });
  }

  Future<String> getConversationSummary(String userId) async {
    final messages = await loadChatHistory(userId, limit: 10);

    if (messages.isEmpty) return 'No previous conversation.';

    final summary = StringBuffer();
    summary.writeln('Recent conversation summary:');

    for (final message in messages) {
      final sender = message.type == MessageType.user ? 'User' : 'AI';
      final content = message.content.length > 100
          ? '${message.content.substring(0, 100)}...'
          : message.content;
      summary.writeln('$sender: $content');
    }

    return summary.toString();
  }

  // ── Clear / Delete ─────────────────────────────────────────────────────

  Future<void> clearChat(String userId) async {
    try {
      await _deleteMessagesInBatches(userId);

      await _chatDoc(userId).update({
        'message_count': 0,
        'last_message': null,
        'last_message_time': null,
        'escalated': false,
        'escalated_to': null,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      debugPrint('AI clearChat failed: $e');
      debugPrintStack(stackTrace: st);
      throw const AiChatException(
        code: 'chat_clear_failed',
        message: 'Failed to clear chat. Please try again.',
      );
    }
  }

  Future<void> deleteChat(String userId) async {
    try {
      await _deleteMessagesInBatches(userId);
      await _chatDoc(userId).delete();
    } catch (e, st) {
      debugPrint('AI deleteChat failed: $e');
      debugPrintStack(stackTrace: st);
      throw const AiChatException(
        code: 'chat_delete_failed',
        message: 'Failed to delete chat. Please try again.',
      );
    }
  }

  Future<void> _deleteMessagesInBatches(String userId) async {
    final messagesSnapshot = await _messagesCollection(userId).get();
    const chunkSize = 400;
    final docs = messagesSnapshot.docs;

    for (var i = 0; i < docs.length; i += chunkSize) {
      final batch = _firestore.batch();
      final end =
          (i + chunkSize < docs.length) ? i + chunkSize : docs.length;
      for (var j = i; j < end; j++) {
        batch.delete(docs[j].reference);
      }
      await batch.commit();
    }
  }
}

/// AI Chat document model
class AiChatDocument {
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int messageCount;
  final String? currentMood;
  final bool escalated;
  final String? escalatedTo;
  final DateTime? escalationTime;

  AiChatDocument({
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageTime,
    this.messageCount = 0,
    this.currentMood,
    this.escalated = false,
    this.escalatedTo,
    this.escalationTime,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastMessageTime != null)
        'last_message_time': Timestamp.fromDate(lastMessageTime!),
      'message_count': messageCount,
      if (currentMood != null) 'current_mood': currentMood,
      'escalated': escalated,
      if (escalatedTo != null) 'escalated_to': escalatedTo,
      if (escalationTime != null)
        'escalation_time': Timestamp.fromDate(escalationTime!),
    };
  }

  factory AiChatDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AiChatDocument(
      userId: data['user_id'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      lastMessage: data['last_message'] as String?,
      lastMessageTime: data['last_message_time'] != null
          ? (data['last_message_time'] as Timestamp).toDate()
          : null,
      messageCount: data['message_count'] as int? ?? 0,
      currentMood: data['current_mood'] as String?,
      escalated: data['escalated'] as bool? ?? false,
      escalatedTo: data['escalated_to'] as String?,
      escalationTime: data['escalation_time'] != null
          ? (data['escalation_time'] as Timestamp).toDate()
          : null,
    );
  }
}
