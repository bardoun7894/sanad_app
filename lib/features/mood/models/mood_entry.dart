import '../widgets/mood_selector.dart';

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
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood': mood.index,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

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
      case MoodType.tired:
        return '😴';
    }
  }

  static String getLabel(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return 'Happy';
      case MoodType.calm:
        return 'Calm';
      case MoodType.anxious:
        return 'Anxious';
      case MoodType.sad:
        return 'Sad';
      case MoodType.tired:
        return 'Tired';
    }
  }

  static int getMoodScore(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return 5;
      case MoodType.calm:
        return 4;
      case MoodType.tired:
        return 3;
      case MoodType.anxious:
        return 2;
      case MoodType.sad:
        return 1;
    }
  }
}
