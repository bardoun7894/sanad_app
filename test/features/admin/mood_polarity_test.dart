import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/models/mood_alert.dart';
import 'package:sanad_app/features/mood/models/mood_enums.dart';

void main() {
  // ---------------------------------------------------------------------------
  // RED phase: tests written BEFORE the polarity extension exists.
  // They verify the exact MoodPolarity enum values and the extension mapping.
  // ---------------------------------------------------------------------------

  group('MoodPolarity enum', () {
    test('enum has exactly three values: positive, negative, neutral', () {
      expect(MoodPolarity.values.length, 3);
      expect(MoodPolarity.values, containsAll([
        MoodPolarity.positive,
        MoodPolarity.negative,
        MoodPolarity.neutral,
      ]));
    });
  });

  group('MoodPolarityX extension — polarity getter', () {
    test('happy (index 0) is positive', () {
      expect(MoodType.happy.polarity, MoodPolarity.positive);
    });

    test('calm (index 1) is positive', () {
      expect(MoodType.calm.polarity, MoodPolarity.positive);
    });

    test('anxious (index 2) is negative', () {
      expect(MoodType.anxious.polarity, MoodPolarity.negative);
    });

    test('sad (index 3) is negative', () {
      expect(MoodType.sad.polarity, MoodPolarity.negative);
    });

    test('angry (index 4) is negative', () {
      expect(MoodType.angry.polarity, MoodPolarity.negative);
    });

    test('tired (index 5) is neutral', () {
      expect(MoodType.tired.polarity, MoodPolarity.neutral);
    });

    test('all MoodType values have a polarity (no exhaustive gaps)', () {
      // Verify every value maps without throwing
      for (final mood in MoodType.values) {
        expect(() => mood.polarity, returnsNormally,
            reason: '$mood should have a polarity');
      }
    });
  });

  group('MoodAlert — unchanged by polarity addition', () {
    // Confirm the existing MoodAlert model still functions correctly
    // after we add the polarity enum/extension to the same file.
    test('MoodAlert equality is preserved', () {
      final date = DateTime(2026, 6, 20, 10, 0);
      final a = MoodAlert(
        userId: 'uid-1',
        userName: 'أحمد',
        mood: MoodType.happy,
        date: date,
      );
      final b = MoodAlert(
        userId: 'uid-1',
        userName: 'أحمد',
        mood: MoodType.happy,
        date: date,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('MoodAlert is not equal when mood differs', () {
      final date = DateTime(2026, 6, 20);
      final a = MoodAlert(
          userId: 'uid-1',
          userName: null,
          mood: MoodType.happy,
          date: date);
      final b = MoodAlert(
          userId: 'uid-1',
          userName: null,
          mood: MoodType.calm,
          date: date);
      expect(a, isNot(equals(b)));
    });

    test('polarity can be read directly off a MoodAlert mood field', () {
      final alert = MoodAlert(
        userId: 'uid-1',
        userName: null,
        mood: MoodType.sad,
        date: DateTime(2026, 6, 20),
      );
      expect(alert.mood.polarity, MoodPolarity.negative);
    });
  });
}
