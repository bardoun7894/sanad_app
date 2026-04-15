import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sanad_app/features/mood/models/mood_entry.dart';
import 'package:sanad_app/features/mood/models/mood_enums.dart';

void main() {
  final now = DateTime(2026, 2, 15, 10, 30);

  group('MoodEntry', () {
    test('creates with required fields', () {
      final entry = MoodEntry(id: 'mood-1', mood: MoodType.happy, date: now);

      expect(entry.id, 'mood-1');
      expect(entry.mood, MoodType.happy);
      expect(entry.date, now);
      expect(entry.note, isNull);
    });

    test('creates with optional note', () {
      final entry = MoodEntry(
        id: 'mood-1',
        mood: MoodType.sad,
        date: now,
        note: 'Feeling down today',
      );

      expect(entry.note, 'Feeling down today');
    });

    test('copyWith creates updated copy', () {
      final entry = MoodEntry(id: 'mood-1', mood: MoodType.happy, date: now);

      final updated = entry.copyWith(
        mood: MoodType.calm,
        note: 'Feeling better',
      );

      expect(updated.mood, MoodType.calm);
      expect(updated.note, 'Feeling better');
      expect(updated.id, 'mood-1');
      expect(updated.date, now);
      expect(entry.mood, MoodType.happy);
    });

    test('toMap serializes correctly', () {
      final entry = MoodEntry(
        id: 'mood-1',
        mood: MoodType.anxious,
        date: now,
        note: 'Test note',
      );

      final map = entry.toMap();

      expect(map['mood'], MoodType.anxious.index);
      expect(map['date'], isA<Timestamp>());
      expect(map['note'], 'Test note');
    });

    test('toMap excludes null note', () {
      final entry = MoodEntry(id: 'mood-1', mood: MoodType.happy, date: now);

      final map = entry.toMap();
      expect(map['note'], isNull);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'mood': MoodType.sad.index,
        'date': Timestamp.fromDate(now),
        'note': 'Test note',
      };

      final entry = MoodEntry.fromMap(map, 'mood-1');

      expect(entry.id, 'mood-1');
      expect(entry.mood, MoodType.sad);
      expect(entry.note, 'Test note');
    });

    test('toJson and fromJson roundtrip', () {
      final entry = MoodEntry(
        id: 'mood-1',
        mood: MoodType.angry,
        date: now,
        note: 'Angry note',
      );

      final json = entry.toJson();
      final restored = MoodEntry.fromJson(json);

      expect(restored.id, entry.id);
      expect(restored.mood, entry.mood);
      expect(restored.date.toIso8601String(), entry.date.toIso8601String());
      expect(restored.note, entry.note);
    });
  });

  group('MoodType', () {
    test('has expected values', () {
      expect(MoodType.values.length, 6);
      expect(MoodType.happy.name, 'happy');
      expect(MoodType.calm.name, 'calm');
      expect(MoodType.anxious.name, 'anxious');
      expect(MoodType.sad.name, 'sad');
      expect(MoodType.angry.name, 'angry');
      expect(MoodType.tired.name, 'tired');
    });
  });

  group('MoodMetadata', () {
    test('getEmoji returns correct emoji for each mood', () {
      expect(MoodMetadata.getEmoji(MoodType.happy), '😊');
      expect(MoodMetadata.getEmoji(MoodType.calm), '😌');
      expect(MoodMetadata.getEmoji(MoodType.anxious), '😨');
      expect(MoodMetadata.getEmoji(MoodType.sad), '😢');
      expect(MoodMetadata.getEmoji(MoodType.angry), '😠');
      expect(MoodMetadata.getEmoji(MoodType.tired), '😴');
    });

    test('getLabel returns English default label', () {
      expect(MoodMetadata.getLabel(MoodType.happy), 'Happy');
      expect(MoodMetadata.getLabel(MoodType.calm), 'Calm');
      expect(MoodMetadata.getLabel(MoodType.anxious), 'Anxious');
      expect(MoodMetadata.getLabel(MoodType.sad), 'Sad');
      expect(MoodMetadata.getLabel(MoodType.angry), 'Angry');
      expect(MoodMetadata.getLabel(MoodType.tired), 'Tired');
    });

    test('getMoodScore returns correct scores', () {
      expect(MoodMetadata.getMoodScore(MoodType.happy), 5);
      expect(MoodMetadata.getMoodScore(MoodType.calm), 4);
      expect(MoodMetadata.getMoodScore(MoodType.tired), 2);
      expect(MoodMetadata.getMoodScore(MoodType.anxious), 2);
      expect(MoodMetadata.getMoodScore(MoodType.sad), 1);
      expect(MoodMetadata.getMoodScore(MoodType.angry), 1);
    });
  });
}
