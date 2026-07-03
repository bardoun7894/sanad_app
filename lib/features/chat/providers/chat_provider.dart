import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../mood/models/mood_enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import '../models/ai_persona.dart';
import '../services/ai_chat_service.dart';
import '../../home/home_screen.dart';
import '../../subscription/providers/feature_gating_provider.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/user_context_service.dart';
import '../../crisis/models/crisis_keywords.dart';
import '../../crisis/models/crisis_alert.dart';
import '../../crisis/services/crisis_detection_service.dart';
import '../../crisis/services/crisis_notification_service.dart';

/// Provider for AI Chat Service.
/// Uses Gemini directly with API key from AppConfig (Firestore > dart-define > .env).
final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return AiChatService();
});

/// Provider for user context service (fetches mood, tests, streaks, sessions, risk).
final userContextServiceProvider = Provider<UserContextService>((ref) {
  return UserContextService();
});

/// Main Chat Provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  StreamSubscription<List<Message>>? _messagesSubscription;
  bool _isInitialized = false;

  static const String _guestBoxName = 'guest_chat';
  static const String _guestCountKey = 'guest_message_count';

  ChatNotifier(this.ref) : super(const ChatState()) {
    _initializeChat();
    // Subscription status resolves asynchronously (Firestore/Freemius stream).
    // If it finishes loading after the initial message-limit check ran, a
    // premium user could get stuck showing the free-tier paywall forever
    // since nothing else re-evaluates it. Recompute whenever the tier changes.
    ref.listen<SubscriptionTier>(subscriptionTierProvider, (previous, next) {
      if (previous != next) _recomputeMessageLimit();
    });
  }

  /// Re-check the free-tier message limit against the current subscription
  /// tier and this month's message count. No-op for unlimited tiers.
  void _recomputeMessageLimit() {
    if (!mounted || _userId == null) return;
    final tier = _currentTier;
    final limit = tier.monthlyAiMessages;
    if (limit <= 0) {
      // Unlimited tier — clear any stale lockout immediately.
      if (state.guestLimitReached) {
        _safeState(state.copyWith(guestLimitReached: false));
      }
      return;
    }
    final now = DateTime.now();
    final userMessageCount = state.messages
        .where(
          (m) =>
              m.type == MessageType.user &&
              m.timestamp.year == now.year &&
              m.timestamp.month == now.month,
        )
        .length;
    _safeState(
      state.copyWith(
        guestMessageCount: userMessageCount,
        guestLimitReached: userMessageCount >= limit,
      ),
    );
  }

  /// Safe state update — skips if disposed.
  void _safeState(ChatState newState) {
    if (mounted) state = newState;
  }

  AiChatService? get _aiService => ref.read(aiChatServiceProvider);
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  SubscriptionTier get _currentTier {
    try {
      return ref.read(subscriptionTierProvider);
    } catch (_) {
      return SubscriptionTier.free;
    }
  }

  /// Load persisted guest message count from Hive.
  Future<int> _loadGuestMessageCount() async {
    try {
      final box = await Hive.openBox(_guestBoxName);
      return box.get(_guestCountKey, defaultValue: 0) as int;
    } catch (_) {
      return 0;
    }
  }

  /// Persist guest message count to Hive.
  Future<void> _saveGuestMessageCount(int count) async {
    try {
      final box = await Hive.openBox(_guestBoxName);
      await box.put(_guestCountKey, count);
    } catch (_) {}
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final mood = ref.read(selectedMoodProvider);
    final userId = _userId;

    // Set initial state with welcome message
    final welcomeMessage = Message(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      content: ChatResponses.getWelcomeMessage(mood),
      type: MessageType.bot,
      timestamp: DateTime.now(),
    );

    // Load guest message count if user is not logged in
    int guestCount = 0;
    if (userId == null) {
      guestCount = await _loadGuestMessageCount();
    }

    _safeState(
      ChatState(
        messages: [welcomeMessage],
        currentMood: mood,
        quickReplies: ChatResponses.getQuickReplies(mood),
        guestMessageCount: guestCount,
        guestLimitReached: guestCount >= ChatState.guestMessageLimit,
      ),
    );

    // If user is logged in and AI service is available, load history
    if (mounted &&
        userId != null &&
        _aiService != null &&
        _aiService!.isAvailable) {
      await _loadChatHistory(userId);
    }
  }

  Future<void> _loadChatHistory(String userId) async {
    if (_aiService == null || !mounted) return;
    if (!_aiService!.isAvailable || _userId != userId) return;

    _safeState(state.copyWith(isLoading: true));

    try {
      if (_userId != userId) {
        _safeState(state.copyWith(isLoading: false));
        return;
      }

      // Initialize chat document
      await _aiService!.getOrCreateChat(userId, mood: state.currentMood);
      if (!mounted) return;
      if (_userId != userId) {
        _safeState(state.copyWith(isLoading: false));
        return;
      }

      // Load existing messages
      final messages = await _aiService!.loadChatHistory(userId);
      if (!mounted) return;

      if (messages.isNotEmpty) {
        // Check free user message limit (resets every calendar month)
        final now = DateTime.now();
        final userMessageCount = messages
            .where(
              (m) =>
                  m.type == MessageType.user &&
                  m.timestamp.year == now.year &&
                  m.timestamp.month == now.month,
            )
            .length;
        final tier = _currentTier;
        final limit = tier.monthlyAiMessages;
        final limitReached = limit > 0 && userMessageCount >= limit;

        _safeState(
          state.copyWith(
            messages: messages,
            isLoading: false,
            quickReplies: [], // Clear quick replies if there's history
            guestMessageCount: userMessageCount,
            guestLimitReached: limitReached,
          ),
        );
      } else {
        _safeState(state.copyWith(isLoading: false));
      }

      // Start listening to real-time updates
      if (mounted) _startMessageStream(userId);
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      if (!mounted) return;
      _safeState(
        state.copyWith(isLoading: false, error: 'Failed to load chat history'),
      );
    }
  }

  void _startMessageStream(String userId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = _aiService
        ?.streamMessages(userId)
        .listen(
          (messages) {
            if (mounted && messages.isNotEmpty) {
              _safeState(state.copyWith(messages: messages));
            }
          },
          onError: (e) {
            debugPrint('Message stream error: $e');
          },
        );
  }

  /// Send a message (uses AI service if available, fallback otherwise)
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userId = _userId;

    // Message limit check (guests and free users)
    if (state.guestLimitReached) {
      return; // UI shows signup/upgrade prompt
    }

    // Create user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    // Add user message to state immediately (optimistic update)
    _safeState(
      state.copyWith(
        messages: [...state.messages, userMessage],
        isTyping: true,
        quickReplies: [], // Clear quick replies after first message
        error: null,
      ),
    );

    // Track message count for guests and free users
    final tier = _currentTier;
    final limit = userId == null
        ? ChatState.guestMessageLimit
        : tier.monthlyAiMessages;

    if (limit > 0) {
      // -1 means unlimited, only track when there's a limit
      final newCount = state.guestMessageCount + 1;
      if (userId == null) {
        await _saveGuestMessageCount(newCount);
      }
      if (!mounted) return;
      _safeState(
        state.copyWith(
          guestMessageCount: newCount,
          guestLimitReached: newCount >= limit,
        ),
      );
    }

    // Two-tier crisis detection
    final crisisResult = CrisisKeywords.analyze(content);
    final shouldEscalate = GeminiService.shouldSuggestEscalation(content);

    if (crisisResult.isCrisis && crisisResult.severity == 'critical') {
      // Tier 1: Critical - Instant block + crisis response + alert
      await _handleCriticalCrisis(userId, content, crisisResult);
      return;
    }

    if (crisisResult.isCrisis && crisisResult.severity == 'high') {
      // Tier 2: High - Send message normally but create background alert
      _handleHighCrisisBackground(userId, content, crisisResult);
    }

    // Check if user is in crisis mode (chat disabled)
    if (userId != null) {
      final crisisService = CrisisDetectionService();
      final inCrisisMode = await crisisService.isUserInCrisisMode(userId);
      if (!mounted) return;
      if (inCrisisMode) {
        _safeState(state.copyWith(isTyping: false, isCrisisMode: true));
        return;
      }
    }

    // Use AI service if available and user is logged in
    if (_aiService != null && userId != null) {
      await _sendWithAiService(userId, content, shouldEscalate);
    } else {
      // Fallback to static responses (used by guests and when AI is unavailable)
      await _sendWithFallback(content, shouldEscalate);
    }
  }

  /// Get the current app language code ('ar', 'en', or 'fr').
  String get _currentLanguage {
    try {
      final langState = ref.read(languageProvider);
      switch (langState.language) {
        case AppLanguage.arabic:
          return 'ar';
        case AppLanguage.english:
          return 'en';
        case AppLanguage.french:
          return 'fr';
      }
    } catch (_) {
      return 'ar'; // Default to Arabic
    }
  }

  /// Build rich user context map for RAG (mood history, tests, sessions, risk).
  /// Uses [UserContextService] for comprehensive data fetching.
  Future<Map<String, dynamic>> _buildUserContext(String userId) async {
    try {
      final contextService = ref.read(userContextServiceProvider);
      final ctx = await contextService.buildContext(userId);

      // Override tier from provider if available (more accurate than Firestore)
      try {
        final tier = ref.read(subscriptionTierProvider);
        ctx['tier'] = tier.name;
      } catch (_) {}

      // Add current mood from chat state
      if (state.currentMood != null) {
        ctx['currentMood'] = state.currentMood!.name;
      }

      return ctx;
    } catch (e) {
      debugPrint('Error building user context: $e');
      return {};
    }
  }

  Future<void> _sendWithAiService(
    String userId,
    String content,
    bool shouldEscalate,
  ) async {
    try {
      // Fetch user context (mood history, tests, sessions, risk) before calling AI
      final userCtx = await _buildUserContext(userId);
      if (!mounted) return;

      // Read the currently selected persona from the provider.
      final persona = ref.read(aiPersonaProvider).id;

      await _aiService!.sendMessage(
        userId: userId,
        content: content,
        conversationHistory: state.messages,
        currentMood: state.currentMood,
        language: _currentLanguage,
        persona: persona,
        userContext: userCtx,
      );
      if (!mounted) return;

      // Don't manually append the bot message to state here.
      // The Firestore real-time stream (_startMessageStream) will deliver
      // the bot message automatically once it's saved by the service.
      // Manually appending would cause duplicates because the stream
      // listener also updates state.messages.
      _safeState(state.copyWith(isTyping: false));

      // If user seems to want human help, suggest escalation
      if (shouldEscalate) {
        _suggestEscalation();
      }
    } catch (e) {
      debugPrint('AI Service Error: $e');
      if (!mounted) return;
      // Set error state to notify UI
      _safeState(
        state.copyWith(
          error: 'AI temporarily unavailable. Using basic responses.',
          isTyping: false,
        ),
      );
      // On error, fallback to static response
      if (mounted) await _sendWithFallback(content, shouldEscalate);
    }
  }

  Future<void> _sendWithFallback(String content, bool shouldEscalate) async {
    // Simulate typing delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final response = ChatResponses.getBotResponse(content);

    final botMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      type: MessageType.bot,
      timestamp: DateTime.now(),
      metadata: const MessageMetadata(model: 'fallback'),
    );

    _safeState(
      state.copyWith(
        messages: [...state.messages, botMessage],
        isTyping: false,
      ),
    );

    if (shouldEscalate) {
      _suggestEscalation();
    }
  }

  /// Tier 1: Critical crisis - block chat, show crisis response, write alert.
  Future<void> _handleCriticalCrisis(
    String? userId,
    String content,
    CrisisDetectionResult crisisResult,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    const crisisMessage = '''
I hear you, and I want you to know that you're not alone. What you're feeling matters, and there are people who want to help.

If you're in immediate danger, please reach out to:
- Saudi Arabia: Mental Health Hotline 920033360
- Morocco: SOS Psychiatrie 0522-293-030
- Crisis Text Line: Text HOME to 741741
- Emergency Services: 112

Your safety is the most important thing right now. Please tap "Get Help" for emergency resources.

Remember: It's brave to ask for help. You matter.''';

    final botMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: crisisMessage,
      type: MessageType.bot,
      timestamp: DateTime.now(),
      metadata: MessageMetadata(
        crisisDetected: true,
        crisisSeverity: 'critical',
        crisisKeywordsMatched: crisisResult.matchedKeywords,
        escalationSuggested: true,
      ),
    );

    _safeState(
      state.copyWith(
        messages: [...state.messages, botMessage],
        isTyping: false,
        isCrisisMode: true,
      ),
    );

    // Write crisis alert + set crisis mode in background
    if (userId != null) {
      Future(() async {
        try {
          final crisisService = CrisisDetectionService();
          final userName = await _getUserName(userId);

          final alertId = await crisisService.reportCrisis(
            userId: userId,
            userName: userName,
            alertType: CrisisAlertType.crisisKeyword,
            source: CrisisAlertSource.aiChat,
            severity: CrisisAlertSeverity.critical,
            triggeredText: content,
            matchedKeywords: crisisResult.matchedKeywords,
            language: crisisResult.detectedLanguage,
          );

          await crisisService.setCrisisMode(
            userId: userId,
            enabled: true,
            setBy: 'system',
          );

          // Notify admins
          final notifService = CrisisNotificationService();
          await notifService.notifyAdmins(
            alert: CrisisAlert(
              id: alertId,
              userId: userId,
              userName: userName,
              alertType: CrisisAlertType.crisisKeyword,
              source: CrisisAlertSource.aiChat,
              severity: CrisisAlertSeverity.critical,
              triggeredText: content,
              matchedKeywords: crisisResult.matchedKeywords,
              language: crisisResult.detectedLanguage,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        } catch (e) {
          debugPrint('Error writing crisis alert: $e');
        }
      });
    }
  }

  /// Tier 2: High crisis - message sent normally, background AI confirmation + alert.
  void _handleHighCrisisBackground(
    String? userId,
    String content,
    CrisisDetectionResult crisisResult,
  ) {
    if (userId == null) return;

    Future(() async {
      try {
        final crisisService = CrisisDetectionService();
        final aiConfirmed = await crisisService.confirmWithAi(
          content,
          crisisResult.detectedLanguage,
        );

        if (aiConfirmed) {
          final userName = await _getUserName(userId);
          await crisisService.reportCrisis(
            userId: userId,
            userName: userName,
            alertType: CrisisAlertType.aiFlagged,
            source: CrisisAlertSource.aiChat,
            severity: CrisisAlertSeverity.high,
            triggeredText: content,
            matchedKeywords: crisisResult.matchedKeywords,
            language: crisisResult.detectedLanguage,
            aiConfirmed: true,
          );
        }
      } catch (e) {
        debugPrint('Background crisis confirmation error: $e');
      }
    });
  }

  Future<String> _getUserName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['name'] as String? ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  void _suggestEscalation() {
    // This will trigger the UI to show escalation options
    // The actual navigation is handled by the chat screen
  }

  /// Select a quick reply
  void selectQuickReply(String reply) {
    sendMessage(reply);
  }

  /// Clear chat and start fresh
  Future<void> clearChat() async {
    final userId = _userId;

    if (userId != null && _aiService != null) {
      await _aiService!.clearChat(userId);
    }
    if (!mounted) return;

    _isInitialized = false;
    await _initializeChat();
  }

  /// Escalate chat to human (admin or therapist)
  Future<String?> escalateChat({
    required String escalateTo, // 'admin' or 'therapist'
    String? therapistId,
  }) async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      // Get conversation summary for context transfer
      String? contextSummary;
      if (_aiService != null) {
        contextSummary = await _aiService!.getConversationSummary(userId);
        await _aiService!.markAsEscalated(
          userId: userId,
          escalatedTo: escalateTo,
          therapistId: therapistId,
        );
      }

      if (!mounted) return contextSummary;
      _safeState(state.copyWith(isEscalated: true, escalatedTo: escalateTo));

      return contextSummary;
    } catch (e) {
      debugPrint('Error escalating chat: $e');
      return null;
    }
  }

  /// Update current mood
  void updateMood(MoodType mood) {
    _safeState(state.copyWith(currentMood: mood));
  }

  /// Retry failed message
  Future<void> retryMessage(Message failedMessage) async {
    if (failedMessage.type != MessageType.user) return;
    if (failedMessage.status != MessageStatus.failed) return;

    // Remove failed message and resend
    final updatedMessages = state.messages
        .where((m) => m.id != failedMessage.id)
        .toList();

    _safeState(state.copyWith(messages: updatedMessages));
    await sendMessage(failedMessage.content);
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
