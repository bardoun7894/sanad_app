import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapist_chat/providers/therapist_chat_access_provider.dart';

void main() {
  group('therapistChatAccessFromFlag', () {
    test('returns full for "full"', () {
      expect(
        therapistChatAccessFromFlag('full'),
        TherapistChatAccess.full,
      );
    });

    test('returns readOnly for "read_only"', () {
      expect(
        therapistChatAccessFromFlag('read_only'),
        TherapistChatAccess.readOnly,
      );
    });

    test('returns none for null (absent field)', () {
      expect(
        therapistChatAccessFromFlag(null),
        TherapistChatAccess.none,
      );
    });

    test('returns none for unrecognised string', () {
      expect(
        therapistChatAccessFromFlag('garbage'),
        TherapistChatAccess.none,
      );
    });

    test('returns none for empty string', () {
      expect(
        therapistChatAccessFromFlag(''),
        TherapistChatAccess.none,
      );
    });
  });
}
