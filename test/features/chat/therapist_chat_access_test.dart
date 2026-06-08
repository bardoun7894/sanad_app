import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/chat/providers/therapist_chat_access_provider.dart';

void main() {
  group('therapistChatAccessFromFlag', () {
    test("'full' maps to TherapistChatAccess.full", () {
      expect(
        therapistChatAccessFromFlag('full'),
        TherapistChatAccess.full,
      );
    });

    test("'read_only' maps to TherapistChatAccess.readOnly", () {
      expect(
        therapistChatAccessFromFlag('read_only'),
        TherapistChatAccess.readOnly,
      );
    });

    test('null maps to TherapistChatAccess.none', () {
      expect(
        therapistChatAccessFromFlag(null),
        TherapistChatAccess.none,
      );
    });

    test("empty string maps to TherapistChatAccess.none", () {
      expect(
        therapistChatAccessFromFlag(''),
        TherapistChatAccess.none,
      );
    });

    test("'none' maps to TherapistChatAccess.none", () {
      expect(
        therapistChatAccessFromFlag('none'),
        TherapistChatAccess.none,
      );
    });

    test("'FULL' (uppercase) maps to TherapistChatAccess.none — case-sensitive", () {
      expect(
        therapistChatAccessFromFlag('FULL'),
        TherapistChatAccess.none,
      );
    });

    test("unknown string 'paid' maps to TherapistChatAccess.none", () {
      expect(
        therapistChatAccessFromFlag('paid'),
        TherapistChatAccess.none,
      );
    });
  });
}
