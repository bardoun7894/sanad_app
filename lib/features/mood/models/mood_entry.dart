import 'package:cloud_firestore/cloud_firestore.dart';
import 'mood_enums.dart';
import '../../../core/l10n/language_provider.dart';

class MoodEntry {
  final String id;
  final MoodType mood;
  final DateTime date;
  final String? note;

  const MoodEntry({
    required this.id,
    required this.mood,
    required this.date,
    this.note,
  });

  MoodEntry copyWith({
    String? id,
    MoodType? mood,
    DateTime? date,
    String? note,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      mood: mood ?? this.mood,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  // For persistence
  Map<String, dynamic> toMap() {
    return {'mood': mood.index, 'date': Timestamp.fromDate(date), 'note': note};
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map, String id) {
    return MoodEntry(
      id: id,
      mood: MoodType.values[map['mood'] as int],
      date: (map['date'] as Timestamp).toDate(),
      note: map['note'] as String?,
    );
  }

  // Pending removal of JSON methods if not used elsewhere, or keep for other uses
  Map<String, dynamic> toJson() => {
    'id': id,
    'mood': mood.index,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      mood: MoodType.values[json['mood'] as int],
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}

// Mood metadata helper
class MoodMetadata {
  static String getEmoji(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return '😊';
      case MoodType.calm:
        return '😌';
      case MoodType.anxious:
        return '😨';
      case MoodType.sad:
        return '😢';
      case MoodType.angry:
        return '😠';
      case MoodType.tired:
        return '😴';
    }
  }

  static String getLabel(MoodType mood, {S? strings}) {
    final s = strings;
    switch (mood) {
      case MoodType.happy:
        return s?.moodHappy ?? 'Happy';
      case MoodType.calm:
        return s?.moodCalm ?? 'Calm';
      case MoodType.anxious:
        return s?.moodAnxious ?? 'Anxious';
      case MoodType.sad:
        return s?.moodSad ?? 'Sad';
      case MoodType.angry:
        return s?.moodAngry ?? 'Angry';
      case MoodType.tired:
        return s?.moodTired ?? 'Tired';
    }
  }

  static int getMoodScore(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return 5;
      case MoodType.calm:
        return 4;
      case MoodType.tired:
        return 2;
      case MoodType.anxious:
        return 2;
      case MoodType.sad:
        return 1;
      case MoodType.angry:
        return 1;
    }
  }
}
