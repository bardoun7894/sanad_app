import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/content/models/psychological_test.dart';
import 'package:sanad_app/features/content/repositories/content_repository.dart';

PsychologicalTest _makeTest(String id, DateTime? createdAt) {
  return PsychologicalTest(
    id: id,
    title: id,
    titleEn: id,
    description: '',
    descriptionEn: '',
    type: 'anxiety',
    durationMinutes: 5,
    isActive: true,
    questions: const [],
    scoringRanges: const [],
    createdAt: createdAt,
  );
}

void main() {
  group('sortPsychTestsByCreatedAt', () {
    test('empty list returns empty list', () {
      final result = sortPsychTestsByCreatedAt([]);
      expect(result, isEmpty);
    });

    test('single test without timestamp is returned as-is', () {
      final test = _makeTest('a', null);
      final result = sortPsychTestsByCreatedAt([test]);
      expect(result.length, equals(1));
      expect(result[0].id, equals('a'));
    });

    test('single test with timestamp is returned as-is', () {
      final test = _makeTest('a', DateTime(2025, 1, 1));
      final result = sortPsychTestsByCreatedAt([test]);
      expect(result.length, equals(1));
      expect(result[0].id, equals('a'));
    });

    test('tests with timestamps are sorted newest-first', () {
      final older = _makeTest('older', DateTime(2024, 1, 1));
      final newer = _makeTest('newer', DateTime(2025, 6, 1));
      final middle = _makeTest('middle', DateTime(2024, 12, 1));

      final result = sortPsychTestsByCreatedAt([older, newer, middle]);

      expect(result[0].id, equals('newer'));
      expect(result[1].id, equals('middle'));
      expect(result[2].id, equals('older'));
    });

    test('tests without timestamps come after tests with timestamps', () {
      final withTs = _makeTest('withTs', DateTime(2024, 1, 1));
      final noTs1 = _makeTest('noTs1', null);
      final noTs2 = _makeTest('noTs2', null);

      final result = sortPsychTestsByCreatedAt([noTs1, withTs, noTs2]);

      expect(result[0].id, equals('withTs'));
      expect(result[1].id, equals('noTs1'));
      expect(result[2].id, equals('noTs2'));
    });

    test('tests without timestamps preserve original order (stability)', () {
      final noTs1 = _makeTest('GAD', null);
      final noTs2 = _makeTest('PHQ9', null);
      final noTs3 = _makeTest('STRESS', null);

      final result = sortPsychTestsByCreatedAt([noTs1, noTs2, noTs3]);

      expect(result[0].id, equals('GAD'));
      expect(result[1].id, equals('PHQ9'));
      expect(result[2].id, equals('STRESS'));
    });

    test('mix of timestamped and non-timestamped: timestamped sorted newest-first, non-timestamped last in original order', () {
      final oldest = _makeTest('oldest', DateTime(2023, 1, 1));
      final noTs1 = _makeTest('GAD', null);
      final newest = _makeTest('newest', DateTime(2026, 1, 1));
      final noTs2 = _makeTest('PHQ9', null);
      final middle = _makeTest('middle', DateTime(2024, 6, 1));

      final result =
          sortPsychTestsByCreatedAt([oldest, noTs1, newest, noTs2, middle]);

      // Timestamped: newest first
      expect(result[0].id, equals('newest'));
      expect(result[1].id, equals('middle'));
      expect(result[2].id, equals('oldest'));
      // Non-timestamped: original order preserved
      expect(result[3].id, equals('GAD'));
      expect(result[4].id, equals('PHQ9'));
    });

    test('all tests without timestamps preserves original order', () {
      final tests = [
        _makeTest('GAD', null),
        _makeTest('depression', null),
        _makeTest('stress', null),
      ];

      final result = sortPsychTestsByCreatedAt(tests);

      expect(result[0].id, equals('GAD'));
      expect(result[1].id, equals('depression'));
      expect(result[2].id, equals('stress'));
    });
  });
}
