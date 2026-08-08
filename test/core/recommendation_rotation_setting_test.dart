import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/providers/system_settings_provider.dart';

void main() {
  group('recommendation_rotation_minutes', () {
    test('defaults to 10 minutes when the field is absent', () {
      expect(
        SystemSettings.fromMap(const {}).recommendationRotationMinutes,
        10,
      );
    });

    test('reads the admin-configured value', () {
      expect(
        SystemSettings.fromMap(const {'recommendation_rotation_minutes': 30})
            .recommendationRotationMinutes,
        30,
      );
    });

    test('accepts a double from Firestore', () {
      // Firestore hands back num; a value written as 60.0 must not throw.
      expect(
        SystemSettings.fromMap(const {'recommendation_rotation_minutes': 60.0})
            .recommendationRotationMinutes,
        60,
      );
    });

    test('clamps a too-small value so the row cannot churn every frame', () {
      expect(
        SystemSettings.fromMap(const {'recommendation_rotation_minutes': 0})
            .recommendationRotationMinutes,
        SystemSettings.kMinRotationMinutes,
      );
      expect(
        SystemSettings.fromMap(const {'recommendation_rotation_minutes': -5})
            .recommendationRotationMinutes,
        SystemSettings.kMinRotationMinutes,
      );
    });

    test('clamps a too-large value so the row cannot freeze for a year', () {
      expect(
        SystemSettings.fromMap(
          const {'recommendation_rotation_minutes': 999999},
        ).recommendationRotationMinutes,
        SystemSettings.kMaxRotationMinutes,
      );
    });

    test('survives a round trip through toMap', () {
      const settings = SystemSettings(recommendationRotationMinutes: 360);
      expect(
        SystemSettings.fromMap(settings.toMap())
            .recommendationRotationMinutes,
        360,
      );
    });
  });
}
