import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/crisis/models/crisis_keywords.dart';

void main() {
  group('CrisisKeywords.analyze', () {
    group('Tier 1 - Critical keywords (instant block)', () {
      test('detects Arabic suicide keyword', () {
        final result = CrisisKeywords.analyze('أريد الموت');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'critical');
        expect(result.matchedKeywords, contains('أريد الموت'));
        expect(result.detectedLanguage, 'ar');
      });

      test('detects English suicide keywords', () {
        final result = CrisisKeywords.analyze('I want to kill myself');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'critical');
        expect(result.matchedKeywords, contains('kill myself'));
      });

      test('detects French suicide keywords', () {
        final result = CrisisKeywords.analyze('je veux me tuer');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'critical');
        expect(result.matchedKeywords, contains('me tuer'));
      });

      test('detects self-harm keywords', () {
        final result = CrisisKeywords.analyze('I have been cutting myself');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'critical');
        expect(result.matchedKeywords, contains('cutting myself'));
      });

      test('detects overdose keywords', () {
        final result = CrisisKeywords.analyze('thinking about overdose');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'critical');
        expect(result.matchedKeywords, contains('overdose'));
      });

      test('is case insensitive', () {
        final result = CrisisKeywords.analyze('I want to KILL MYSELF');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'critical');
      });

      test('detects multiple keywords in one message', () {
        final result = CrisisKeywords.analyze('I want to end my life, suicide');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'critical');
        expect(result.matchedKeywords.length, greaterThanOrEqualTo(2));
      });
    });

    group('Tier 2 - High keywords (needs AI confirmation)', () {
      test('detects hopelessness in English', () {
        final result = CrisisKeywords.analyze('I feel hopeless');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'high');
        expect(result.matchedKeywords, contains('hopeless'));
      });

      test('detects Arabic distress phrases', () {
        final result = CrisisKeywords.analyze('لا فائدة من الحياة');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'high');
        expect(result.matchedKeywords, contains('لا فائدة من الحياة'));
      });

      test('detects French distress phrases', () {
        final result = CrisisKeywords.analyze('aucun espoir pour moi');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'high');
        expect(result.matchedKeywords, contains('aucun espoir'));
      });

      test('detects "can\'t take it anymore"', () {
        final result = CrisisKeywords.analyze("I can't take it anymore");
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'high');
      });

      test('detects "want to disappear"', () {
        final result = CrisisKeywords.analyze('I just want to disappear');
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'high');
      });
    });

    group('No crisis detected', () {
      test('normal greeting', () {
        final result = CrisisKeywords.analyze('Hello, how are you?');
        expect(result.isCrisis, isFalse);
        expect(result.severity, 'none');
        expect(result.matchedKeywords, isEmpty);
      });

      test('general sadness without crisis indicators', () {
        final result = CrisisKeywords.analyze('I feel sad today');
        expect(result.isCrisis, isFalse);
      });

      test('empty message', () {
        final result = CrisisKeywords.analyze('');
        expect(result.isCrisis, isFalse);
      });

      test('Arabic general conversation', () {
        final result = CrisisKeywords.analyze('أشعر بالتعب اليوم');
        expect(result.isCrisis, isFalse);
      });

      test('French general conversation', () {
        final result = CrisisKeywords.analyze('Je me sens triste');
        expect(result.isCrisis, isFalse);
      });
    });

    group('Priority: Critical over High', () {
      test('critical takes precedence when both match', () {
        final result = CrisisKeywords.analyze(
          'I want to kill myself, I feel hopeless',
        );
        expect(result.isCrisis, isTrue);
        expect(result.severity, 'critical');
      });
    });
  });
}
