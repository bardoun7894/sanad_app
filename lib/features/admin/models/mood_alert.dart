import '../../mood/models/mood_enums.dart';

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
