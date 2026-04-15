import 'package:flutter/material.dart';

/// Represents an achievement that users can unlock
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    Color? color,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

/// All available achievements in the app
class AchievementDefinitions {
  static const List<Achievement> all = [
    Achievement(
      id: 'first_mood',
      title: 'First Step',
      description: 'Logged your first mood',
      icon: Icons.emoji_emotions_rounded,
      color: Color(0xFF10B981),
    ),
    Achievement(
      id: '7_day_streak',
      title: 'Week Warrior',
      description: 'Maintained a 7-day streak',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF97316),
    ),
    Achievement(
      id: '30_day_streak',
      title: 'Monthly Champion',
      description: 'Maintained a 30-day streak',
      icon: Icons.military_tech_rounded,
      color: Color(0xFFEAB308),
    ),
    Achievement(
      id: 'first_session',
      title: 'Brave Start',
      description: 'Completed your first therapy session',
      icon: Icons.psychology_rounded,
      color: Color(0xFF3B82F6),
    ),
    Achievement(
      id: 'mood_master',
      title: 'Mood Master',
      description: 'Logged 50 moods',
      icon: Icons.insights_rounded,
      color: Color(0xFF8B5CF6),
    ),
    Achievement(
      id: 'community_contributor',
      title: 'Community Voice',
      description: 'Made your first community post',
      icon: Icons.forum_rounded,
      color: Color(0xFFEC4899),
    ),
    Achievement(
      id: 'early_bird',
      title: 'Early Bird',
      description: 'Morning check-in before 8 AM',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFFBBF24),
    ),
    Achievement(
      id: 'night_owl',
      title: 'Night Owl',
      description: 'Evening reflection after 9 PM',
      icon: Icons.nightlight_rounded,
      color: Color(0xFF6366F1),
    ),
    Achievement(
      id: 'challenge_starter',
      title: 'Challenge Accepted',
      description: 'Completed your first daily challenge',
      icon: Icons.flag_rounded,
      color: Color(0xFF14B8A6),
    ),
    Achievement(
      id: 'challenge_master',
      title: 'Challenge Master',
      description: 'Completed 10 daily challenges',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFD97706),
    ),
  ];

  /// Get achievement by ID with unlock status
  static Achievement? getById(String id, {bool isUnlocked = false, DateTime? unlockedAt}) {
    try {
      final achievement = all.firstWhere((a) => a.id == id);
      return achievement.copyWith(isUnlocked: isUnlocked, unlockedAt: unlockedAt);
    } catch (e) {
      return null;
    }
  }

  /// Get all achievements with unlock status from user's achievement list
  static List<Achievement> getAllWithStatus(List<String> unlockedIds) {
    return all.map((achievement) {
      final isUnlocked = unlockedIds.contains(achievement.id);
      return achievement.copyWith(isUnlocked: isUnlocked);
    }).toList();
  }
}
