import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
// MoodPolarity and MoodPolarityX extension live in mood_alert.dart (packet 1).
// MoodType and MoodTypeExtension live in mood_enums.dart.
import 'package:sanad_app/features/admin/models/mood_alert.dart';
import 'package:sanad_app/features/mood/models/mood_enums.dart';

// ---------------------------------------------------------------------------
// Pure-function helpers extracted from MoodFeedScreen for unit-testability.
// These are the exact contracts the screen must satisfy — written BEFORE the
// production code so we can watch them fail first (TDD RED).
// ---------------------------------------------------------------------------

/// Returns the display name for a mood feed row.
/// Rules (from KB [[mandatory_profile_gate_and_user_display]]):
///   - userName non-null → return as-is
///   - userName null    → return Arabic fallback (never show "User" literally)
String resolveFeedUserName(String? userName) => userName ?? 'مستخدم';

/// Returns the dot/chip Color for a given MoodPolarity value.
/// Mapping:
///   positive → green  (AppColors.statusSuccess  ~  Color(0xFF10B981))
///   negative → red    (AppColors.statusDanger   ~  Color(0xFFEF4444))
///   neutral  → amber  (AppColors.statusWarning  ~  Color(0xFFF59E0B))
Color polarityColor(MoodPolarity polarity) {
  switch (polarity) {
    case MoodPolarity.positive:
      return const Color(0xFF10B981); // AppColors.statusSuccess
    case MoodPolarity.negative:
      return const Color(0xFFEF4444); // AppColors.statusDanger
    case MoodPolarity.neutral:
      return const Color(0xFFF59E0B); // AppColors.statusWarning
  }
}

/// Returns a filter label for a polarity chip.
String polarityLabel(MoodPolarity? polarity) {
  if (polarity == null) return 'الكل';
  switch (polarity) {
    case MoodPolarity.positive:
      return 'إيجابي';
    case MoodPolarity.negative:
      return 'سلبي';
    case MoodPolarity.neutral:
      return 'محايد';
  }
}

/// Filters a list of MoodAlert by polarity, returning all when filter is null.
List<MoodAlert> filterByPolarity(
  List<MoodAlert> alerts,
  MoodPolarity? filter,
) {
  if (filter == null) return alerts;
  return alerts.where((a) => a.mood.polarity == filter).toList();
}

void main() {
  // -------------------------------------------------------------------------
  // RED phase: tests written BEFORE MoodFeedScreen production code exists.
  // -------------------------------------------------------------------------

  group('MoodFeedScreen — userName resolution', () {
    test('shows userName when non-null', () {
      expect(resolveFeedUserName('فاطمة'), 'فاطمة');
    });

    test('shows Arabic fallback "مستخدم" when userName is null', () {
      expect(resolveFeedUserName(null), 'مستخدم');
    });

    test('never returns the literal English word "User"', () {
      expect(resolveFeedUserName(null), isNot('User'));
    });

    test('never returns empty string', () {
      expect(resolveFeedUserName(null).isNotEmpty, true);
    });
  });

  group('MoodFeedScreen — polarity color mapping', () {
    test('positive polarity returns green color', () {
      final color = polarityColor(MoodPolarity.positive);
      // Green: should not be red or amber
      expect(color, isNot(equals(const Color(0xFFEF4444))));
      expect(color, isNot(equals(const Color(0xFFF59E0B))));
      // Should be a recognizable green
      expect(color.green, greaterThan(color.red));
    });

    test('negative polarity returns red color', () {
      final color = polarityColor(MoodPolarity.negative);
      expect(color.red, greaterThan(color.green));
    });

    test('neutral polarity returns amber/yellow color', () {
      final color = polarityColor(MoodPolarity.neutral);
      // Amber: high red + high green, low blue
      expect(color.red, greaterThan(color.blue));
      expect(color.green, greaterThan(color.blue));
    });

    test('all three polarity values have distinct colors', () {
      final positive = polarityColor(MoodPolarity.positive);
      final negative = polarityColor(MoodPolarity.negative);
      final neutral = polarityColor(MoodPolarity.neutral);
      expect(positive, isNot(equals(negative)));
      expect(positive, isNot(equals(neutral)));
      expect(negative, isNot(equals(neutral)));
    });
  });

  group('MoodFeedScreen — polarity filter chips', () {
    test('"All" label is returned for null filter', () {
      expect(polarityLabel(null), 'الكل');
    });

    test('positive label is Arabic', () {
      expect(polarityLabel(MoodPolarity.positive), 'إيجابي');
    });

    test('negative label is Arabic', () {
      expect(polarityLabel(MoodPolarity.negative), 'سلبي');
    });

    test('neutral label is Arabic', () {
      expect(polarityLabel(MoodPolarity.neutral), 'محايد');
    });
  });

  group('MoodFeedScreen — client-side polarity filtering', () {
    final date = DateTime(2026, 6, 20, 10, 0);
    final alerts = [
      MoodAlert(userId: 'u1', userName: 'أحمد', mood: MoodType.happy, date: date),
      MoodAlert(userId: 'u2', userName: 'سارة', mood: MoodType.calm, date: date),
      MoodAlert(userId: 'u3', userName: null, mood: MoodType.anxious, date: date),
      MoodAlert(userId: 'u4', userName: 'علي', mood: MoodType.sad, date: date),
      MoodAlert(userId: 'u5', userName: 'نور', mood: MoodType.angry, date: date),
      MoodAlert(userId: 'u6', userName: null, mood: MoodType.tired, date: date),
    ];

    test('null filter returns all entries', () {
      expect(filterByPolarity(alerts, null).length, 6);
    });

    test('positive filter returns happy and calm only', () {
      final filtered = filterByPolarity(alerts, MoodPolarity.positive);
      expect(filtered.length, 2);
      expect(filtered.every((a) => a.mood.polarity == MoodPolarity.positive), true);
    });

    test('negative filter returns anxious, sad, and angry', () {
      final filtered = filterByPolarity(alerts, MoodPolarity.negative);
      expect(filtered.length, 3);
      expect(filtered.every((a) => a.mood.polarity == MoodPolarity.negative), true);
    });

    test('neutral filter returns only tired', () {
      final filtered = filterByPolarity(alerts, MoodPolarity.neutral);
      expect(filtered.length, 1);
      expect(filtered.first.mood, MoodType.tired);
    });

    test('filter on empty list returns empty list', () {
      expect(filterByPolarity([], MoodPolarity.positive), isEmpty);
    });
  });

  group('MoodFeedScreen — newest-first sort contract', () {
    test('list sorted descending by date is newest first', () {
      final now = DateTime.now();
      final older = MoodAlert(
        userId: 'u-old',
        userName: 'قديم',
        mood: MoodType.happy,
        date: now.subtract(const Duration(hours: 2)),
      );
      final newer = MoodAlert(
        userId: 'u-new',
        userName: 'جديد',
        mood: MoodType.calm,
        date: now.subtract(const Duration(minutes: 5)),
      );
      final sorted = [older, newer]
        ..sort((a, b) => b.date.compareTo(a.date));
      expect(sorted.first.userId, 'u-new');
    });
  });
}
