import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/content/models/psychological_test.dart';
import 'package:sanad_app/features/admin/providers/psych_tests_admin_provider.dart';

void main() {
  group('psychTestToMap round-trip', () {
    final testQuestion = const TestQuestion(
      text: 'هل تشعر بالقلق؟',
      textEn: 'Do you feel anxious?',
      options: [
        TestOption(text: 'أبدا', textEn: 'Never', score: 0),
        TestOption(text: 'أحيانا', textEn: 'Sometimes', score: 1),
        TestOption(text: 'دائما', textEn: 'Always', score: 3),
      ],
    );

    final testRange = const ScoringRange(
      min: 0,
      max: 7,
      level: 'minimal',
      text: 'لا توجد أعراض',
      textEn: 'No symptoms',
    );

    final sampleTest = PsychologicalTest(
      id: 'test-id-123',
      title: 'اختبار القلق',
      titleEn: 'Anxiety Test',
      description: 'وصف الاختبار',
      descriptionEn: 'Test description',
      type: 'anxiety',
      durationMinutes: 10,
      isActive: true,
      questions: [testQuestion],
      scoringRanges: [testRange],
    );

    test('psychTestToMap produces correct top-level keys', () {
      final map = psychTestToMap(sampleTest);

      expect(map['title'], equals('اختبار القلق'));
      expect(map['title_en'], equals('Anxiety Test'));
      expect(map['description'], equals('وصف الاختبار'));
      expect(map['description_en'], equals('Test description'));
      expect(map['type'], equals('anxiety'));
      expect(map['duration_minutes'], equals(10));
      expect(map['is_active'], isTrue);
    });

    test('psychTestToMap nests scoring ranges under scoring.ranges', () {
      final map = psychTestToMap(sampleTest);

      expect(map.containsKey('scoring'), isTrue,
          reason: 'scoring must be a nested map, not scoring_ranges at top level');
      final scoring = map['scoring'] as Map<String, dynamic>;
      expect(scoring.containsKey('ranges'), isTrue);
      final ranges = scoring['ranges'] as List;
      expect(ranges.length, equals(1));
      final range = ranges[0] as Map<String, dynamic>;
      expect(range['min'], equals(0));
      expect(range['max'], equals(7));
      expect(range['level'], equals('minimal'));
      expect(range['text'], equals('لا توجد أعراض'));
      expect(range['text_en'], equals('No symptoms'));
    });

    test('psychTestToMap round-trips via fromJson', () {
      final map = psychTestToMap(sampleTest);
      // Add id so fromJson can read it
      map['id'] = sampleTest.id;

      final restored = PsychologicalTest.fromJson(map);

      expect(restored.title, equals(sampleTest.title));
      expect(restored.titleEn, equals(sampleTest.titleEn));
      expect(restored.type, equals(sampleTest.type));
      expect(restored.durationMinutes, equals(sampleTest.durationMinutes));
      expect(restored.isActive, equals(sampleTest.isActive));
      expect(restored.scoringRanges.length, equals(1));
      expect(restored.scoringRanges[0].level, equals('minimal'));
      expect(restored.questions.length, equals(1));
      expect(restored.questions[0].options.length, equals(3));
      expect(restored.questions[0].options[2].score, equals(3));
    });

    test('psychTestToMap does NOT include is_premium key', () {
      final map = psychTestToMap(sampleTest);
      expect(map.containsKey('is_premium'), isFalse,
          reason: 'PsychologicalTest has no isPremium field');
    });

    test('psychTestToMap does NOT include top-level scoring_ranges key', () {
      final map = psychTestToMap(sampleTest);
      expect(map.containsKey('scoring_ranges'), isFalse,
          reason: 'Scoring ranges must be nested under scoring.ranges');
    });
  });

  group('psychTestValidate', () {
    test('returns error when title is empty', () {
      final error = psychTestValidate(
        title: '',
        questionCount: 2,
        rangeCount: 1,
      );
      expect(error, isNotNull);
      expect(error, contains('title'));
    });

    test('returns error when no questions', () {
      final error = psychTestValidate(
        title: 'Test',
        questionCount: 0,
        rangeCount: 1,
      );
      expect(error, isNotNull);
      expect(error, contains('question'));
    });

    test('returns error when no scoring ranges', () {
      final error = psychTestValidate(
        title: 'Test',
        questionCount: 1,
        rangeCount: 0,
      );
      expect(error, isNotNull);
      expect(error, contains('range'));
    });

    test('returns null when all valid', () {
      final error = psychTestValidate(
        title: 'Test',
        questionCount: 1,
        rangeCount: 1,
      );
      expect(error, isNull);
    });
  });
}
