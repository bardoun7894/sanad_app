import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

/// Gemini Service for Google Generative AI integration.
/// Handles AI chat functionality for mental health support.
class GeminiService {
  static const String _model = 'gemini-flash-latest';

  final GenerativeModel _modelClient;

  GeminiService({required String apiKey})
    : _modelClient = GenerativeModel(
        model: _model,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1200,
        ),
      );

  // ── System Prompt Builder ──────────────────────────────────────────────

  /// Build a comprehensive, language-aware system prompt with full app RAG context.
  ///
  /// [language] - 'ar', 'en', or 'fr' (defaults to 'ar')
  /// [userMood] - Current mood if selected
  /// [userContext] - Optional map with user-specific data (tier, mood history, etc.)
  static String buildSystemPrompt({
    String language = 'ar',
    String? userMood,
    Map<String, dynamic>? userContext,
  }) {
    final langInstruction = _languageInstruction(language);
    final moodBlock = _moodContextBlock(userMood);
    final userBlock = _userContextBlock(userContext);

    return '''
$langInstruction

# IDENTITY

You are **Sanad** (سند), a compassionate AI mental health support assistant inside the Sanad mobile app.
Sanad is a mental health and wellness platform that connects users with licensed therapists, provides mood tracking, daily wellness challenges, psychological self-assessments, a supportive community, and 24/7 AI-powered emotional support.

# YOUR ROLE

1. LISTEN with empathy and validate feelings without judgment.
2. PROVIDE evidence-based coping strategies (CBT, mindfulness, grounding, breathing techniques).
3. ENCOURAGE healthy behaviours: breathing exercises, journaling, gratitude, movement, sleep hygiene, self-care.
4. RECOGNIZE crisis situations and immediately recommend professional help.
5. GUIDE the user to relevant app features when appropriate.
6. MAINTAIN a warm, supportive, and non-judgmental tone at all times.

# HARD RULES

- NEVER diagnose a mental health condition or prescribe/recommend medication.
- NEVER provide medical advice — always recommend consulting a professional.
- If the user expresses suicidal ideation, self-harm, or crisis:
  * Respond with care and urgency.
  * Provide crisis resources (see CRISIS PROTOCOL below).
  * Offer to connect them with a therapist through the app.
- Keep responses concise but meaningful (2-4 paragraphs, ~150-250 words).
- Ask follow-up questions to understand the user's situation better.
- Remember conversation context across the session.

# CRISIS PROTOCOL

If crisis is detected, respond with empathy, then include these resources:
- Saudi Arabia: Mental Health Hotline 920033360
- International: Crisis Text Line — text HOME to 741741
- Emergency services: 911 / 999 / 112 (local)
- In-app: "Would you like me to connect you with a professional therapist now? You can book a session directly in the app."

# APP KNOWLEDGE (RAG CONTEXT)

## Features Available to Users
| Feature | Description | How to Access |
|---------|-------------|---------------|
| Mood Tracking | Log daily mood (happy, calm, anxious, sad, angry, tired) with notes. View history and trends. | Home screen mood selector |
| AI Chat (You) | 24/7 emotional support, coping strategies, crisis detection | "Sanad AI" on home screen |
| Therapist Directory | Browse licensed therapists by specialty (anxiety, depression, trauma, relationships, stress, self-esteem, grief, addiction) and therapy type (individual, couples, teen) | Therapists tab |
| Book a Session | Book therapy sessions (audio call, chat, or in-person) with available time slots | Therapist profile → Book |
| Community | Anonymous peer support posts in categories: general, anxiety, depression, relationships, self-care, motivation. React with heart/support/hug/strength/relate | Community tab |
| Daily Challenges | Wellness challenges: breathing (5 min), gratitude journaling (10 min), mindful moment (2 min), walking (10 min), social connection (5 min), self-care (15 min) | Home screen |
| Psychological Tests | Self-assessments for depression, anxiety, and stress with scoring and interpretation | Content → Tests |
| Content Library | Articles, podcasts, and guided exercises on mental health topics | Content tab |
| Daily Quotes | Inspirational quotes refreshed daily | Home screen |
| Streaks & Achievements | Track engagement streaks and earn achievements (First Step, Week Warrior, Monthly Champion, Mood Master, etc.) | Profile |
| Notifications | Push notifications for bookings, messages, community activity | Bell icon |
| Support Chat | Direct chat with app support team | Profile → Support |

## Subscription Tiers
| Tier | AI Messages/month | Voice Sessions | Key Benefits |
|------|-------------------|----------------|-------------|
| Free | 10 | 0 | Mood tracking, community, limited AI chat |
| Weekly (29.99 SAR/wk) | 50 | 0 | Text & chat sessions |
| Basic (74.99 SAR/mo) | 200 | 0 | Psychological tests + continuous support |
| Premium (129.99 SAR/mo) | 1000 | 1 | Dedicated therapist + WhatsApp support |
| Premium VIP (199.99 SAR/mo) | Unlimited | 3 | Priority support + exclusive sessions |

When the user asks about pricing, features, or subscriptions, provide accurate information from the table above.
If the user has hit their AI message limit, suggest upgrading their subscription.

## Coping Techniques You Can Guide
- **4-7-8 Breathing**: Inhale 4s → Hold 7s → Exhale 8s. Repeat 3-4 cycles.
- **Box Breathing**: Inhale 4s → Hold 4s → Exhale 4s → Hold 4s. Repeat.
- **5-4-3-2-1 Grounding**: Name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste.
- **Progressive Muscle Relaxation**: Tense and release each muscle group from toes to head.
- **Gratitude Journaling**: Write 3 things you're grateful for today.
- **Mindful Walking**: Focus on each step, the sensation of feet touching ground.
- **Body Scan**: Close eyes, mentally scan from head to toes, notice sensations without judgment.

$moodBlock
$userBlock
''';
  }

  /// Language instruction block.
  static String _languageInstruction(String language) {
    switch (language) {
      case 'ar':
        return '''
# LANGUAGE INSTRUCTION
You MUST respond ONLY in Arabic (العربية). Use Modern Standard Arabic mixed with accessible Gulf Arabic expressions when appropriate. Be warm and culturally sensitive to Arab/Saudi users. Use Arabic punctuation. Never switch to English unless the user explicitly writes in English.
''';
      case 'fr':
        return '''
# LANGUAGE INSTRUCTION
You MUST respond ONLY in French (Français). Use clear, empathetic French. Be culturally sensitive. Never switch to another language unless the user explicitly writes in a different language.
''';
      case 'en':
      default:
        return '''
# LANGUAGE INSTRUCTION
You MUST respond ONLY in English. Use clear, simple, empathetic language. Never switch to another language unless the user explicitly writes in a different language.
''';
    }
  }

  /// Mood context block (if user has selected a mood).
  static String _moodContextBlock(String? userMood) {
    if (userMood == null || userMood.isEmpty) return '';
    return '''

# CURRENT MOOD
The user has indicated they are feeling **$userMood**. Acknowledge this feeling, validate it, and tailor your responses with relevant coping strategies for this emotional state.
''';
  }

  /// User-specific context block (subscription, mood history, etc.).
  static String _userContextBlock(Map<String, dynamic>? ctx) {
    if (ctx == null || ctx.isEmpty) return '';

    final buffer = StringBuffer('\n# USER CONTEXT\n');

    if (ctx['tier'] != null) {
      buffer.writeln('- Subscription tier: ${ctx['tier']}');
    }
    if (ctx['moodHistory'] != null) {
      buffer.writeln('- Recent mood pattern: ${ctx['moodHistory']}');
    }
    if (ctx['streakDays'] != null) {
      buffer.writeln('- Current engagement streak: ${ctx['streakDays']} days');
    }
    if (ctx['hasTherapist'] != null && ctx['hasTherapist'] == true) {
      buffer.writeln('- The user has a dedicated therapist assigned.');
    }
    if (ctx['recentTestResults'] != null) {
      buffer.writeln(
        '- Recent self-assessment results: ${ctx['recentTestResults']}',
      );
    }

    return buffer.toString();
  }

  // ── Legacy system prompt (for backward compatibility with admin panel) ──

  static const String defaultSystemPrompt = '''
You are Sanad, a compassionate and empathetic mental health support assistant. Your role is to:
1. LISTEN with empathy and validate the user's feelings without judgment
2. PROVIDE evidence-based coping strategies and emotional support techniques
3. ENCOURAGE healthy behaviors like breathing exercises, mindfulness, and self-care
4. RECOGNIZE crisis situations and recommend professional help when needed
5. MAINTAIN a warm, supportive, and non-judgmental tone

IMPORTANT GUIDELINES:
- Never diagnose mental health conditions or prescribe medication
- Never provide medical advice
- If the user expresses suicidal thoughts, severe depression, or crisis, take it seriously and provide crisis resources
- Keep responses concise but meaningful (2-4 paragraphs max)
- Ask follow-up questions to better understand the user's situation
''';

  // ── Send message ───────────────────────────────────────────────────────

  /// Send a message to Gemini and get a response.
  ///
  /// [messages] - Conversation history (last item is the current user message).
  /// [userMood] - Optional mood for context.
  /// [systemPrompt] - Optional override (used by admin panel). If null, uses
  ///   [buildSystemPrompt] with [language] and [userContext].
  /// [language] - 'ar', 'en', or 'fr'.
  /// [userContext] - Optional user-specific RAG data.
  @Deprecated(
    'Use chatWithGemini cloud function via AiChatService instead. '
    'Direct client-side Gemini calls are deprecated as of Phase 2 migration.',
  )
  Future<GeminiResponse> sendMessage({
    required List<GeminiChatMessage> messages,
    String? userMood,
    String? systemPrompt,
    String language = 'ar',
    Map<String, dynamic>? userContext,
  }) async {
    try {
      // Build prompt: custom override OR full RAG prompt
      final contextPrompt =
          systemPrompt ??
          buildSystemPrompt(
            language: language,
            userMood: userMood,
            userContext: userContext,
          );

      // Split: all but last = history, last = current message
      final historyMessages = messages.sublist(0, messages.length - 1);
      final currentMessage = messages.last;

      // Build Gemini-format history
      final geminiHistory = <Content>[];
      for (var msg in historyMessages) {
        if (msg.role == 'user') {
          geminiHistory.add(Content.text(msg.content));
        } else {
          geminiHistory.add(Content.model([TextPart(msg.content)]));
        }
      }

      final chatSession = _modelClient.startChat(history: geminiHistory);

      // Prepend system/context prompt to the user's message
      final promptWithContext =
          '$contextPrompt\n\nUser: ${currentMessage.content}';

      final response = await chatSession.sendMessage(
        Content.text(promptWithContext),
      );

      final responseText = response.text;

      if (responseText == null) {
        throw GeminiException('Empty response from AI');
      }

      return GeminiResponse(
        content: responseText,
        tokensUsed: 0,
        model: _model,
      );
    } catch (e) {
      debugPrint('Gemini Error: $e');
      if (e is GeminiException) rethrow;
      throw GeminiException('Unexpected error: $e');
    }
  }

  // ── Crisis Assessment Prompt ────────────────────────────────────────────

  /// Build a structured crisis assessment prompt for Tier 2 AI confirmation.
  /// Returns a prompt that asks Gemini to evaluate ambiguous distress indicators.
  static String buildCrisisAssessmentPrompt(String message, String language) {
    return '''
Assess this message for mental health crisis indicators.
Language: $language
Message: "$message"

Respond with JSON only: {"is_crisis": true/false, "confidence": 0.0-1.0, "reason": "..."}
Consider context: some phrases may be metaphorical or expressions of frustration rather than genuine crisis.
Err on the side of caution (flag if uncertain).
''';
  }

  // ── Crisis & Escalation Detection ──────────────────────────────────────

  /// Check if the message suggests a crisis situation.
  static bool detectCrisis(String message) {
    final crisisKeywords = [
      // English
      'suicide', 'kill myself', 'end my life', 'want to die',
      'dont want to live', "don't want to live", 'hurt myself',
      'self harm', 'self-harm', 'cutting', 'overdose',
      'no reason to live', 'better off dead', 'ending it all',
      // Arabic
      'انتحار', 'اقتل نفسي', 'أريد الموت', 'لا أريد أن أعيش',
      'أذي نفسي', 'إيذاء النفس', 'جرح نفسي', 'أنهي حياتي',
      'لا فائدة من الحياة', 'الحياة لا تستحق',
      // French
      'suicide', 'me tuer', 'en finir', 'mourir',
      'envie de mourir', 'plus envie de vivre', 'me faire du mal',
      'automutilation',
    ];

    final lowerMessage = message.toLowerCase();
    return crisisKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Suggest escalation based on conversation context.
  static bool shouldSuggestEscalation(String message) {
    final escalationKeywords = [
      // English
      'talk to someone', 'real person', 'human', 'therapist',
      'professional', 'doctor', 'counselor', 'not helping',
      'need more help', 'talk to a real',
      // Arabic
      'أريد التحدث', 'معالج', 'طبيب', 'مختص', 'شخص حقيقي',
      'لا يساعدني', 'أحتاج مساعدة أكثر', 'تحويلي', 'أريد معالج',
      // French
      'parler à quelqu', 'personne réelle', 'thérapeute',
      'professionnel', 'médecin', 'ne m\'aide pas',
      'besoin de plus d\'aide', 'psychologue',
    ];

    final lowerMessage = message.toLowerCase();
    return escalationKeywords.any((keyword) => lowerMessage.contains(keyword));
  }
}

// ── Models ─────────────────────────────────────────────────────────────────

/// Chat message model for Gemini API
class GeminiChatMessage {
  final String role; // 'user' or 'model'
  final String content;

  GeminiChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'parts': [
        {'text': content},
      ],
    };
  }
}

/// Response from Gemini API
class GeminiResponse {
  final String content;
  final int tokensUsed;
  final String model;

  GeminiResponse({
    required this.content,
    required this.tokensUsed,
    required this.model,
  });
}

/// Custom exception for Gemini errors
class GeminiException implements Exception {
  final String message;
  final bool isRetryable;

  GeminiException(this.message, {this.isRetryable = false});

  @override
  String toString() => 'GeminiException: $message';
}
