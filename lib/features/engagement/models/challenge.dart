import 'package:flutter/material.dart';

/// Types of daily challenges
/// Keep this enum in sync with the admin CMS enum in
/// lib/features/admin/models/cms_models.dart — the two are serialized by
/// `.name`, so a type known to one side but not the other gets silently
/// rewritten on round-trip and the wrong icon/color renders.
enum ChallengeType {
  breathing,
  journaling,
  mindfulness,
  movement,
  social,
  selfCare,
  gratitude,
  exercise,
  general,
}

/// Represents a daily wellness challenge
class DailyChallenge {
  final String id;
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final ChallengeType type;
  final int durationMinutes;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final DateTime? completedAt;

  const DailyChallenge({
    required this.id,
    required this.title,
    this.titleEn = '',
    required this.description,
    this.descriptionEn = '',
    required this.type,
    this.durationMinutes = 5,
    required this.icon,
    required this.color,
    this.isCompleted = false,
    this.completedAt,
  });

  DailyChallenge copyWith({
    String? id,
    String? title,
    String? titleEn,
    String? description,
    String? descriptionEn,
    ChallengeType? type,
    int? durationMinutes,
    IconData? icon,
    Color? color,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_en': titleEn,
      'description': description,
      'description_en': descriptionEn,
      'type': type.name,
      'duration_minutes': durationMinutes,
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'mindfulness';
    final type = ChallengeType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => ChallengeType.mindfulness,
    );

    return DailyChallenge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      type: type,
      durationMinutes: json['duration_minutes'] as int? ?? 5,
      icon: _getIconForType(type),
      color: _getColorForType(type),
    );
  }

  static IconData _getIconForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.breathing:
        return Icons.air_rounded;
      case ChallengeType.journaling:
        return Icons.edit_note_rounded;
      case ChallengeType.mindfulness:
        return Icons.self_improvement_rounded;
      case ChallengeType.movement:
        return Icons.directions_walk_rounded;
      case ChallengeType.social:
        return Icons.people_rounded;
      case ChallengeType.selfCare:
        return Icons.spa_rounded;
      case ChallengeType.gratitude:
        return Icons.favorite_rounded;
      case ChallengeType.exercise:
        return Icons.fitness_center_rounded;
      case ChallengeType.general:
        return Icons.emoji_events_rounded;
    }
  }

  static Color _getColorForType(ChallengeType type) {
    switch (type) {
      case ChallengeType.breathing:
        return const Color(0xFF06B6D4);
      case ChallengeType.journaling:
        return const Color(0xFF8B5CF6);
      case ChallengeType.mindfulness:
        return const Color(0xFF10B981);
      case ChallengeType.movement:
        return const Color(0xFFF97316);
      case ChallengeType.social:
        return const Color(0xFFEC4899);
      case ChallengeType.selfCare:
        return const Color(0xFF14B8A6);
      case ChallengeType.gratitude:
        return const Color(0xFFF43F5E);
      case ChallengeType.exercise:
        return const Color(0xFFEF4444);
      case ChallengeType.general:
        return const Color(0xFF6366F1);
    }
  }
}

/// Demo challenges for when Firestore is empty
class DemoChallenges {
  static final List<DailyChallenge> all = [
    DailyChallenge(
      id: 'demo_1',
      title: '5-Minute Breathing',
      description: 'Take 5 minutes to focus on deep, calming breaths',
      type: ChallengeType.breathing,
      durationMinutes: 5,
      icon: Icons.air_rounded,
      color: const Color(0xFF06B6D4),
    ),
    DailyChallenge(
      id: 'demo_2',
      title: 'Gratitude Journal',
      description: 'Write down 3 things you are grateful for today',
      type: ChallengeType.journaling,
      durationMinutes: 10,
      icon: Icons.edit_note_rounded,
      color: const Color(0xFF8B5CF6),
    ),
    DailyChallenge(
      id: 'demo_3',
      title: 'Mindful Moment',
      description: 'Take a 2-minute pause and observe your surroundings',
      type: ChallengeType.mindfulness,
      durationMinutes: 2,
      icon: Icons.self_improvement_rounded,
      color: const Color(0xFF10B981),
    ),
    DailyChallenge(
      id: 'demo_4',
      title: 'Take a Walk',
      description: 'Go for a 10-minute walk outside',
      type: ChallengeType.movement,
      durationMinutes: 10,
      icon: Icons.directions_walk_rounded,
      color: const Color(0xFFF97316),
    ),
    DailyChallenge(
      id: 'demo_5',
      title: 'Connect with Someone',
      description: 'Reach out to a friend or family member',
      type: ChallengeType.social,
      durationMinutes: 5,
      icon: Icons.people_rounded,
      color: const Color(0xFFEC4899),
    ),
    DailyChallenge(
      id: 'demo_6',
      title: 'Self-Care Time',
      description: 'Do one thing just for yourself today',
      type: ChallengeType.selfCare,
      durationMinutes: 15,
      icon: Icons.spa_rounded,
      color: const Color(0xFF14B8A6),
    ),
  ];

  /// Get today's challenge (rotates daily)
  static DailyChallenge getToday() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return all[dayOfYear % all.length];
  }
}

// ---------------------------------------------------------------------------
// Localization helpers — mirrors ContentItemLocalization in content_models.dart
// ---------------------------------------------------------------------------

extension DailyChallengeLocalization on DailyChallenge {
  String localizedTitle(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale.toLowerCase().startsWith('en') && titleEn.trim().isNotEmpty) {
      return titleEn;
    }
    return title;
  }

  String localizedDescription(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale.toLowerCase().startsWith('en') &&
        descriptionEn.trim().isNotEmpty) {
      return descriptionEn;
    }
    return description;
  }
}
