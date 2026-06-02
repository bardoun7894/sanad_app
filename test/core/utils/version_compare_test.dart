import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/utils/version_compare.dart';

void main() {
  group('compareSemver', () {
    test('equal versions return 0', () {
      expect(compareSemver('1.0.0', '1.0.0'), 0);
    });

    test('greater version returns 1', () {
      expect(compareSemver('1.2.0', '1.0.0'), 1);
    });

    test('lesser version returns -1', () {
      expect(compareSemver('0.9.0', '1.0.0'), -1);
    });

    test('missing segments treated as 0 (1.2 == 1.2.0)', () {
      expect(compareSemver('1.2', '1.2.0'), 0);
    });

    test('build suffix stripped before compare (1.0.0+17 == 1.0.0)', () {
      expect(compareSemver('1.0.0+17', '1.0.0'), 0);
    });

    test('pre-release suffix stripped before compare (1.2.3-beta == 1.2.3)', () {
      expect(compareSemver('1.2.3-beta', '1.2.3'), 0);
    });

    test('double-digit patch segment: 1.2.10 > 1.2.9', () {
      expect(compareSemver('1.2.10', '1.2.9'), 1);
    });

    test('double-digit minor segment: 1.10.0 > 1.9.0', () {
      expect(compareSemver('1.10.0', '1.9.0'), 1);
    });
  });

  group('isVersionBelow', () {
    test('current < minimum returns true', () {
      expect(isVersionBelow('1.0.0', '2.0.0'), isTrue);
    });

    test('current == minimum returns false', () {
      expect(isVersionBelow('1.0.0', '1.0.0'), isFalse);
    });

    test('current > minimum returns false', () {
      expect(isVersionBelow('2.0.0', '1.0.0'), isFalse);
    });

    test('current with build suffix below minimum', () {
      expect(isVersionBelow('1.0.0+17', '1.1.0'), isTrue);
    });

    test('short form 1.2 is not below 1.2.0', () {
      expect(isVersionBelow('1.2', '1.2.0'), isFalse);
    });
  });
}
