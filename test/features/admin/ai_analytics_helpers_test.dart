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

  // ── Client's Jul 22 asks: date range, mood filter, sort ──────────────────

  Map<String, dynamic> u({
    String? mood,
    String? lastMoodAt,
    int entries = 0,
    String risk = 'low',
  }) => {
        'userId': 'u',
        'dominantMood': mood,
        'lastMoodAt': lastMoodAt,
        'totalMoodEntries': entries,
        'riskLevel': risk,
      };

  group('applyMoodFilter', () {
    test('All keeps everything', () {
      final rows = [u(mood: 'happy'), u(mood: 'anxious')];
      expect(applyMoodFilter(rows, 'All').length, 2);
    });

    test('matches one mood, case-insensitively', () {
      final rows = [u(mood: 'Happy'), u(mood: 'anxious')];
      expect(applyMoodFilter(rows, 'happy').length, 1);
    });

    test('users with no recorded mood are excluded by a specific filter', () {
      final rows = [u(mood: null), u(mood: 'happy')];
      expect(applyMoodFilter(rows, 'happy').length, 1);
    });
  });

  group('applyDateRange on lastMoodAt', () {
    final jan = DateTime.utc(2026, 1, 15);
    final feb = DateTime.utc(2026, 2, 15);
    final mar = DateTime.utc(2026, 3, 15);
    List<Map<String, dynamic>> rows() => [
          u(lastMoodAt: jan.toIso8601String()),
          u(lastMoodAt: feb.toIso8601String()),
          u(lastMoodAt: mar.toIso8601String()),
        ];

    test('null bounds keep everything', () {
      expect(applyDateRange(rows(), null, null).length, 3);
    });

    test('from alone keeps that date onward', () {
      expect(applyDateRange(rows(), feb, null).length, 2);
    });

    test('to alone keeps up to that date', () {
      expect(applyDateRange(rows(), null, feb).length, 2);
    });

    test('both bounds keep the middle', () {
      expect(applyDateRange(rows(), feb, feb).length, 1);
    });

    test('the whole "to" day counts, not just midnight', () {
      final rows = [u(lastMoodAt: DateTime.utc(2026, 2, 15, 23, 30).toIso8601String())];
      expect(applyDateRange(rows, null, DateTime.utc(2026, 2, 15)).length, 1);
    });

    test('users who never logged a mood drop out once a range is set', () {
      final rows = [u(lastMoodAt: null)];
      expect(applyDateRange(rows, feb, null), isEmpty);
      expect(applyDateRange(rows, null, null).length, 1);
    });
  });

  group('sortUsersBy', () {
    test('entries sorts by totalMoodEntries descending', () {
      final rows = [u(entries: 3), u(entries: 90), u(entries: 12)];
      final out = sortUsersBy(rows, AiUserSort.entries);
      expect(out.map((e) => e['totalMoodEntries']), [90, 12, 3]);
    });

    test('recent sorts by lastMoodAt, newest first', () {
      final rows = [
        u(lastMoodAt: DateTime.utc(2026, 1, 1).toIso8601String()),
        u(lastMoodAt: DateTime.utc(2026, 3, 1).toIso8601String()),
        u(lastMoodAt: DateTime.utc(2026, 2, 1).toIso8601String()),
      ];
      final out = sortUsersBy(rows, AiUserSort.recent);
      expect(out.first['lastMoodAt'], contains('2026-03-01'));
      expect(out.last['lastMoodAt'], contains('2026-01-01'));
    });

    test('users who never logged sort last, not first', () {
      final rows = [
        u(lastMoodAt: null),
        u(lastMoodAt: DateTime.utc(2026, 1, 1).toIso8601String()),
      ];
      expect(sortUsersBy(rows, AiUserSort.recent).last['lastMoodAt'], isNull);
    });

    test('risk keeps the original risk-then-trend order', () {
      final rows = [u(risk: 'low'), u(risk: 'critical'), u(risk: 'high')];
      final out = sortUsersBy(rows, AiUserSort.risk);
      expect(out.map((e) => e['riskLevel']), ['critical', 'high', 'low']);
    });

    test('does not mutate the input list', () {
      final rows = [u(entries: 1), u(entries: 5)];
      sortUsersBy(rows, AiUserSort.entries);
      expect(rows.first['totalMoodEntries'], 1);
    });
  });

  group('mergeUserPages', () {
    // "Show more" appended without de-duplicating, so a repeated or
    // overlapping page put the same person in the table twice.
    test('appends new users', () {
      final a = [{'userId': '1'}, {'userId': '2'}];
      final b = [{'userId': '3'}];
      expect(mergeUserPages(a, b).length, 3);
    });

    test('a repeated page does not duplicate rows', () {
      final a = [{'userId': '1'}, {'userId': '2'}];
      expect(mergeUserPages(a, a).length, 2);
    });

    test('the later copy wins so refreshed data is not discarded', () {
      final a = [{'userId': '1', 'totalMoodEntries': 1}];
      final b = [{'userId': '1', 'totalMoodEntries': 9}];
      expect(mergeUserPages(a, b).single['totalMoodEntries'], 9);
    });
  });
}
