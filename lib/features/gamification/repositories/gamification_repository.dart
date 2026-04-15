import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firestore_cache_helper.dart';
import '../models/gamification_state.dart';
import '../models/xp_config.dart';

/// Repository for gamification state CRUD on /users/{userId}/gamification/progress
class GamificationRepository {
  final FirebaseFirestore _firestore;

  GamificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to the gamification progress document
  DocumentReference _progressDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('gamification')
        .doc('progress');
  }

  /// Get current gamification state (one-time read)
  Future<GamificationState?> getState(String userId) async {
    try {
      final doc = await _progressDoc(userId).getCacheFirst();
      if (!doc.exists) return null;
      return GamificationState.fromFirestore(
        doc.data() as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Error getting gamification state: $e');
      return null;
    }
  }

  /// Stream gamification state for real-time updates
  Stream<GamificationState?> streamState(String userId) {
    return _progressDoc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return GamificationState.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
      );
    });
  }

  /// Initialize gamification state for a new user
  Future<void> initializeState(String userId) async {
    try {
      final doc = await _progressDoc(userId).get();
      if (doc.exists) return; // Already initialized

      final initialState = GamificationState.initial();
      await _progressDoc(userId).set(initialState.toFirestore());
    } catch (e) {
      debugPrint('Error initializing gamification state: $e');
    }
  }

  /// Add XP with daily cap check and auto level-up.
  /// Returns the actual XP awarded (may be less than [amount] due to daily cap).
  Future<int> addXp(String userId, int amount) async {
    try {
      final doc = await _progressDoc(userId).get();
      if (!doc.exists) {
        await initializeState(userId);
        return await addXp(userId, amount);
      }

      final state = GamificationState.fromFirestore(
        doc.data() as Map<String, dynamic>,
      );

      // Check daily cap
      final today = _todayString();
      int dailyEarned = state.dailyXpEarned;
      if (state.dailyXpDate != today) {
        // New day - reset daily counter
        dailyEarned = 0;
      }

      final remaining = XpConfig.dailyCap - dailyEarned;
      if (remaining <= 0) return 0;

      final xpToAward = amount > remaining ? remaining : amount;
      final newXpTotal = state.xpTotal + xpToAward;
      final newLevel = XpConfig.levelForXp(newXpTotal);

      await _progressDoc(userId).update({
        'xp_total': FieldValue.increment(xpToAward),
        'level': newLevel,
        'daily_xp_earned': dailyEarned + xpToAward,
        'daily_xp_date': today,
        'updated_at': Timestamp.now(),
      });

      return xpToAward;
    } catch (e) {
      debugPrint('Error adding XP: $e');
      return 0;
    }
  }

  /// Update streak data
  Future<void> updateStreak(
    String userId,
    int current,
    int longest,
    String lastDate,
  ) async {
    try {
      await _progressDoc(userId).update({
        'streak_current': current,
        'streak_longest': longest,
        'streak_last_date': lastDate,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  /// Unlock an achievement for the user
  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      final achievement = UnlockedAchievement(
        id: achievementId,
        unlockedAt: DateTime.now(),
      );

      await _progressDoc(userId).update({
        'achievements': FieldValue.arrayUnion([achievement.toFirestore()]),
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  /// Update journey progress for a specific journey
  Future<void> updateJourneyProgress(
    String userId,
    String journeyId,
    JourneyProgressEntry progressEntry,
  ) async {
    try {
      await _progressDoc(userId).update({
        'journey_progress.$journeyId': progressEntry.toFirestore(),
        'active_journey_id': journeyId,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error updating journey progress: $e');
    }
  }

  /// Mark a journey as completed
  Future<void> completeJourney(String userId, String journeyId) async {
    try {
      await _progressDoc(userId).update({
        'journeys_completed': FieldValue.arrayUnion([journeyId]),
        'active_journey_id': null,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error completing journey: $e');
    }
  }

  /// Returns today's date as YYYY-MM-DD string
  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
