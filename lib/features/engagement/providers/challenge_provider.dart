import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_cache_helper.dart';
import '../models/challenge.dart';
import 'streak_provider.dart';

/// State for the daily challenge
class DailyChallengeState {
  final DailyChallenge? challenge;
  final bool isLoading;
  final String? error;

  const DailyChallengeState({
    this.challenge,
    this.isLoading = false,
    this.error,
  });

  DailyChallengeState copyWith({
    DailyChallenge? challenge,
    bool? isLoading,
    String? error,
  }) {
    return DailyChallengeState(
      challenge: challenge ?? this.challenge,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for today's daily challenge
final dailyChallengeProvider =
    StateNotifierProvider<DailyChallengeNotifier, DailyChallengeState>((ref) {
      return DailyChallengeNotifier(ref);
    });

class DailyChallengeNotifier extends StateNotifier<DailyChallengeState> {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DailyChallengeNotifier(this._ref) : super(const DailyChallengeState()) {
    _loadTodaysChallenge();
  }

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _loadTodaysChallenge() async {
    state = state.copyWith(isLoading: true);

    try {
      // For guests, show demo challenge
      if (_userId == null) {
        state = DailyChallengeState(challenge: DemoChallenges.getToday());
        return;
      }

      // Check if user already completed today's challenge
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final completionDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('challenge_completions')
          .where('completed_at', isGreaterThanOrEqualTo: startOfDay)
          .limit(1)
          .getCacheFirst();

      final isCompleted = completionDoc.docs.isNotEmpty;

      // Fetch the active challenges from Firestore.
      //
      // Two deliberate choices here:
      //  1. Plain server-first get() (not getCacheFirst) so admin edits —
      //     including English translations added from the control panel —
      //     reflect on the app instead of being masked by a stale local
      //     cache. Falls back to the local cache automatically when offline.
      //  2. We do NOT use orderBy('order') in the query. Firestore silently
      //     drops documents missing the orderBy field, which was hiding every
      //     challenge that lacked an `order` value (all but one of the seeded
      //     docs). Instead we fetch all active docs and order them client-side
      //     so admin edits to ANY challenge are reachable.
      final challengeQuery = await _firestore
          .collection('daily_challenges')
          .where('is_active', isEqualTo: true)
          .get();

      DailyChallenge challenge;
      if (challengeQuery.docs.isEmpty) {
        // Use demo challenge if none in Firestore
        challenge = DemoChallenges.getToday();
      } else {
        // Admin-pinned model: show the active challenge with the lowest
        // `order`. Docs missing `order` sort to the end (so a deliberately
        // ordered challenge always wins); ties break by id for stability.
        final docs = [...challengeQuery.docs]..sort((a, b) {
          final ao = (a.data()['order'] as num?)?.toInt() ?? 1 << 30;
          final bo = (b.data()['order'] as num?)?.toInt() ?? 1 << 30;
          if (ao != bo) return ao.compareTo(bo);
          return a.id.compareTo(b.id);
        });
        final data = docs.first.data();
        data['id'] = docs.first.id;
        challenge = DailyChallenge.fromJson(data);
      }

      // Mark as completed if already done today
      if (isCompleted) {
        challenge = challenge.copyWith(
          isCompleted: true,
          completedAt: completionDoc.docs.first
              .data()['completed_at']
              ?.toDate(),
        );
      }

      state = DailyChallengeState(challenge: challenge);
    } catch (e) {
      // Fallback to demo challenge on error
      state = DailyChallengeState(
        challenge: DemoChallenges.getToday(),
        error: e.toString(),
      );
    }
  }

  /// Complete the current challenge
  Future<bool> completeChallenge() async {
    if (_userId == null || state.challenge == null) return false;

    final challenge = state.challenge!;
    if (challenge.isCompleted) return false;

    state = state.copyWith(isLoading: true);

    try {
      final now = DateTime.now();

      // Record completion
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('challenge_completions')
          .add({
            'challenge_id': challenge.id,
            'challenge_type': challenge.type.name,
            'completed_at': now,
          });

      // Update streak provider
      await _ref.read(streakProvider.notifier).recordChallenge();

      // Update local state
      state = DailyChallengeState(
        challenge: challenge.copyWith(isCompleted: true, completedAt: now),
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Skip today's challenge (doesn't affect streak)
  void skipChallenge() {
    if (state.challenge == null) return;
    state = DailyChallengeState(
      challenge: state.challenge!.copyWith(isCompleted: true),
    );
  }

  /// Refresh the challenge
  Future<void> refresh() async {
    await _loadTodaysChallenge();
  }
}

/// Provider for challenge completion history
final challengeHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final query = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('challenge_completions')
      .orderBy('completed_at', descending: true)
      .limit(30)
      .getCacheFirst();

  return query.docs.map((doc) => doc.data()).toList();
});
