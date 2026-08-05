import '../../mood/models/mood_enums.dart';

/// A single private journal entry ("مذكرتي").
///
/// PRIVACY: this model is persisted ONLY in a local encrypted Hive box.
/// It is never written to Firestore or any backend. See [JournalRepository].
class JournalEntry {
  final String id;
  final String body; // markdown text
  final MoodType? mood;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.body,
    this.mood,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  JournalEntry copyWith({
    String? id,
    String? body,
    MoodType? mood,
    bool clearMood = false,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      body: body ?? this.body,
      mood: clearMood ? null : (mood ?? this.mood),
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Plain-JSON serialization for the local Hive box (no Firestore Timestamp).
  Map<String, dynamic> toJson() => {
        'id': id,
        'body': body,
        'mood': mood?.index,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final moodIdx = json['mood'] as int?;
    return JournalEntry(
      id: json['id'] as String,
      body: json['body'] as String? ?? '',
      mood: (moodIdx != null && moodIdx >= 0 && moodIdx < MoodType.values.length)
          ? MoodType.values[moodIdx]
          : null,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
