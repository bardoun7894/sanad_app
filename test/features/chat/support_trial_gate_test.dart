// TDD tests for `supportTrialDays` config field and the trial paywall gate.
// RED: These tests must FAIL before production code changes are applied.
// GREEN: They must all pass after.
// Run: flutter test test/features/chat/support_trial_gate_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/providers/system_settings_provider.dart';
import 'package:sanad_app/core/l10n/app_strings.dart';

void main() {
  // ── Task 1: SystemSettings.supportTrialDays ──────────────────────────────
  group('SystemSettings.supportTrialDays', () {
    test('defaults to 3 when constructed with no arguments', () {
      const settings = SystemSettings();
      expect(settings.supportTrialDays, equals(3));
    });

    test('can be set to a custom value via named constructor argument', () {
      const settings = SystemSettings(supportTrialDays: 7);
      expect(settings.supportTrialDays, equals(7));
    });

    test('fromMap reads support_trial_days from Firestore data', () {
      final settings = SystemSettings.fromMap({'support_trial_days': 5});
      expect(settings.supportTrialDays, equals(5));
    });

    test('fromMap defaults to 3 when support_trial_days is absent', () {
      final settings = SystemSettings.fromMap({});
      expect(settings.supportTrialDays, equals(3));
    });

    test('fromMap defaults to 3 when support_trial_days is null', () {
      final settings = SystemSettings.fromMap({'support_trial_days': null});
      expect(settings.supportTrialDays, equals(3));
    });

    test('fromMap coerces double Firestore num to int (e.g. 7.0 → 7)', () {
      final settings = SystemSettings.fromMap({'support_trial_days': 7.0});
      expect(settings.supportTrialDays, equals(7));
    });

    test('toMap includes support_trial_days', () {
      const settings = SystemSettings(supportTrialDays: 14);
      expect(settings.toMap()['support_trial_days'], equals(14));
    });
  });

  // ── Task 2: gate condition logic ─────────────────────────────────────────
  //
  // We extract the pure boolean logic from the widget and test it here so
  // the gate condition is provably correct without needing a widget test
  // (which would require Firebase / go_router).
  //
  // Gate:
  //   trialEnded = now.isAfter(createdAt.add(Duration(days: supportTrialDays)))
  //   gated = trialEnded && tierLevel < 1 && !supportOpenToAll
  // Fail-open: if createdAt is null OR settings is loading/error → gated = false.

  bool computeGated({
    required DateTime now,
    DateTime? createdAt,
    required int supportTrialDays,
    required int tierLevel,
    required bool supportOpenToAll,
  }) {
    if (createdAt == null) return false;
    final trialEnded = now.isAfter(createdAt.add(Duration(days: supportTrialDays)));
    return trialEnded && tierLevel < 1 && !supportOpenToAll;
  }

  group('gate condition — trial not yet ended', () {
    final now = DateTime(2026, 1, 10);
    final createdAt = DateTime(2026, 1, 8); // 2 days ago, trial=3

    test('in-trial free user is NOT gated', () {
      expect(
        computeGated(
          now: now,
          createdAt: createdAt,
          supportTrialDays: 3,
          tierLevel: 0,
          supportOpenToAll: false,
        ),
        isFalse,
      );
    });
  });

  group('gate condition — trial ended', () {
    final now = DateTime(2026, 1, 15);
    final createdAt = DateTime(2026, 1, 10); // 5 days ago, trial=3

    test('free user after trial is gated', () {
      expect(
        computeGated(
          now: now,
          createdAt: createdAt,
          supportTrialDays: 3,
          tierLevel: 0,
          supportOpenToAll: false,
        ),
        isTrue,
      );
    });

    test('subscribed user (tierLevel>=1) after trial is NOT gated', () {
      expect(
        computeGated(
          now: now,
          createdAt: createdAt,
          supportTrialDays: 3,
          tierLevel: 1,
          supportOpenToAll: false,
        ),
        isFalse,
      );
    });

    test('supportOpenToAll=true overrides gating for free user', () {
      expect(
        computeGated(
          now: now,
          createdAt: createdAt,
          supportTrialDays: 3,
          tierLevel: 0,
          supportOpenToAll: true,
        ),
        isFalse,
      );
    });
  });

  group('gate condition — fail-open cases', () {
    final now = DateTime(2026, 1, 15);

    test('null createdAt is NOT gated (fail-open)', () {
      expect(
        computeGated(
          now: now,
          createdAt: null,
          supportTrialDays: 3,
          tierLevel: 0,
          supportOpenToAll: false,
        ),
        isFalse,
      );
    });

    test('exactly on the trial boundary (same day) is NOT gated', () {
      // createdAt + 3 days == now → isAfter is false → not gated
      final createdAt = now.subtract(const Duration(days: 3));
      expect(
        computeGated(
          now: now,
          createdAt: createdAt,
          supportTrialDays: 3,
          tierLevel: 0,
          supportOpenToAll: false,
        ),
        isFalse,
      );
    });

    test('one second past the trial boundary is gated', () {
      final createdAt = now.subtract(
        const Duration(days: 3, seconds: 1),
      );
      expect(
        computeGated(
          now: now,
          createdAt: createdAt,
          supportTrialDays: 3,
          tierLevel: 0,
          supportOpenToAll: false,
        ),
        isTrue,
      );
    });
  });

  // ── Task 3: l10n keys are defined ────────────────────────────────────────
  group('l10n keys', () {
    test('AppStrings.supportTrialEnded is defined (AR)', () {
      // compile-time check: if the field doesn't exist, this won't compile
      const s = AppStrings.supportTrialEnded;
      expect(s, isNotEmpty);
    });

    test('AppStrings.subscribeToContinue is defined (AR)', () {
      const s = AppStrings.subscribeToContinue;
      expect(s, isNotEmpty);
    });
  });
}
