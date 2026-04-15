import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_handoff.dart';
import '../../../core/services/gemini_service.dart';

/// Evaluates whether an AI chat response should trigger a handoff to a therapist.
///
/// Checks 4 trigger conditions in priority order after each AI response:
/// 1. **Crisis** - Active crisis alerts exist for the user
/// 2. **User Request** - User explicitly asked for a human / therapist
/// 3. **Mood Pattern** - Sustained low mood detected
/// 4. **AI Low Confidence** - Fallback model or very short response
class HandoffTriggerService {
  final FirebaseFirestore _firestore;

  /// Explicit phrases that indicate the user wants a human therapist.
  static const List<String> _escalationPhrases = [
    'talk to someone',
    'real person',
    'human',
    'therapist',
    'real therapist',
    'talk to a therapist',
    'speak to someone',
    'need help',
    'professional help',
    'want a therapist',
    'connect me',
    'real doctor',
    // Arabic
    '\u0623\u0631\u064a\u062f \u0645\u0639\u0627\u0644\u062c',
    '\u0634\u062e\u0635 \u062d\u0642\u064a\u0642\u064a',
    '\u0645\u0633\u0627\u0639\u062f\u0629 \u0645\u062a\u062e\u0635\u0635\u0629',
    '\u0623\u0631\u064a\u062f \u0627\u0644\u062a\u062d\u062f\u062b',
    // French
    'parler a quelqu\'un',
    'vrai th\u00e9rapeute',
    'aide professionnelle',
  ];

  HandoffTriggerService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Evaluate the latest AI response and user context for handoff triggers.
  ///
  /// Returns the highest-priority [HandoffTrigger] if one is detected,
  /// or `null` if no handoff is warranted.
  ///
  /// [userId] - The current user's ID.
  /// [latestAiResponse] - The most recent AI bot message content.
  /// [currentMood] - The user's currently selected mood (optional).
  /// [userContext] - Pre-built user context map from [UserContextService].
  Future<HandoffTrigger?> evaluate({
    required String userId,
    required String latestAiResponse,
    String? currentMood,
    Map<String, dynamic>? userContext,
  }) async {
    try {
      // Priority 1: Crisis
      final hasCrisis = await _checkCrisis(userId);
      if (hasCrisis) {
        debugPrint('HandoffTriggerService: Crisis trigger detected');
        return HandoffTrigger.crisis;
      }

      // Priority 2: User Request
      final hasUserRequest = _checkUserRequest(latestAiResponse);
      if (hasUserRequest) {
        debugPrint('HandoffTriggerService: UserRequest trigger detected');
        return HandoffTrigger.userRequest;
      }

      // Priority 3: Mood Pattern
      final hasMoodPattern = _checkMoodPattern(userContext);
      if (hasMoodPattern) {
        debugPrint('HandoffTriggerService: MoodPattern trigger detected');
        return HandoffTrigger.moodPattern;
      }

      // Priority 4: AI Low Confidence
      final hasLowConfidence = _checkAiLowConfidence(
        latestAiResponse,
        userContext,
      );
      if (hasLowConfidence) {
        debugPrint('HandoffTriggerService: AiLowConfidence trigger detected');
        return HandoffTrigger.aiLowConfidence;
      }

      return null;
    } catch (e) {
      debugPrint('HandoffTriggerService: Error evaluating triggers: $e');
      return null;
    }
  }

  // ── Crisis Check ────────────────────────────────────────────────────────

  /// Check if the user has active (unresolved) crisis alerts.
  ///
  /// Queries `/risk_alerts` for alerts with status `newAlert`, `acknowledged`,
  /// or `assigned` for this user.
  Future<bool> _checkCrisis(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('risk_alerts')
          .where('user_id', isEqualTo: userId)
          .where('status', whereIn: ['newAlert', 'acknowledged', 'assigned'])
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('HandoffTriggerService: Error checking crisis alerts: $e');
      return false;
    }
  }

  // ── User Request Check ──────────────────────────────────────────────────

  /// Check if the latest AI response or underlying user message suggests
  /// the user wants to talk to a real person.
  ///
  /// Uses [GeminiService.shouldSuggestEscalation] plus explicit phrase
  /// matching for multi-language support.
  bool _checkUserRequest(String latestAiResponse) {
    // Check GeminiService static escalation detection
    if (GeminiService.shouldSuggestEscalation(latestAiResponse)) {
      return true;
    }

    // Check explicit escalation phrases in the AI response
    // (the AI may echo back the user's intent)
    final lower = latestAiResponse.toLowerCase();
    for (final phrase in _escalationPhrases) {
      if (lower.contains(phrase.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  // ── Mood Pattern Check ──────────────────────────────────────────────────

  /// Detects sustained low mood patterns from user context.
  ///
  /// Triggers if any of:
  /// - [consecutiveLowDays] >= 3
  /// - [riskLevel] is 'high' or 'critical'
  /// - Trend is 'declining' AND average score < 2.5
  bool _checkMoodPattern(Map<String, dynamic>? userContext) {
    if (userContext == null || userContext.isEmpty) return false;

    // Check consecutive low-mood days
    final consecutiveLowDays = userContext['consecutiveLowDays'] as int? ?? 0;
    if (consecutiveLowDays >= 3) return true;

    // Check risk level
    final riskLevel = userContext['riskLevel'] as String?;
    if (riskLevel == 'high' || riskLevel == 'critical') return true;

    // Check declining trend with low average
    final moodTrend = userContext['moodTrend'] as String?;
    final avgScore = userContext['moodAvgScore'] as double?;
    if (moodTrend == 'declining' && avgScore != null && avgScore < 2.5) {
      return true;
    }

    return false;
  }

  // ── AI Low Confidence Check ─────────────────────────────────────────────

  /// Detects when the AI model is unreliable (fallback mode or very short
  /// responses that suggest the model could not generate a meaningful reply).
  ///
  /// Triggers if:
  /// - The model used is 'fallback' (static responses, Gemini was unavailable)
  /// - The response is extremely short (< 50 characters)
  bool _checkAiLowConfidence(
    String latestAiResponse,
    Map<String, dynamic>? userContext,
  ) {
    // Check if the response came from the fallback model
    // The caller should include metadata about the model used in userContext
    final model = userContext?['lastResponseModel'] as String?;
    if (model == 'fallback') return true;

    // Very short responses indicate the model could not produce meaningful output
    if (latestAiResponse.trim().length < 50) return true;

    return false;
  }
}
