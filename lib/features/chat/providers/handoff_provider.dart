import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_handoff.dart';
import '../repositories/chat_handoff_repository.dart';
import '../services/handoff_service.dart';
import '../services/handoff_trigger_service.dart';
import '../../therapist_chat/services/therapist_chat_service.dart';
import 'chat_provider.dart';

// ── Service Providers ─────────────────────────────────────────────────────

/// Provider for the ChatHandoff Firestore repository.
final chatHandoffRepositoryProvider = Provider<ChatHandoffRepository>((ref) {
  return ChatHandoffRepository();
});

/// Provider for the HandoffService orchestrator.
final handoffServiceProvider = Provider<HandoffService>((ref) {
  return HandoffService(
    handoffRepository: ref.watch(chatHandoffRepositoryProvider),
    aiChatService: ref.watch(aiChatServiceProvider),
    userContextService: ref.watch(userContextServiceProvider),
    therapistChatService: ref.watch(therapistChatServiceProvider),
  );
});

/// Provider for the HandoffTriggerService evaluator.
final handoffTriggerServiceProvider = Provider<HandoffTriggerService>((ref) {
  return HandoffTriggerService();
});

/// Provider for TherapistChatService (re-exported here if not already available
/// from therapist_chat_provider; avoids circular deps by creating fresh).
final therapistChatServiceProvider = Provider<TherapistChatService>((ref) {
  return TherapistChatService();
});

// ── Stream / Future Providers ─────────────────────────────────────────────

/// Stream of pending handoffs for the admin queue.
///
/// Watches all handoffs with status `pending`, ordered by most recent first.
final pendingHandoffsProvider = StreamProvider<List<ChatHandoff>>((ref) {
  final repository = ref.watch(chatHandoffRepositoryProvider);
  return repository.streamPendingHandoffs();
});

/// Active (pending/accepted/inProgress) handoff for a given user.
///
/// Returns `null` if the user has no active handoff.
final activeUserHandoffProvider = FutureProvider.family<ChatHandoff?, String>((
  ref,
  userId,
) {
  final repository = ref.watch(chatHandoffRepositoryProvider);
  return repository.getActiveHandoffForUser(userId);
});

/// Stream of handoffs assigned to a specific therapist.
final therapistHandoffsProvider =
    StreamProvider.family<List<ChatHandoff>, String>((ref, therapistId) {
      final repository = ref.watch(chatHandoffRepositoryProvider);
      return repository.streamTherapistHandoffs(therapistId);
    });

/// Stream of handoffs for a specific user (history).
final userHandoffsProvider = StreamProvider.family<List<ChatHandoff>, String>((
  ref,
  userId,
) {
  final repository = ref.watch(chatHandoffRepositoryProvider);
  return repository.streamUserHandoffs(userId);
});

// ── Handoff Notifier ──────────────────────────────────────────────────────

/// State for the [HandoffNotifier].
class HandoffNotifierState {
  final bool isInitiating;
  final bool isAccepting;
  final String? error;
  final String? lastHandoffId;
  final String? lastTherapistChatId;

  const HandoffNotifierState({
    this.isInitiating = false,
    this.isAccepting = false,
    this.error,
    this.lastHandoffId,
    this.lastTherapistChatId,
  });

  HandoffNotifierState copyWith({
    bool? isInitiating,
    bool? isAccepting,
    String? error,
    String? lastHandoffId,
    String? lastTherapistChatId,
  }) {
    return HandoffNotifierState(
      isInitiating: isInitiating ?? this.isInitiating,
      isAccepting: isAccepting ?? this.isAccepting,
      error: error,
      lastHandoffId: lastHandoffId ?? this.lastHandoffId,
      lastTherapistChatId: lastTherapistChatId ?? this.lastTherapistChatId,
    );
  }
}

/// Manages handoff initiation and acceptance from the UI.
///
/// Used by both the user-facing chat screen (to initiate handoffs) and
/// the therapist/admin dashboard (to accept handoffs).
class HandoffNotifier extends StateNotifier<HandoffNotifierState> {
  final HandoffService _handoffService;

  HandoffNotifier({required HandoffService handoffService})
    : _handoffService = handoffService,
      super(const HandoffNotifierState());

  /// Initiate a new handoff from AI chat to therapist.
  ///
  /// Called from the user-facing chat screen when a handoff is triggered
  /// (either automatically or by user request).
  Future<String?> initiateHandoff({
    required String userId,
    required String userName,
    required HandoffTrigger triggerReason,
    String? triggerDetails,
    String? therapistId,
    String? riskAlertId,
  }) async {
    state = state.copyWith(isInitiating: true, error: null);

    try {
      final handoffId = await _handoffService.initiateHandoff(
        userId: userId,
        userName: userName,
        triggerReason: triggerReason,
        triggerDetails: triggerDetails,
        therapistId: therapistId,
        riskAlertId: riskAlertId,
      );

      state = state.copyWith(isInitiating: false, lastHandoffId: handoffId);

      return handoffId;
    } catch (e) {
      debugPrint('HandoffNotifier: Error initiating handoff: $e');
      state = state.copyWith(
        isInitiating: false,
        error: 'Failed to initiate handoff. Please try again.',
      );
      return null;
    }
  }

  /// Therapist accepts a pending handoff.
  ///
  /// Returns the therapist chat ID for navigation, or null on failure.
  Future<String?> acceptHandoff({
    required String handoffId,
    required String therapistId,
    required String therapistName,
  }) async {
    state = state.copyWith(isAccepting: true, error: null);

    try {
      final therapistChatId = await _handoffService.acceptHandoff(
        handoffId: handoffId,
        therapistId: therapistId,
        therapistName: therapistName,
      );

      state = state.copyWith(
        isAccepting: false,
        lastTherapistChatId: therapistChatId,
      );

      return therapistChatId;
    } catch (e) {
      debugPrint('HandoffNotifier: Error accepting handoff: $e');
      state = state.copyWith(
        isAccepting: false,
        error: 'Failed to accept handoff. Please try again.',
      );
      return null;
    }
  }

  /// Complete a handoff (mark as done).
  Future<void> completeHandoff(String handoffId) async {
    try {
      await _handoffService.completeHandoff(handoffId);
    } catch (e) {
      debugPrint('HandoffNotifier: Error completing handoff: $e');
      state = state.copyWith(error: 'Failed to complete handoff.');
    }
  }

  /// Clear any error state.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for the HandoffNotifier.
final handoffNotifierProvider =
    StateNotifierProvider<HandoffNotifier, HandoffNotifierState>((ref) {
      final service = ref.watch(handoffServiceProvider);
      return HandoffNotifier(handoffService: service);
    });
