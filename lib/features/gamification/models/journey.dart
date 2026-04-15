import 'package:cloud_firestore/cloud_firestore.dart';

/// Journey category enum
enum JourneyCategory {
  anxiety,
  depression,
  stress,
  self_esteem,
  resilience,
  mindfulness,
}

/// Journey difficulty level
enum JourneyDifficulty { beginner, intermediate, advanced }

/// Content type for a journey chapter
enum ChapterContentType { lesson, exercise, quiz, reflection }

/// A therapeutic journey comprising multiple chapters
class Journey {
  final String id;
  final String titleAr;
  final String titleEn;
  final String titleFr;
  final String descriptionAr;
  final String descriptionEn;
  final String descriptionFr;
  final JourneyCategory category;
  final JourneyDifficulty difficulty;
  final String icon;
  final int totalXp;
  final int estimatedDays;
  final int unlockLevel;
  final bool isPremium;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Journey({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.titleFr,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.category,
    required this.difficulty,
    required this.icon,
    this.totalXp = 0,
    this.estimatedDays = 7,
    this.unlockLevel = 1,
    this.isPremium = false,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns the localized title based on locale code
  String getLocalizedTitle(String locale) {
    switch (locale) {
      case 'ar':
        return titleAr;
      case 'fr':
        return titleFr;
      default:
        return titleEn;
    }
  }

  /// Returns the localized description based on locale code
  String getLocalizedDescription(String locale) {
    switch (locale) {
      case 'ar':
        return descriptionAr;
      case 'fr':
        return descriptionFr;
      default:
        return descriptionEn;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title_ar': titleAr,
      'title_en': titleEn,
      'title_fr': titleFr,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'description_fr': descriptionFr,
      'category': category.name,
      'difficulty': difficulty.name,
      'icon': icon,
      'total_xp': totalXp,
      'estimated_days': estimatedDays,
      'unlock_level': unlockLevel,
      'is_premium': isPremium,
      'is_active': isActive,
      'display_order': displayOrder,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory Journey.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Journey._fromMap(data, doc.id);
  }

  factory Journey._fromMap(Map<String, dynamic> json, String id) {
    final categoryStr = json['category'] as String? ?? 'mindfulness';
    final category = JourneyCategory.values.firstWhere(
      (c) => c.name == categoryStr,
      orElse: () => JourneyCategory.mindfulness,
    );

    final difficultyStr = json['difficulty'] as String? ?? 'beginner';
    final difficulty = JourneyDifficulty.values.firstWhere(
      (d) => d.name == difficultyStr,
      orElse: () => JourneyDifficulty.beginner,
    );

    return Journey(
      id: id,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      titleFr: json['title_fr'] as String? ?? '',
      descriptionAr: json['description_ar'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionFr: json['description_fr'] as String? ?? '',
      category: category,
      difficulty: difficulty,
      icon: json['icon'] as String? ?? 'auto_stories',
      totalXp: json['total_xp'] as int? ?? 0,
      estimatedDays: json['estimated_days'] as int? ?? 7,
      unlockLevel: json['unlock_level'] as int? ?? 1,
      isPremium: json['is_premium'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

/// A single chapter within a journey
class JourneyChapter {
  final String id;
  final String titleAr;
  final String titleEn;
  final String titleFr;
  final String contentAr;
  final String contentEn;
  final String contentFr;
  final ChapterContentType contentType;
  final int xpReward;
  final int order;
  final int durationMinutes;
  final DateTime createdAt;

  const JourneyChapter({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.titleFr,
    required this.contentAr,
    required this.contentEn,
    required this.contentFr,
    required this.contentType,
    this.xpReward = 25,
    this.order = 0,
    this.durationMinutes = 10,
    required this.createdAt,
  });

  /// Returns the localized title based on locale code
  String getLocalizedTitle(String locale) {
    switch (locale) {
      case 'ar':
        return titleAr;
      case 'fr':
        return titleFr;
      default:
        return titleEn;
    }
  }

  /// Returns the localized description based on locale code
  String getLocalizedDescription(String locale) {
    switch (locale) {
      case 'ar':
        return contentAr;
      case 'fr':
        return contentFr;
      default:
        return contentEn;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title_ar': titleAr,
      'title_en': titleEn,
      'title_fr': titleFr,
      'content_ar': contentAr,
      'content_en': contentEn,
      'content_fr': contentFr,
      'content_type': contentType.name,
      'xp_reward': xpReward,
      'order': order,
      'duration_minutes': durationMinutes,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory JourneyChapter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return JourneyChapter._fromMap(data, doc.id);
  }

  factory JourneyChapter._fromMap(Map<String, dynamic> json, String id) {
    final contentTypeStr = json['content_type'] as String? ?? 'lesson';
    final contentType = ChapterContentType.values.firstWhere(
      (t) => t.name == contentTypeStr,
      orElse: () => ChapterContentType.lesson,
    );

    return JourneyChapter(
      id: id,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      titleFr: json['title_fr'] as String? ?? '',
      contentAr: json['content_ar'] as String? ?? '',
      contentEn: json['content_en'] as String? ?? '',
      contentFr: json['content_fr'] as String? ?? '',
      contentType: contentType,
      xpReward: json['xp_reward'] as int? ?? 25,
      order: json['order'] as int? ?? 0,
      durationMinutes: json['duration_minutes'] as int? ?? 10,
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
