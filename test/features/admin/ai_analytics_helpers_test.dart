// ignore_for_file: avoid_relative_lib_imports

/// Unit tests for pure-Dart helpers extracted from AiAnalyticsScreen:
///   - riskRank(String) -> int
///   - trendRank(String) -> int
///   - relativeTime(DateTime) -> String
///   - compareUsers(Map, Map) -> int
///
/// These functions must exist as top-level helpers in
/// lib/features/admin/screens/ai_analytics_screen.dart.
/// The tests drive their design and verify their correctness.

import 'package:flutter_test/flutter_test.dart';

// Import the helpers. They are declared top-level in ai_analytics_screen.dart.
import 'package:sanad_app/features/admin/screens/ai_analytics_screen.dart';

void main() {
  group('riskRank', () {
    test('critical maps to 4', () {
      expect(riskRank('critical'), 4);
    });

    test('high maps to 3', () {
      expect(riskRank('high'), 3);
    });

    test('moderate maps to 2', () {
      expect(riskRank('moderate'), 2);
    });

    test('low maps to 1', () {
      expect(riskRank('low'), 1);
    });

    test('unknown maps to 0', () {
      expect(riskRank('unknown'), 0);
    });

    test('case-insensitive', () {
      expect(riskRank('CRITICAL'), 4);
      expect(riskRank('High'), 3);
    });
  });

  group('trendRank', () {
    test('declining maps to 2', () {
      expect(trendRank('declining'), 2);
    });

    test('stable maps to 1', () {
      expect(trendRank('stable'), 1);
    });

    test('improving maps to 0', () {
      expect(trendRank('improving'), 0);
    });

    test('unknown maps to 0', () {
      expect(trendRank('unknown_value'), 0);
    });
  });

  group('relativeTime', () {
    test('returns "Just now" for time within 60 seconds', () {
      final now = DateTime.now();
      expect(relativeTime(now.subtract(const Duration(seconds: 30))), 'Just now');
    });

    test('returns minutes ago for time under 1 hour', () {
      final now = DateTime.now();
      final result = relativeTime(now.subtract(const Duration(minutes: 45)));
      expect(result, '45 min ago');
    });

    test('returns hours ago for time under 24 hours', () {
      final now = DateTime.now();
      final result = relativeTime(now.subtract(const Duration(hours: 3)));
      expect(result, '3 hours ago');
    });

    test('returns days ago for time over 24 hours', () {
      final now = DateTime.now();
      final result = relativeTime(now.subtract(const Duration(days: 2)));
      expect(result, '2 days ago');
    });

    test('returns 1 day ago for 1 day', () {
      final now = DateTime.now();
      final result = relativeTime(now.subtract(const Duration(days: 1)));
      expect(result, '1 day ago');
    });
  });

  group('compareUsers sort order', () {
    final critical = {'riskLevel': 'critical', 'trend': 'improving'};
    final highDeclining = {'riskLevel': 'high', 'trend': 'declining'};
    final highStable = {'riskLevel': 'high', 'trend': 'stable'};
    final low = {'riskLevel': 'low', 'trend': 'improving'};

    test('critical sorts before high', () {
      expect(compareUsers(critical, highDeclining), lessThan(0));
    });

    test('high sorts before low', () {
      expect(compareUsers(highStable, low), lessThan(0));
    });

    test('same risk: declining sorts before stable', () {
      expect(compareUsers(highDeclining, highStable), lessThan(0));
    });

    test('same risk and trend: equal', () {
      expect(compareUsers(highDeclining, highDeclining), 0);
    });
  });
}
