import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's engagement streak data
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int totalMoodsLogged;
  final int totalSessions;
  final int challengesCompleted;
  final List<String> achievements;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.totalMoodsLogged = 0,
    this.totalSessions = 0,
    this.challengesCompleted = 0,
    this.achievements = const [],
  });

  /// Check if the streak is active (activity within last 24 hours)
  bool get isStreakActive {
    if (lastActivityDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActivity = DateTime(
      lastActivityDate!.year,
      lastActivityDate!.month,
      lastActivityDate!.day,
    );
    return today.difference(lastActivity).inDays <= 1;
  }

  /// Check if user has logged activity today
  bool get hasActivityToday {
    if (lastActivityDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActivity = DateTime(
      lastActivityDate!.year,
      lastActivityDate!.month,
      lastActivityDate!.day,
    );
    return today == lastActivity;
  }

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? totalMoodsLogged,
    int? totalSessions,
    int? challengesCompleted,
    List<String>? achievements,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      totalMoodsLogged: totalMoodsLogged ?? this.totalMoodsLogged,
      totalSessions: totalSessions ?? this.totalSessions,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      achievements: achievements ?? this.achievements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_activity': lastActivityDate != null
          ? Timestamp.fromDate(lastActivityDate!)
          : null,
      'total_moods_logged': totalMoodsLogged,
      'total_sessions': totalSessions,
      'challenges_completed': challengesCompleted,
      'achievements': achievements,
    };
  }

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastActivityDate: json['last_activity'] != null
          ? (json['last_activity'] as Timestamp).toDate()
          : null,
      totalMoodsLogged: json['total_moods_logged'] as int? ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      challengesCompleted: json['challenges_completed'] as int? ?? 0,
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Demo data for guests
  static StreakData get demo => StreakData(
        currentStreak: 5,
        longestStreak: 12,
        lastActivityDate: DateTime.now(),
        totalMoodsLogged: 23,
        totalSessions: 3,
        challengesCompleted: 8,
        achievements: ['first_mood', '7_day_streak'],
      );
}
