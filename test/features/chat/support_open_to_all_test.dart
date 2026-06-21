// TDD: RED tests for `support_open_to_all` feature flag.
// These tests must FAIL before the production code changes are applied.
// Run: flutter test test/features/chat/support_open_to_all_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/providers/system_settings_provider.dart';

void main() {
  group('SystemSettings.supportOpenToAll', () {
    test('defaults to false when constructed with no arguments', () {
      const settings = SystemSettings();
      expect(settings.supportOpenToAll, isFalse);
    });

    test('can be set to true via named constructor argument', () {
      const settings = SystemSettings(supportOpenToAll: true);
      expect(settings.supportOpenToAll, isTrue);
    });

    test('fromFirestore parses support_open_to_all=true from Firestore map', () {
      // We test the fromMap-equivalent path through the factory constructor
      // directly, providing a mock data map. The factory reads
      // data['support_open_to_all'] ?? false.
      final settings = SystemSettings.fromMap({
        'support_open_to_all': true,
      });
      expect(settings.supportOpenToAll, isTrue);
    });

    test('fromFirestore defaults to false when support_open_to_all is absent', () {
      final settings = SystemSettings.fromMap({});
      expect(settings.supportOpenToAll, isFalse);
    });

    test('fromFirestore defaults to false when support_open_to_all is null', () {
      final settings = SystemSettings.fromMap({'support_open_to_all': null});
      expect(settings.supportOpenToAll, isFalse);
    });
  });

  group('showSupportChat logic with supportOpenToAll', () {
    // Replicate the visibility computation from user_chat_list_screen.dart
    // to make it unit-testable without Flutter/Riverpod.
    //
    // Current formula (before fix):
    //   showSupportChat = !hideSupportAndTherapy || hasAssignedTherapist
    //
    // Target formula (after fix):
    //   showSupportChat = supportOpenToAll || !hideSupportAndTherapy || hasAssignedTherapist
    bool showSupportChat({
      required bool isGuest,
      required int tierLevel,
      required bool hasAssignedTherapist,
      required bool supportOpenToAll,
    }) {
      final hideSupportAndTherapy = isGuest || tierLevel < 1;
      return supportOpenToAll || !hideSupportAndTherapy || hasAssignedTherapist;
    }

    test('guest with flag=false sees NO support tile (existing behavior)', () {
      final result = showSupportChat(
        isGuest: true,
        tierLevel: 0,
        hasAssignedTherapist: false,
        supportOpenToAll: false,
      );
      expect(result, isFalse);
    });

    test('guest with flag=true sees support tile (new behavior)', () {
      final result = showSupportChat(
        isGuest: true,
        tierLevel: 0,
        hasAssignedTherapist: false,
        supportOpenToAll: true,
      );
      expect(result, isTrue);
    });

    test('free-tier user with flag=false sees NO support tile (existing)', () {
      final result = showSupportChat(
        isGuest: false,
        tierLevel: 0,
        hasAssignedTherapist: false,
        supportOpenToAll: false,
      );
      expect(result, isFalse);
    });

    test('free-tier user with flag=true sees support tile (new behavior)', () {
      final result = showSupportChat(
        isGuest: false,
        tierLevel: 0,
        hasAssignedTherapist: false,
        supportOpenToAll: true,
      );
      expect(result, isTrue);
    });

    test('paid-tier user always sees support tile regardless of flag', () {
      expect(
        showSupportChat(
          isGuest: false,
          tierLevel: 1,
          hasAssignedTherapist: false,
          supportOpenToAll: false,
        ),
        isTrue,
      );
      expect(
        showSupportChat(
          isGuest: false,
          tierLevel: 1,
          hasAssignedTherapist: false,
          supportOpenToAll: true,
        ),
        isTrue,
      );
    });

    test('admin-assigned user always sees support tile regardless of flag', () {
      expect(
        showSupportChat(
          isGuest: true,
          tierLevel: 0,
          hasAssignedTherapist: true,
          supportOpenToAll: false,
        ),
        isTrue,
      );
    });
  });
}
