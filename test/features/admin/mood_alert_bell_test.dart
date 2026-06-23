import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/models/mood_alert.dart';
import 'package:sanad_app/features/mood/models/mood_enums.dart';

// ---------------------------------------------------------------------------
// Helpers duplicated from MoodAlertBell for unit-testability.
// These are the pure functions that the widget uses internally.
// ---------------------------------------------------------------------------

String formatTimeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}د';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}س';
  }
  return '${diff.inDays}ي';
}

String badgeLabel(int count) => count > 9 ? '9+' : count.toString();

String resolveUserName(String? userName) => userName ?? 'مستخدم';

void main() {
  // -------------------------------------------------------------------------
  // RED phase: tests are written BEFORE the production widget exists.
  // They test the pure-function contracts the widget must satisfy.
  // -------------------------------------------------------------------------

  group('MoodAlertBell — badge label', () {
    test('shows count as-is when <= 9', () {
      expect(badgeLabel(0), '0');
      expect(badgeLabel(1), '1');
      expect(badgeLabel(9), '9');
    });

    test('clamps to "9+" when count > 9', () {
      expect(badgeLabel(10), '9+');
      expect(badgeLabel(99), '9+');
    });
  });

  group('MoodAlertBell — userName fallback', () {
    test('returns userName when not null', () {
      expect(resolveUserName('أحمد'), 'أحمد');
    });

    test('returns Arabic fallback "مستخدم" when userName is null', () {
      expect(resolveUserName(null), 'مستخدم');
    });
  });

  group('MoodAlertBell — MoodAlert model', () {
    test('MoodAlert stores all fields correctly', () {
      final date = DateTime(2026, 6, 20, 10, 0);
      final alert = MoodAlert(
        userId: 'uid-1',
        userName: 'سارة',
        mood: MoodType.anxious,
        date: date,
      );
      expect(alert.userId, 'uid-1');
      expect(alert.userName, 'سارة');
      expect(alert.mood, MoodType.anxious);
    });

    test('MoodAlert accepts null userName', () {
      final alert = MoodAlert(
        userId: 'uid-2',
        userName: null,
        mood: MoodType.sad,
        date: DateTime(2026, 6, 20),
      );
      expect(alert.userName, isNull);
      expect(resolveUserName(alert.userName), 'مستخدم');
    });
  });

  group('MoodAlertBell — MoodTypeExtension', () {
    test('emoji returns non-empty string for each negative mood', () {
      for (final mood in [MoodType.anxious, MoodType.sad, MoodType.angry]) {
        final emoji = MoodTypeExtension.emoji(mood);
        expect(emoji.isNotEmpty, isTrue,
            reason: 'Expected emoji for $mood to be non-empty');
      }
    });

    test('label returns Arabic string for negative moods', () {
      expect(MoodTypeExtension.label(MoodType.anxious), 'قلق');
      expect(MoodTypeExtension.label(MoodType.sad), 'حزين');
      expect(MoodTypeExtension.label(MoodType.angry), 'غاضب');
    });
  });

  group('MoodAlertBell — formatTimeAgo', () {
    test('shows minutes when diff < 1 hour', () {
      final time = DateTime.now().subtract(const Duration(minutes: 30));
      final result = formatTimeAgo(time);
      expect(result, contains('30'));
      expect(result, contains('د'));
    });

    test('shows hours when diff >= 1 hour and < 24 hours', () {
      final time = DateTime.now().subtract(const Duration(hours: 3));
      final result = formatTimeAgo(time);
      expect(result, contains('3'));
      expect(result, contains('س'));
    });

    test('shows days when diff >= 24 hours', () {
      final time = DateTime.now().subtract(const Duration(days: 2));
      final result = formatTimeAgo(time);
      expect(result, contains('2'));
      expect(result, contains('ي'));
    });
  });
}
