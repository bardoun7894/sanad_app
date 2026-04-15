import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/streak_data.dart';

final streakProvider = StateNotifierProvider<StreakNotifier, StreakData>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  return StreakNotifier(userId);
});

class StreakNotifier extends StateNotifier<StreakData> {
  final String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  StreakNotifier(this._userId) : super(const StreakData()) {
    if (_userId != null) {
      _init();
    } else {
      // Guest user - show demo data
      state = StreakData.demo;
    }
  }

  DocumentReference get _engagementDoc =>
      _firestore.collection('users').doc(_userId).collection('engagement').doc('streak');

  void _init() {
    _subscription = _engagementDoc.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        state = StreakData.fromJson(snapshot.data() as Map<String, dynamic>);
      } else {
        // Initialize empty streak for new users
        state = const StreakData();
        _createInitialDocument();
      }
    });
  }

  Future<void> _createInitialDocument() async {
    if (_userId == null) return;
    await _engagementDoc.set(state.toJson());
  }

  /// Record an activity and update streak
  Future<void> recordActivity({
    required String activityType, // 'mood', 'session', 'challenge'
  }) async {
    if (_userId == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int newStreak = state.currentStreak;
    int newLongest = state.longestStreak;

    if (state.lastActivityDate != null) {
      final lastDate = DateTime(
        state.lastActivityDate!.year,
        state.lastActivityDate!.month,
        state.lastActivityDate!.day,
      );

      final daysDiff = today.difference(lastDate).inDays;

      if (daysDiff == 0) {
        // Same day - no streak change
      } else if (daysDiff == 1) {
        // Consecutive day - increment streak
        newStreak++;
        if (newStreak > newLongest) {
          newLongest = newStreak;
        }
      } else {
        // Streak broken - reset to 1
        newStreak = 1;
      }
    } else {
      // First activity ever
      newStreak = 1;
    }

    // Update counters based on activity type
    int newMoods = state.totalMoodsLogged;
    int newSessions = state.totalSessions;
    int newChallenges = state.challengesCompleted;

    switch (activityType) {
      case 'mood':
        newMoods++;
        break;
      case 'session':
        newSessions++;
        break;
      case 'challenge':
        newChallenges++;
        break;
    }

    // Check for new achievements
    List<String> newAchievements = List.from(state.achievements);
    _checkAndAddAchievements(
      achievements: newAchievements,
      streak: newStreak,
      moods: newMoods,
      sessions: newSessions,
      challenges: newChallenges,
      now: now,
    );

    final newState = state.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastActivityDate: now,
      totalMoodsLogged: newMoods,
      totalSessions: newSessions,
      challengesCompleted: newChallenges,
      achievements: newAchievements,
    );

    state = newState;
    await _engagementDoc.set(newState.toJson());
  }

  void _checkAndAddAchievements({
    required List<String> achievements,
    required int streak,
    required int moods,
    required int sessions,
    required int challenges,
    required DateTime now,
  }) {
    // First mood
    if (moods >= 1 && !achievements.contains('first_mood')) {
      achievements.add('first_mood');
    }

    // 7-day streak
    if (streak >= 7 && !achievements.contains('7_day_streak')) {
      achievements.add('7_day_streak');
    }

    // 30-day streak
    if (streak >= 30 && !achievements.contains('30_day_streak')) {
      achievements.add('30_day_streak');
    }

    // First session
    if (sessions >= 1 && !achievements.contains('first_session')) {
      achievements.add('first_session');
    }

    // Mood master (50 moods)
    if (moods >= 50 && !achievements.contains('mood_master')) {
      achievements.add('mood_master');
    }

    // Challenge starter
    if (challenges >= 1 && !achievements.contains('challenge_starter')) {
      achievements.add('challenge_starter');
    }

    // Challenge master (10 challenges)
    if (challenges >= 10 && !achievements.contains('challenge_master')) {
      achievements.add('challenge_master');
    }

    // Early bird (before 8 AM)
    if (now.hour < 8 && !achievements.contains('early_bird')) {
      achievements.add('early_bird');
    }

    // Night owl (after 9 PM)
    if (now.hour >= 21 && !achievements.contains('night_owl')) {
      achievements.add('night_owl');
    }
  }

  /// Record mood log (convenience method)
  Future<void> recordMoodLog() => recordActivity(activityType: 'mood');

  /// Record session completion
  Future<void> recordSession() => recordActivity(activityType: 'session');

  /// Record challenge completion
  Future<void> recordChallenge() => recordActivity(activityType: 'challenge');

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
