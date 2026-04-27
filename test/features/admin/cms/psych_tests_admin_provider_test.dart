import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/content/models/psychological_test.dart';
import 'package:sanad_app/features/admin/providers/psych_tests_admin_provider.dart';

void main() {
  group('psychTestToMap round-trip', () {
    final testData = PsychologicalTest(
      id: 'test-1',
      title: 'اختبار القلق',
      titleEn: 'Anxiety Test',
      description: 'وصف الاختبار',
      descriptionEn: 'Test description',
      type: 'anxiety',
      durationMinutes: 10,
      isActive: true,
      questions: [
        const TestQuestion(
          text: 'كيف حالك؟',
          textEn: 'How are you?',
          options: [
            TestOption(text: 'جيد', textEn: 'Good', score: 0),
            TestOption(text: 'سيء', textEn: 'Bad', score: 3),
          ],
        ),
      ],
      scoringRanges: [
        const ScoringRange(
          min: 0,
          max: 9,
          level: 'minimal',
          text: 'طبيعي',
          textEn: 'Normal',
        ),
      ],
    );

    test('toMap produces nested scoring.ranges structure', () {
      final map = psychTestToMap(testData);

      // Scoring must be nested, not flat
      expect(map.containsKey('scoring'), isTrue,
          reason: 'Must use nested scoring: {ranges: [...]}');
      expect(map.containsKey('scoring_ranges'), isFalse,
          reason: 'Must NOT use flat scoring_ranges key');

      final scoring = map['scoring'] as Map<String, dynamic>;
      expect(scoring.containsKey('ranges'), isTrue);
      final ranges = scoring['ranges'] as List;
      expect(ranges, hasLength(1));
    });

    test('toMap includes all required fields for PsychologicalTest', () {
      final map = psychTestToMap(testData);

      expect(map['title'], equals('اختبار القلق'));
      expect(map['title_en'], equals('Anxiety Test'));
      expect(map['description'], equals('وصف الاختبار'));
      expect(map['description_en'], equals('Test description'));
      expect(map['type'], equals('anxiety'));
      expect(map['duration_minutes'], equals(10));
      expect(map['is_active'], isTrue);
    });

    test('toMap questions include options with scores', () {
      final map = psychTestToMap(testData);
      final questions = map['questions'] as List;
      expect(questions, hasLength(1));

      final q = questions[0] as Map<String, dynamic>;
      expect(q['text'], equals('كيف حالك؟'));
      expect(q['text_en'], equals('How are you?'));

      final options = q['options'] as List;
      expect(options, hasLength(2));
      expect((options[1] as Map<String, dynamic>)['score'], equals(3));
    });

    test('fromJson round-trip: toMap output can be deserialized back', () {
      final map = psychTestToMap(testData);
      // fromJson needs an id, inject it
      map['id'] = testData.id;

      final restored = PsychologicalTest.fromJson(map);

      expect(restored.title, equals(testData.title));
      expect(restored.titleEn, equals(testData.titleEn));
      expect(restored.type, equals(testData.type));
      expect(restored.durationMinutes, equals(testData.durationMinutes));
      expect(restored.isActive, equals(testData.isActive));
      expect(restored.scoringRanges, hasLength(1));
      expect(restored.scoringRanges.first.level, equals('minimal'));
      expect(restored.questions, hasLength(1));
      expect(restored.questions.first.options, hasLength(2));
    });
  });
}
