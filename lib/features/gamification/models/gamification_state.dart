import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single unlocked achievement with its timestamp
class UnlockedAchievement {
  final String id;
  final DateTime unlockedAt;

  const UnlockedAchievement({required this.id, required this.unlockedAt});

  Map<String, dynamic> toFirestore() {
    return {'id': id, 'unlocked_at': Timestamp.fromDate(unlockedAt)};
  }

  factory UnlockedAchievement.fromFirestore(Map<String, dynamic> json) {
    return UnlockedAchievement(
      id: json['id'] as String? ?? '',
      unlockedAt: json['unlocked_at'] != null
          ? (json['unlocked_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

/// Tracks progress within a specific journey
class JourneyProgressEntry {
  final int currentChapter;
  final List<int> chaptersCompleted;
  final DateTime startedAt;
  final DateTime? completedAt;

  const JourneyProgressEntry({
    this.currentChapter = 0,
    this.chaptersCompleted = const [],
    required this.startedAt,
    this.completedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'current_chapter': currentChapter,
      'chapters_completed': chaptersCompleted,
      'started_at': Timestamp.fromDate(startedAt),
      'completed_at': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
    };
  }

  factory JourneyProgressEntry.fromFirestore(Map<String, dynamic> json) {
    return JourneyProgressEntry(
      currentChapter: json['current_chapter'] as int? ?? 0,
      chaptersCompleted:
          (json['chapters_completed'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      startedAt: json['started_at'] != null
          ? (json['started_at'] as Timestamp).toDate()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? (json['completed_at'] as Timestamp).toDate()
          : null,
    );
  }

  JourneyProgressEntry copyWith({
    int? currentChapter,
    List<int>? chaptersCompleted,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return JourneyProgressEntry(
      currentChapter: currentChapter ?? this.currentChapter,
      chaptersCompleted: chaptersCompleted ?? this.chaptersCompleted,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Core gamification state for a user: XP, level, streak, achievements, journeys
class GamificationState {
  final int xpTotal;
  final int level;
  final int streakCurrent;
  final int streakLongest;
  final String? streakLastDate;
  final List<UnlockedAchievement> achievements;
  final String? activeJourneyId;
  final List<String> journeysCompleted;
  final Map<String, JourneyProgressEntry> journeyProgress;
  final int dailyXpEarned;
  final String? dailyXpDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GamificationState({
    this.xpTotal = 0,
    this.level = 1,
    this.streakCurrent = 0,
    this.streakLongest = 0,
    this.streakLastDate,
    this.achievements = const [],
    this.activeJourneyId,
    this.journeysCompleted = const [],
    this.journeyProgress = const {},
    this.dailyXpEarned = 0,
    this.dailyXpDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Empty initial state for new users
  factory GamificationState.initial() {
    final now = DateTime.now();
    return GamificationState(createdAt: now, updatedAt: now);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'xp_total': xpTotal,
      'level': level,
      'streak_current': streakCurrent,
      'streak_longest': streakLongest,
      'streak_last_date': streakLastDate,
      'achievements': achievements.map((a) => a.toFirestore()).toList(),
      'active_journey_id': activeJourneyId,
      'journeys_completed': journeysCompleted,
      'journey_progress': journeyProgress.map(
        (key, value) => MapEntry(key, value.toFirestore()),
      ),
      'daily_xp_earned': dailyXpEarned,
      'daily_xp_date': dailyXpDate,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory GamificationState.fromFirestore(Map<String, dynamic> json) {
    return GamificationState(
      xpTotal: json['xp_total'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      streakCurrent: json['streak_current'] as int? ?? 0,
      streakLongest: json['streak_longest'] as int? ?? 0,
      streakLastDate: json['streak_last_date'] as String?,
      achievements:
          (json['achievements'] as List<dynamic>?)
              ?.map(
                (e) => UnlockedAchievement.fromFirestore(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      activeJourneyId: json['active_journey_id'] as String?,
      journeysCompleted:
          (json['journeys_completed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      journeyProgress:
          (json['journey_progress'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              JourneyProgressEntry.fromFirestore(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      dailyXpEarned: json['daily_xp_earned'] as int? ?? 0,
      dailyXpDate: json['daily_xp_date'] as String?,
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  GamificationState copyWith({
    int? xpTotal,
    int? level,
    int? streakCurrent,
    int? streakLongest,
    String? streakLastDate,
    List<UnlockedAchievement>? achievements,
    String? activeJourneyId,
    List<String>? journeysCompleted,
    Map<String, JourneyProgressEntry>? journeyProgress,
    int? dailyXpEarned,
    String? dailyXpDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GamificationState(
      xpTotal: xpTotal ?? this.xpTotal,
      level: level ?? this.level,
      streakCurrent: streakCurrent ?? this.streakCurrent,
      streakLongest: streakLongest ?? this.streakLongest,
      streakLastDate: streakLastDate ?? this.streakLastDate,
      achievements: achievements ?? this.achievements,
      activeJourneyId: activeJourneyId ?? this.activeJourneyId,
      journeysCompleted: journeysCompleted ?? this.journeysCompleted,
      journeyProgress: journeyProgress ?? this.journeyProgress,
      dailyXpEarned: dailyXpEarned ?? this.dailyXpEarned,
      dailyXpDate: dailyXpDate ?? this.dailyXpDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
