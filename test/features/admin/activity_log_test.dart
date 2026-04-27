import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/models/activity_log.dart';

void main() {
  group('ActivityType enum', () {
    test('therapistRejected value exists', () {
      // This test will FAIL until we add therapistRejected to the enum
      expect(
        ActivityType.values.any((t) => t.name == 'therapistRejected'),
        isTrue,
        reason:
            'ActivityType.therapistRejected must exist for correct rejection logging',
      );
    });

    test('ActivityType has expected number of values including therapistRejected', () {
      // Currently 12 values; after adding therapistRejected it should be 13
      expect(
        ActivityType.values.length,
        greaterThanOrEqualTo(13),
        reason: 'ActivityType should have at least 13 values after adding therapistRejected',
      );
    });
  });

  group('ActivityLog icon getter', () {
    DateTime now = DateTime(2026, 1, 1);

    ActivityLog makeLog(ActivityType type) => ActivityLog(
          id: 'test-id',
          type: type,
          userId: 'uid-1',
          userName: 'Admin',
          description: 'test',
          timestamp: now,
        );

    test('therapistApproved has an icon', () {
      final log = makeLog(ActivityType.therapistApproved);
      expect(log.icon, isNotNull);
    });

    test('all ActivityType values have icons defined (no missing switch case)', () {
      // This ensures the switch in ActivityLog.icon is exhaustive after
      // adding therapistRejected
      for (final type in ActivityType.values) {
        final log = makeLog(type);
        expect(log.icon, isNotNull, reason: 'Missing icon for $type');
      }
    });
  });
}
