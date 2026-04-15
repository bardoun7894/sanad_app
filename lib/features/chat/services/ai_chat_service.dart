import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/app_config.dart';
import '../../../core/services/gemini_service.dart';
import '../models/message.dart';
import '../../mood/models/mood_enums.dart';

class AiChatException implements Exception {
  final String code;
  final String message;

  const AiChatException({required this.code, required this.message});

  @override
  String toString() => message;
}

/// AI Chat Service - Calls Gemini directly with Firestore persistence.
///
/// Uses [GeminiService] with the API key from [AppConfig] (Firestore > dart-define > .env).
class AiChatService {
  final FirebaseFirestore _firestore;

  static const String _collection = 'ai_chats';
  static const String _messagesSubcollection = 'messages';
  static const int _maxContextMessages = 20;

  /// Cached GeminiService instance; recreated if key changes.
  GeminiService? _gemini;
  String? _lastKey;

  AiChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get or create a GeminiService using the current API key.
  /// Returns null if no key is configured.
  GeminiService? _getGemini() {
    final key = AppConfig.geminiApiKey;
    if (key.isEmpty) return null;
    if (_gemini == null || _lastKey != key) {
      _gemini = GeminiService(apiKey: key);
      _lastKey = key;
    }
    return _gemini;
  }

  /// Whether the AI backend is available (key configured).
  bool get isAvailable => AppConfig.isGeminiConfigured;

  // ── Firestore helpers ──────────────────────────────────────────────────

  DocumentReference _chatDoc(String userId) =>
      _firestore.collection(_collection).doc(userId);

  CollectionReference _messagesCollection(String userId) =>
      _chatDoc(userId).collection(_messagesSubcollection);

  // ── Chat lifecycle ─────────────────────────────────────────────────────

  /// Initialize or get existing chat for user
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

  /// Load chat history for a user
  Future<List<Message>> loadChatHistory(String userId, {int limit = 50}) async {
    final snapshot = await _messagesCollection(
      userId,
    ).orderBy('timestamp', descending: false).limit(limit).get();

    return snapshot.docs
        .map((doc) => Message.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Stream chat messages in real-time
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

  /// Send a message and get AI response.
  /// Calls Gemini directly; falls back to static responses on failure.
  ///
  /// [language] - 'ar', 'en', or 'fr' for response language.
  /// [userContext] - Optional user-specific data for RAG (tier, mood history, etc.).
  Future<Message> sendMessage({
    required String userId,
    required String content,
    required List<Message> conversationHistory,
    MoodType? currentMood,
    String language = 'ar',
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

    // 2. Prepare context
    final contextMessages = _prepareContext(conversationHistory, userMessage);

    // 3. Crisis / escalation flags (static, no API needed)
    final isCrisis = GeminiService.detectCrisis(content);
    final shouldEscalate = GeminiService.shouldSuggestEscalation(content);

    try {
      // 4. Call Gemini directly
      final gemini = _getGemini();
      if (gemini == null) {
        throw const AiChatException(
          code: 'no_api_key',
          message: 'Gemini API key not configured',
        );
      }

      final response = await gemini.sendMessage(
        messages: contextMessages,
        userMood: currentMood?.name,
        language: language,
        userContext: userContext,
      );

      // 5. Create and save bot message
      final botMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response.content,
        type: MessageType.bot,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        metadata: MessageMetadata(
          tokensUsed: response.tokensUsed,
          model: response.model,
          moodDetected: currentMood?.name,
          escalationSuggested: shouldEscalate,
          crisisDetected: isCrisis,
        ),
      );

      await _saveMessage(userId, botMessage);

      // 6. Update chat document metadata
      await _updateChatMetadata(
        userId: userId,
        lastMessage: response.content,
        mood: currentMood,
      );

      return botMessage;
    } catch (e, st) {
      debugPrint('AI Chat Error: $e');
      debugPrintStack(stackTrace: st);

      // Fallback to static response if Gemini fails
      final fallbackContent = ChatResponses.getBotResponse(content);
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
  }

  // ── Internal helpers ───────────────────────────────────────────────────

  Future<void> _saveMessage(String userId, Message message) async {
    await _messagesCollection(
      userId,
    ).doc(message.id).set(message.toFirestore());
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

  List<GeminiChatMessage> _prepareContext(
    List<Message> history,
    Message currentMessage,
  ) {
    final recentMessages = history.length > _maxContextMessages
        ? history.sublist(history.length - _maxContextMessages)
        : history;

    final context = recentMessages
        .map((m) => GeminiChatMessage(role: m.geminiRole, content: m.content))
        .toList();

    context.add(
      GeminiChatMessage(role: 'user', content: currentMessage.content),
    );

    return context;
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
      final end = (i + chunkSize < docs.length) ? i + chunkSize : docs.length;
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
