import 'package:sanad_app/core/l10n/coaching_wording.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../mood/models/mood_enums.dart';
import '../../../core/l10n/language_provider.dart';

enum MessageType { user, bot, system, handoff }

enum MessageStatus { sending, sent, delivered, read, failed }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isQuickReply;
  final MessageStatus status;
  final MessageMetadata? metadata;

  const Message({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isQuickReply = false,
    this.status = MessageStatus.sent,
    this.metadata,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isQuickReply,
    MessageStatus? status,
    MessageMetadata? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isQuickReply: isQuickReply ?? this.isQuickReply,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'is_quick_reply': isQuickReply,
      'status': status.name,
      if (metadata != null) 'metadata': metadata!.toFirestore(),
    };
  }

  /// Create from Firestore document
  factory Message.fromFirestore(Map<String, dynamic> data) {
    return Message(
      id: data['id'] as String,
      content: data['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.bot,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isQuickReply: data['is_quick_reply'] as bool? ?? false,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      metadata: data['metadata'] != null
          ? MessageMetadata.fromFirestore(
              data['metadata'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Get OpenAI role from message type
  String get openAIRole {
    switch (type) {
      case MessageType.user:
        return 'user';
      case MessageType.bot:
        return 'assistant';
      case MessageType.system:
        return 'system';
      case MessageType.handoff:
        return 'system';
    }
  }

  /// Get Gemini role from message type
  String get geminiRole {
    switch (type) {
      case MessageType.user:
        return 'user';
      case MessageType.bot:
        return 'model'; // Gemini uses 'model' instead of 'assistant'
      case MessageType.system:
        return 'user'; // Gemini doesn't have system role, map to user or handle separately
      case MessageType.handoff:
        return 'user';
    }
  }
}

/// Metadata for AI-generated messages
class MessageMetadata {
  final int? tokensUsed;
  final String? model;
  final String? moodDetected;
  final bool? escalationSuggested;
  final bool? crisisDetected;
  final String? crisisSeverity;
  final List<String>? crisisKeywordsMatched;
  final List<String>? resourcesProvided;

  /// Content document IDs returned by the chatWithGemini Cloud Function.
  final List<String>? sources;

  /// AI persona used to generate this message (e.g. 'cbt_therapist').
  /// Persisted for audit / analytics.
  final String? persona;

  const MessageMetadata({
    this.tokensUsed,
    this.model,
    this.moodDetected,
    this.escalationSuggested,
    this.crisisDetected,
    this.crisisSeverity,
    this.crisisKeywordsMatched,
    this.resourcesProvided,
    this.sources,
    this.persona,
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (tokensUsed != null) 'tokens_used': tokensUsed,
      if (model != null) 'model': model,
      if (moodDetected != null) 'mood_detected': moodDetected,
      if (escalationSuggested != null)
        'escalation_suggested': escalationSuggested,
      if (crisisDetected != null) 'crisis_detected': crisisDetected,
      if (crisisSeverity != null) 'crisis_severity': crisisSeverity,
      if (crisisKeywordsMatched != null)
        'crisis_keywords_matched': crisisKeywordsMatched,
      if (resourcesProvided != null) 'resources_provided': resourcesProvided,
      if (sources != null) 'sources': sources,
      if (persona != null) 'persona': persona,
    };
  }

  factory MessageMetadata.fromFirestore(Map<String, dynamic> data) {
    return MessageMetadata(
      tokensUsed: data['tokens_used'] as int?,
      model: data['model'] as String?,
      moodDetected: data['mood_detected'] as String?,
      escalationSuggested: data['escalation_suggested'] as bool?,
      crisisDetected: data['crisis_detected'] as bool?,
      crisisSeverity: data['crisis_severity'] as String?,
      crisisKeywordsMatched: (data['crisis_keywords_matched'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      resourcesProvided: (data['resources_provided'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sources: (data['sources'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      persona: data['persona'] as String?,
    );
  }
}

/// Chat state for the AI chat
class ChatState {
  final List<Message> messages;
  final bool isTyping;
  final MoodType? currentMood;
  final List<String> quickReplies;
  final bool isLoading;
  final String? error;
  final bool isEscalated;
  final String? escalatedTo; // 'admin' or 'therapist'
  final bool isCrisisMode;
  final int guestMessageCount;
  final bool guestLimitReached;

  /// Maximum number of messages a guest can send before being prompted to sign up.
  /// 0 = guests must create an account before sending any AI message.
  static const int guestMessageLimit = 0;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.currentMood,
    this.quickReplies = const [],
    this.isLoading = false,
    this.error,
    this.isEscalated = false,
    this.escalatedTo,
    this.isCrisisMode = false,
    this.guestMessageCount = 0,
    this.guestLimitReached = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isTyping,
    MoodType? currentMood,
    List<String>? quickReplies,
    bool? isLoading,
    String? error,
    bool? isEscalated,
    String? escalatedTo,
    bool? isCrisisMode,
    int? guestMessageCount,
    bool? guestLimitReached,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      currentMood: currentMood ?? this.currentMood,
      quickReplies: quickReplies ?? this.quickReplies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isEscalated: isEscalated ?? this.isEscalated,
      escalatedTo: escalatedTo ?? this.escalatedTo,
      isCrisisMode: isCrisisMode ?? this.isCrisisMode,
      guestMessageCount: guestMessageCount ?? this.guestMessageCount,
      guestLimitReached: guestLimitReached ?? this.guestLimitReached,
    );
  }
}

// Mood-based responses and quick replies (kept for quick replies functionality)
class ChatResponses {
  static const Map<MoodType?, String> _welcomeAr = {
    MoodType.happy:
        'يسعدني سماع ذلك! جميل أنك تشعر بالرضا اليوم. هل تحب أن تشاركني ما يُسعدك؟',
    MoodType.calm:
        'جميل أنك تشعر بالهدوء والسكينة. كيف أساعدك لتحافظ على هذه الحالة الإيجابية؟',
    MoodType.anxious:
        'أفهم أن القلق قد يكون مرهقاً. خذ نفساً عميقاً، أنا هنا معك. ما الذي يشغل بالك؟',
    MoodType.sad:
        'يؤسفني أنك تشعر بالحزن اليوم، ولا بأس أن تشعر هكذا. هل تحب أن تحدثني عمّا يضايقك؟',
    MoodType.tired:
        'الشعور بالتعب أمر طبيعي، والراحة مهمة لرفاهيتك. كيف يمكنني دعمك اليوم؟',
    MoodType.angry:
        'يبدو أنك تشعر بالإحباط أو الغضب، والتعامل مع هذه المشاعر مهم. ما الذي أثار هذا الشعور؟',
    null:
        'مرحباً! أنا سند، رفيقك للرفاهية. كيف تشعر اليوم؟ شاركني بكل ما يدور في ذهنك.',
  };

  static const Map<MoodType?, List<String>> _quickRepliesAr = {
    MoodType.happy: ['أشارك سعادتي', 'أضع هدفاً إيجابياً', 'أمارس الامتنان'],
    MoodType.calm: ['أكمل التأمل', 'أدوّن أفكاري', 'أخطط ليومي بهدوء'],
    MoodType.anxious: ['أجرّب تمرين تنفس', 'أتحدث عن مخاوفي', 'أحتاج طرقاً للتهدئة'],
    MoodType.sad: ['أحتاج أن أفضفض', 'ساعدني لأشعر بتحسن', 'أريد التحدث مع كوتش'],
    MoodType.tired: ['نصائح للاسترخاء', 'نوم أفضل الليلة', 'طاقة سريعة'],
    MoodType.angry: ['طرق للهدوء', 'أحدد سبب الغضب', 'مساحة للتنفيس'],
    null: ['كيف يمكنك مساعدتي؟', 'أحتاج من يسمعني', 'اعرض لي تمارين'],
  };

  /// Arabic users get Arabic; English and French keep the English copy.
  static String getWelcomeMessage(
    MoodType? mood, {
    AppLanguage language = AppLanguage.english,
  }) {
    if (language == AppLanguage.arabic) return _welcomeAr[mood]!;
    switch (mood) {
      case MoodType.happy:
        return "That's wonderful to hear! I'm glad you're feeling good today. Would you like to share what's making you happy?";
      case MoodType.calm:
        return "It's great that you're feeling calm and peaceful. How can I help you maintain this positive state?";
      case MoodType.anxious:
        return "I understand that anxiety can be overwhelming. Take a deep breath. I'm here to help you through this. What's on your mind?";
      case MoodType.sad:
        return "I'm sorry you're feeling sad today. Remember, it's okay to feel this way. Would you like to talk about what's bothering you?";
      case MoodType.tired:
        return "Feeling tired is completely valid. Rest is important for your wellbeing. How can I support you today?";
      case MoodType.angry:
        return "It sounds like you're feeling frustrated or angry. Processing these intense emotions is important. What's triggering this feeling?";
      default:
        return "Hello! I'm Sanad, your wellbeing companion. How are you feeling today? Feel free to share anything on your mind.";
    }
  }

  static List<String> getQuickReplies(
    MoodType? mood, {
    AppLanguage language = AppLanguage.english,
  }) {
    if (language == AppLanguage.arabic) return _quickRepliesAr[mood]!;
    switch (mood) {
      case MoodType.happy:
        return [
          "Share my happiness",
          "Set a positive goal",
          "Practice gratitude",
        ];
      case MoodType.calm:
        return [
          "Continue meditation",
          "Journal my thoughts",
          "Plan my day mindfully",
        ];
      case MoodType.anxious:
        return [
          "Try breathing exercise",
          "Talk about my worries",
          "Need grounding techniques",
        ];
      case MoodType.sad:
        return ["I need to vent", "Help me feel better", "Talk to a coach"];
      case MoodType.tired:
        return [
          "Relaxation tips",
          "Sleep better tonight",
          "Quick energy boost",
        ];
      case MoodType.angry:
        return ["Ways to calm down", "Identify the trigger", "Venting space"];
      default:
        return [
          "How can you help me?",
          "I need someone to talk to",
          "Show me exercises",
        ];
    }
  }

  // Kept for fallback if API fails
  static String getBotResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('anxiety') ||
        lowerMessage.contains('anxious') ||
        lowerMessage.contains('worried')) {
      return "Anxiety can feel overwhelming, but you're not alone. Let's try a simple technique: Take a slow, deep breath in for 4 seconds, hold for 4 seconds, and exhale for 6 seconds. Would you like me to guide you through more exercises?";
    }

    if (lowerMessage.contains('sad') ||
        lowerMessage.contains('depressed') ||
        lowerMessage.contains('unhappy')) {
      return "I hear you, and your feelings are valid. Sometimes sadness is our mind's way of processing difficult experiences. Would you like to talk more about what's been happening, or would you prefer some gentle activities to help lift your mood?";
    }

    if (lowerMessage.contains('therapist') ||
        lowerMessage.contains('professional') ||
        lowerMessage.contains('help')) {
      return CoachingWording.any("I think speaking with a professional could really help. Our licensed therapists are available to support you. Would you like me to help you book a session?");
    }

    if (lowerMessage.contains('breathing') ||
        lowerMessage.contains('exercise') ||
        lowerMessage.contains('calm')) {
      return "Great choice! Breathing exercises are powerful tools. Let's start with the 4-7-8 technique:\n\n1. Breathe in quietly through your nose for 4 seconds\n2. Hold your breath for 7 seconds\n3. Exhale completely through your mouth for 8 seconds\n\nRepeat this 3-4 times. How do you feel?";
    }

    if (lowerMessage.contains('sleep') ||
        lowerMessage.contains('tired') ||
        lowerMessage.contains('rest')) {
      return "Quality sleep is essential for mental health. Here are some tips:\n\n- Try to sleep at the same time each night\n- Avoid screens 1 hour before bed\n- Keep your room cool and dark\n- Try a relaxing bedtime routine\n\nWould you like a guided sleep meditation?";
    }

    return "Thank you for sharing that with me. I'm here to listen and support you. Is there anything specific you'd like to explore or talk about?";
  }
}
