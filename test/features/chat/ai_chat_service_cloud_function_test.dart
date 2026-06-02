import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:sanad_app/features/chat/models/message.dart';
import 'package:sanad_app/features/chat/services/ai_chat_service.dart';

/// Tests verifying the Cloud Function routing behaviour of AiChatService.
///
/// These tests use the injectable [ChatCallable] hook to avoid live network
/// calls and Firestore writes, focusing on pure logic: message windowing,
/// role mapping, error classification, and metadata persistence.
void main() {
  // ── Helpers ──────────────────────────────────────────────────────────────

  Message _makeMsg(
    String id,
    MessageType type,
    String content, {
    DateTime? ts,
  }) {
    return Message(
      id: id,
      content: content,
      type: type,
      timestamp: ts ?? DateTime(2026, 1, 1, 10, 0),
    );
  }

  List<Message> _makeHistory(int count) {
    return List.generate(
      count,
      (i) => _makeMsg(
        'h$i',
        i.isEven ? MessageType.user : MessageType.bot,
        'msg $i',
        ts: DateTime(2026, 1, 1, 10, i),
      ),
    );
  }

  // ── prepareCloudPayload (pure message helper) ─────────────────────────────

  group('prepareCloudPayload', () {
    test('maps user type to role "user"', () {
      final msg = _makeMsg('1', MessageType.user, 'hello');
      final payload = prepareCloudPayload([msg]);
      expect(payload.length, 1);
      expect(payload.first['role'], 'user');
      expect(payload.first['content'], 'hello');
    });

    test('maps bot type to role "model"', () {
      final msg = _makeMsg('1', MessageType.bot, 'reply');
      final payload = prepareCloudPayload([msg]);
      expect(payload.first['role'], 'model');
    });

    test('limits history to last 20 messages when given 25', () {
      final history = _makeHistory(25);
      final payload = prepareCloudPayload(history);
      // Should keep last 20 (index 5..24)
      expect(payload.length, 20);
      expect(payload.first['content'], 'msg 5');
      expect(payload.last['content'], 'msg 24');
    });

    test('returns all messages when fewer than 20', () {
      final history = _makeHistory(10);
      final payload = prepareCloudPayload(history);
      expect(payload.length, 10);
    });

    test('system and handoff types map to role "user"', () {
      final sys = _makeMsg('1', MessageType.system, 'sys');
      final handoff = _makeMsg('2', MessageType.handoff, 'hoff');
      final payload = prepareCloudPayload([sys, handoff]);
      expect(payload[0]['role'], 'user');
      expect(payload[1]['role'], 'user');
    });
  });

  // ── classifyFunctionError ──────────────────────────────────────────────

  group('classifyFunctionError', () {
    test('resource-exhausted maps to dailyLimitReached', () {
      final result = classifyFunctionError('resource-exhausted');
      expect(result, CloudFunctionErrorKind.dailyLimitReached);
    });

    test('permission-denied maps to permissionDenied', () {
      final result = classifyFunctionError('permission-denied');
      expect(result, CloudFunctionErrorKind.permissionDenied);
    });

    test('unauthenticated maps to unauthenticated', () {
      final result = classifyFunctionError('unauthenticated');
      expect(result, CloudFunctionErrorKind.unauthenticated);
    });

    test('unknown codes map to generic', () {
      final result = classifyFunctionError('internal');
      expect(result, CloudFunctionErrorKind.generic);
    });
  });

  // ── MessageMetadata sources field ─────────────────────────────────────

  group('MessageMetadata.sources', () {
    test('sources field is serialized to Firestore', () {
      const meta = MessageMetadata(
        model: 'gemini-2.5-flash',
        tokensUsed: 300,
        sources: ['content-abc', 'content-xyz'],
      );
      final map = meta.toFirestore();
      expect(map['sources'], ['content-abc', 'content-xyz']);
    });

    test('sources field is deserialized from Firestore', () {
      final map = {
        'model': 'gemini-2.5-flash',
        'tokens_used': 300,
        'sources': ['content-abc', 'content-xyz'],
      };
      final meta = MessageMetadata.fromFirestore(map);
      expect(meta.sources, ['content-abc', 'content-xyz']);
    });

    test('sources field is absent when null', () {
      const meta = MessageMetadata(model: 'fallback');
      final map = meta.toFirestore();
      expect(map.containsKey('sources'), isFalse);
    });
  });

  // ── buildDailyLimitMessage ──────────────────────────────────────────────

  group('buildDailyLimitMessage', () {
    test('contains expected daily limit text', () {
      final msg = buildDailyLimitMessage();
      expect(msg, contains('Daily AI usage limit reached'));
      expect(msg, contains('Try again tomorrow'));
    });
  });

  group('getOrCreateChat auth guard', () {
    test(
      'does not create a chat document when no user is authenticated',
      () async {
        final firestore = FakeFirebaseFirestore();
        final service = AiChatService(
          firestore: firestore,
          chatCallable: (_) async => <String, dynamic>{},
        );

        await expectLater(
          service.getOrCreateChat('user-1'),
          throwsA(
            isA<AiChatException>().having(
              (error) => error.code,
              'code',
              'unauthenticated',
            ),
          ),
        );

        final doc = await firestore.collection('ai_chats').doc('user-1').get();
        expect(doc.exists, isFalse);
      },
    );
  });

  group('sendMessage auth guard', () {
    test('does not write a message when no user is authenticated', () async {
      final firestore = FakeFirebaseFirestore();
      final service = AiChatService(
        firestore: firestore,
        chatCallable: (_) async => <String, dynamic>{},
      );

      await expectLater(
        service.sendMessage(
          userId: 'user-1',
          content: 'hello',
          conversationHistory: const [],
        ),
        throwsA(
          isA<AiChatException>().having(
            (error) => error.code,
            'code',
            'unauthenticated',
          ),
        ),
      );

      final messages = await firestore
          .collection('ai_chats')
          .doc('user-1')
          .collection('messages')
          .get();
      expect(messages.docs, isEmpty);
    });
  });
}
