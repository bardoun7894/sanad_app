import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/openai_service.dart';

/// AI Assistant Service for Admin/Therapist Panel
/// Provides AI-powered assistance for clinical documentation and patient management
class AdminAiService {
  final FirebaseFirestore _firestore;
  final OpenAIService? _openAI;

  static const String _collection = 'admin_ai_chats';
  static const String _messagesSubcollection = 'messages';

  AdminAiService({
    String? openAIApiKey,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _openAI = openAIApiKey != null && openAIApiKey.isNotEmpty
            ? OpenAIService(apiKey: openAIApiKey)
            : null;

  /// Check if AI service is available
  bool get isAvailable => _openAI != null;

  /// Get reference to admin's chat document
  DocumentReference _chatDoc(String adminId) =>
      _firestore.collection(_collection).doc(adminId);

  /// Get reference to messages subcollection
  CollectionReference _messagesCollection(String adminId) =>
      _chatDoc(adminId).collection(_messagesSubcollection);

  /// Load chat history for admin
  Future<List<Map<String, String>>> loadChatHistory(String adminId, {int limit = 50}) async {
    try {
      final snapshot = await _messagesCollection(adminId)
          .orderBy('timestamp', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'role': data['role'] as String,
          'content': data['content'] as String,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading admin AI chat history: $e');
      return [];
    }
  }

  /// Send message and get AI response
  Future<String> sendMessage({
    required String adminId,
    required String content,
    required List<Map<String, String>> conversationHistory,
    String? patientContext,
  }) async {
    // Save user message
    await _saveMessage(adminId, 'user', content);

    String responseContent;

    if (_openAI != null) {
      try {
        // Build context messages for OpenAI
        final messages = _buildContextMessages(
          conversationHistory,
          content,
          patientContext,
        );

        // Add clinical context as a system-like user message at the start
        final clinicalContext = ChatMessage.user(
          '[Clinical Assistant Context: ${_getClinicalSystemPrompt()}]\n\nUser query: $content',
        );

        final messagesWithContext = [clinicalContext, ...messages.sublist(0, messages.length - 1)];
        messagesWithContext.add(messages.last);

        final response = await _openAI.sendMessage(
          messages: messagesWithContext,
          userMood: 'clinical', // Use clinical context
        );

        responseContent = response.content;
      } catch (e) {
        debugPrint('Admin AI Error: $e');
        responseContent = _getFallbackResponse(content);
      }
    } else {
      // No API key configured - use intelligent fallback
      responseContent = _getFallbackResponse(content);
    }

    // Save AI response
    await _saveMessage(adminId, 'assistant', responseContent);

    // Update chat metadata
    await _updateChatMetadata(adminId, responseContent);

    return responseContent;
  }

  /// Save a message to Firestore
  Future<void> _saveMessage(String adminId, String role, String content) async {
    await _messagesCollection(adminId).add({
      'role': role,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Update chat document metadata
  Future<void> _updateChatMetadata(String adminId, String lastMessage) async {
    await _chatDoc(adminId).set({
      'admin_id': adminId,
      'last_message': lastMessage.length > 100
          ? '${lastMessage.substring(0, 100)}...'
          : lastMessage,
      'last_message_time': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Build context messages for OpenAI
  List<ChatMessage> _buildContextMessages(
    List<Map<String, String>> history,
    String currentMessage,
    String? patientContext,
  ) {
    final messages = <ChatMessage>[];

    // Add recent history (limit to avoid token overflow)
    final recentHistory = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    for (final msg in recentHistory) {
      messages.add(ChatMessage(
        role: msg['role'] == 'user' ? 'user' : 'assistant',
        content: msg['content'] ?? '',
        timestamp: DateTime.now(),
      ));
    }

    // Add current message with patient context if available
    final messageContent = patientContext != null
        ? '$currentMessage\n\n[Patient Context: $patientContext]'
        : currentMessage;

    messages.add(ChatMessage.user(messageContent));

    return messages;
  }

  /// Get system prompt for clinical AI assistant
  String _getClinicalSystemPrompt() {
    return '''You are Sanad AI Assistant, a clinical support tool for mental health professionals.
Your role is to assist with:
- Drafting clinical notes (SOAP, DAP, progress notes)
- Suggesting treatment approaches based on evidence-based practices
- Providing reminders about crisis protocols when relevant
- Helping organize patient information

Important guidelines:
- Always maintain professional, clinical language
- Never provide diagnosis or treatment recommendations as final decisions
- Remind clinicians that all AI suggestions should be reviewed
- Flag any crisis indicators immediately
- Respect patient confidentiality in all responses''';
  }

  /// Get intelligent fallback response when AI is unavailable
  String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // SOAP note requests
    if (lowerMessage.contains('soap') || lowerMessage.contains('note')) {
      return '''I can help you structure a SOAP note. Here's a template:

**S (Subjective):** Patient's reported symptoms and concerns
**O (Objective):** Observable findings, vital signs, mental status exam
**A (Assessment):** Clinical impression, diagnosis codes
**P (Plan):** Treatment plan, interventions, follow-up

Would you like me to help with a specific section?

_Note: Full AI assistance requires OpenAI API configuration._''';
    }

    // Crisis protocol requests
    if (lowerMessage.contains('crisis') || lowerMessage.contains('risk') ||
        lowerMessage.contains('suicide') || lowerMessage.contains('emergency')) {
      return '''**Crisis Protocol Reminder:**

1. **Assess immediate safety** - Is the patient safe right now?
2. **Determine risk level** - Ideation, plan, means, intent
3. **Create safety plan** - Coping strategies, support contacts
4. **Document thoroughly** - Risk assessment, interventions
5. **Follow-up** - Schedule next contact, involve support system

For immediate emergencies, contact local crisis services.

_Note: Full AI assistance requires OpenAI API configuration._''';
    }

    // Treatment suggestions
    if (lowerMessage.contains('treatment') || lowerMessage.contains('therapy') ||
        lowerMessage.contains('intervention')) {
      return '''For evidence-based treatment planning, consider:

- **CBT** - Cognitive restructuring, behavioral activation
- **DBT** - Distress tolerance, emotion regulation
- **ACT** - Values clarification, acceptance strategies
- **Mindfulness** - Present-moment awareness exercises

Would you like specific resources for any of these approaches?

_Note: Full AI assistance requires OpenAI API configuration._''';
    }

    // Default helpful response
    return '''I'm here to assist with clinical documentation and patient management. I can help with:

• **Draft Notes** - SOAP, DAP, progress notes
• **Crisis Protocol** - Safety assessments and protocols
• **Treatment Planning** - Evidence-based approaches
• **Patient Management** - Organization and follow-ups

How can I help you today?

_Note: For full AI capabilities, please configure your OpenAI API key in settings._''';
  }

  /// Clear chat history
  Future<void> clearChat(String adminId) async {
    final messagesSnapshot = await _messagesCollection(adminId).get();

    final batch = _firestore.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await _chatDoc(adminId).delete();
  }
}
