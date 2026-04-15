import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_handoff.dart';
import '../services/handoff_trigger_service.dart';
import '../services/handoff_service.dart';
import 'handoff_provider.dart';

// ── Hybrid Chat State ─────────────────────────────────────────────────────

/// Unified state for the AI + therapist hybrid chat experience.
///
/// Tracks the current chat mode (AI or therapist), any active or suggested
/// handoffs, and transition state between modes.
class HybridChatState {
  /// Current chat mode: 'ai' or 'therapist'.
  final String currentMode;

  /// Active handoff that has been initiated (pending, accepted, or in progress).
  final ChatHandoff? activeHandoff;

  /// Suggested handoff trigger that the user has not yet acted on.
  /// The UI should show a banner/dialog prompting the user to accept or dismiss.
  final HandoffTrigger? suggestedHandoff;

  /// Whether the chat is currently transitioning between AI and therapist modes.
  final bool isTransitioning;

  /// Error message from the last operation, if any.
  final String? error;

  const HybridChatState({
    this.currentMode = 'ai',
    this.activeHandoff,
    this.suggestedHandoff,
    this.isTransitioning = false,
    this.error,
  });

  HybridChatState copyWith({
    String? currentMode,
    ChatHandoff? activeHandoff,
    HandoffTrigger? suggestedHandoff,
    bool? isTransitioning,
    String? error,
    bool clearActiveHandoff = false,
    bool clearSuggestedHandoff = false,
  }) {
    return HybridChatState(
      currentMode: currentMode ?? this.currentMode,
      activeHandoff: clearActiveHandoff
          ? null
          : (activeHandoff ?? this.activeHandoff),
      suggestedHandoff: clearSuggestedHandoff
          ? null
          : (suggestedHandoff ?? this.suggestedHandoff),
      isTransitioning: isTransitioning ?? this.isTransitioning,
      error: error,
    );
  }

  /// Whether a handoff suggestion banner should be shown.
  bool get hasSuggestion => suggestedHandoff != null;

  /// Whether there is an active handoff in progress.
  bool get hasActiveHandoff => activeHandoff != null && activeHandoff!.isActive;
}

// ── Hybrid Chat Notifier ──────────────────────────────────────────────────

/// Manages the unified AI + therapist chat state.
///
/// Coordinates with [HandoffTriggerService] to detect when a handoff should
/// be suggested, and with [HandoffService] to initiate handoffs when the
/// user accepts the suggestion.
class HybridChatNotifier extends StateNotifier<HybridChatState> {
  final HandoffTriggerService _triggerService;
  final HandoffService _handoffService;
  final Ref _ref;

  HybridChatNotifier({
    required HandoffTriggerService triggerService,
    required HandoffService handoffService,
    required Ref ref,
  }) : _triggerService = triggerService,
       _handoffService = handoffService,
       _ref = ref,
       super(const HybridChatState());

  // ── Trigger Evaluation ──────────────────────────────────────────────────

  /// Check whether the latest AI response should trigger a handoff suggestion.
  ///
  /// Called after each AI response is received. If a trigger is detected,
  /// it updates the state with a [suggestedHandoff] for the UI to display.
  Future<void> checkForHandoffSuggestion({
    required String latestResponse,
    String? currentMood,
    Map<String, dynamic>? userContext,
  }) async {
    // Only check when in AI mode
    if (state.currentMode != 'ai') return;

    // Don't suggest if there's already an active handoff or pending suggestion
    if (state.hasActiveHandoff || state.hasSuggestion) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final trigger = await _triggerService.evaluate(
        userId: userId,
        latestAiResponse: latestResponse,
        currentMood: currentMood,
        userContext: userContext,
      );

      if (trigger != null) {
        state = state.copyWith(suggestedHandoff: trigger);
        debugPrint('HybridChatNotifier: Handoff suggestion: ${trigger.name}');
      }
    } catch (e) {
      debugPrint('HybridChatNotifier: Error checking triggers: $e');
    }
  }

  // ── Handoff Initiation ──────────────────────────────────────────────────

  /// Initiate a handoff based on a trigger (user accepted the suggestion).
  ///
  /// Creates the handoff in Firestore and transitions the UI to a
  /// waiting/transitioning state.
  Future<String?> initiateHandoff(HandoffTrigger trigger) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    state = state.copyWith(
      isTransitioning: true,
      error: null,
      clearSuggestedHandoff: true,
    );

    try {
      final handoffId = await _handoffService.initiateHandoff(
        userId: user.uid,
        userName: user.displayName ?? 'User',
        triggerReason: trigger,
        triggerDetails: 'Initiated from hybrid chat',
      );

      // Refresh the active handoff
      final handoff = await _ref
          .read(chatHandoffRepositoryProvider)
          .get(handoffId);

      state = state.copyWith(isTransitioning: false, activeHandoff: handoff);

      debugPrint('HybridChatNotifier: Handoff initiated: $handoffId');
      return handoffId;
    } catch (e) {
      debugPrint('HybridChatNotifier: Error initiating handoff: $e');
      state = state.copyWith(
        isTransitioning: false,
        error: 'Failed to connect to therapist. Please try again.',
      );
      return null;
    }
  }

  // ── Dismiss Suggestion ──────────────────────────────────────────────────

  /// User dismisses the handoff suggestion banner.
  void dismissSuggestion() {
    state = state.copyWith(clearSuggestedHandoff: true);
  }

  // ── Mode Switching ──────────────────────────────────────────────────────

  /// Switch between 'ai' and 'therapist' modes.
  ///
  /// Used when a handoff is accepted (switch to therapist) or when
  /// returning to AI chat.
  void switchMode(String mode) {
    if (mode != 'ai' && mode != 'therapist') {
      debugPrint('HybridChatNotifier: Invalid mode: $mode');
      return;
    }

    state = state.copyWith(currentMode: mode);
    debugPrint('HybridChatNotifier: Switched to mode: $mode');
  }

  /// Update the active handoff (e.g. after it's been accepted by therapist).
  void updateActiveHandoff(ChatHandoff? handoff) {
    state = state.copyWith(
      activeHandoff: handoff,
      clearActiveHandoff: handoff == null,
    );

    // Auto-switch to therapist mode when handoff is accepted
    if (handoff != null &&
        handoff.status == HandoffStatus.accepted &&
        state.currentMode == 'ai') {
      switchMode('therapist');
    }
  }

  /// Clear the active handoff (e.g. after completion).
  void clearActiveHandoff() {
    state = state.copyWith(clearActiveHandoff: true);
  }

  /// Clear any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────

/// Provider for the HybridChatNotifier.
///
/// Manages the unified AI + therapist chat state for the current user.
final hybridChatProvider =
    StateNotifierProvider<HybridChatNotifier, HybridChatState>((ref) {
      return HybridChatNotifier(
        triggerService: ref.watch(handoffTriggerServiceProvider),
        handoffService: ref.watch(handoffServiceProvider),
        ref: ref,
      );
    });
