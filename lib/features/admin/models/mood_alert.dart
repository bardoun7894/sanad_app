import '../../mood/models/mood_enums.dart';

// ---------------------------------------------------------------------------
// Polarity classification
// ---------------------------------------------------------------------------

/// Emotional valence of a [MoodType], used by the all-moods feed for
/// color-coding entries in the admin dashboard.
///
/// Mapping (non-negotiable per design spec):
///   positive  → happy (0), calm (1)
///   negative  → anxious (2), sad (3), angry (4)
///   neutral   → tired (5)
enum MoodPolarity { positive, negative, neutral }

/// Extension that adds a [polarity] getter to every [MoodType] value.
/// Both packets (data layer + UI layer) import this from mood_alert.dart.
extension MoodPolarityX on MoodType {
  MoodPolarity get polarity {
    switch (this) {
      case MoodType.happy:
      case MoodType.calm:
        return MoodPolarity.positive;
      case MoodType.anxious:
      case MoodType.sad:
      case MoodType.angry:
        return MoodPolarity.negative;
      case MoodType.tired:
        return MoodPolarity.neutral;
    }
  }
}

// ---------------------------------------------------------------------------
// MoodAlert model
// ---------------------------------------------------------------------------

/// A single mood-alert entry surfaced in the admin dashboard.
///
/// Represents a mood log from any user that has a NEGATIVE mood
/// (anxious, sad, angry) — used to alert admins of at-risk patients.
class MoodAlert {
  final String userId;
  final String? userName; // null = incomplete signup (no real name)
  final MoodType mood;
  final DateTime date;

  const MoodAlert({
    required this.userId,
    required this.userName,
    required this.mood,
    required this.date,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodAlert &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          userName == other.userName &&
          mood == other.mood &&
          date == other.date;

  @override
  int get hashCode =>
      userId.hashCode ^ userName.hashCode ^ mood.hashCode ^ date.hashCode;
}
