import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/chat/services/ai_chat_service.dart';
import 'package:sanad_app/features/chat/models/message.dart';

/// Tests verifying that the persona field is included in Cloud Function
/// payloads. These test the pure helper logic to avoid live network calls.
void main() {
  group('buildPersonaPayload', () {
    test('persona field appears in payload with provided value', () {
      final payload = buildPersonaPayload(
        userId: 'user123',
        locale: 'en',
        messages: [],
        persona: 'cbt_therapist',
      );
      expect(payload['persona'], 'cbt_therapist');
      expect(payload['userId'], 'user123');
      expect(payload['locale'], 'en');
    });

    test('persona defaults to companion when not provided', () {
      final payload = buildPersonaPayload(
        userId: 'user123',
        locale: 'ar',
        messages: [],
      );
      expect(payload['persona'], 'companion');
    });

    test('messages are included in payload', () {
      final messages = [
        {'role': 'user', 'content': 'hello'},
      ];
      final payload = buildPersonaPayload(
        userId: 'user123',
        locale: 'en',
        messages: messages,
        persona: 'coach',
      );
      expect(payload['messages'], messages);
    });
  });

  group('MessageMetadata persona field', () {
    test('persona field is serialized to Firestore', () {
      const meta = MessageMetadata(
        model: 'gemini-2.5-flash',
        persona: 'coach',
      );
      final map = meta.toFirestore();
      expect(map['persona'], 'coach');
    });

    test('persona field is deserialized from Firestore', () {
      final map = {
        'model': 'gemini-2.5-flash',
        'persona': 'cbt_therapist',
      };
      final meta = MessageMetadata.fromFirestore(map);
      expect(meta.persona, 'cbt_therapist');
    });

    test('persona field is absent from Firestore map when null', () {
      const meta = MessageMetadata(model: 'fallback');
      final map = meta.toFirestore();
      expect(map.containsKey('persona'), isFalse);
    });
  });
}
