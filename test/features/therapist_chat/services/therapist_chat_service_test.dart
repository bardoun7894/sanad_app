// T10 — TherapistChatService unit tests.
//
// Uses FakeFirebaseFirestore for real Firestore behavior on the
// messages subcollection — no mocks needed here.
//
// sendWelcomeMessage variants:
//   - senderType is SenderType.therapist
//   - metadata.custom['is_welcome'] == true
//   - metadata.custom['auto_generated'] == true
//   - metadata.custom['triggered_by'] matches param — tested for 'admin' AND 'user'
//   - content matches input string verbatim
//   - senderName matches therapistName param
//
// chatHasMessages:
//   - empty chat → false
//   - chat with one message → true

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapist_chat/models/therapist_message.dart';
import 'package:sanad_app/features/therapist_chat/services/therapist_chat_service.dart';

void main() {
  const _chatsCollection = 'therapist_chats';
  const _messagesSubcollection = 'messages';

  // Convenience: insert a raw message document into the fake Firestore.
  Future<void> seedMessage(
    FakeFirebaseFirestore db,
    String chatId,
    Map<String, dynamic> data,
  ) {
    return db
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesSubcollection)
        .add(data);
  }

  // Read all messages back from the subcollection.
  Future<List<Map<String, dynamic>>> readMessages(
    FakeFirebaseFirestore db,
    String chatId,
  ) async {
    final snap = await db
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesSubcollection)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // -----------------------------------------------------------------------
  // sendWelcomeMessage
  // -----------------------------------------------------------------------

  group('sendWelcomeMessage', () {
    const chatId = 'therapist-A_user-1';
    const therapistId = 'therapist-A';
    const therapistName = 'Dr. Welcome';
    const welcomeContent = 'Hello, welcome to our chat!';

    test(
      'senderType is SenderType.therapist (not system)',
      () async {
        final db = FakeFirebaseFirestore();
        final service = TherapistChatService(firestore: db);

        await service.sendWelcomeMessage(
          chatId: chatId,
          therapistId: therapistId,
          therapistName: therapistName,
          content: welcomeContent,
          triggeredBy: 'admin',
        );

        final messages = await readMessages(db, chatId);
        expect(messages, hasLength(1));
        expect(messages.first['sender_type'], SenderType.therapist.name);
      },
    );

    test(
      'metadata.custom contains is_welcome=true and auto_generated=true',
      () async {
        final db = FakeFirebaseFirestore();
        final service = TherapistChatService(firestore: db);

        await service.sendWelcomeMessage(
          chatId: chatId,
          therapistId: therapistId,
          therapistName: therapistName,
          content: welcomeContent,
          triggeredBy: 'admin',
        );

        final messages = await readMessages(db, chatId);
        final metadata =
            messages.first['metadata'] as Map<String, dynamic>?;
        expect(metadata, isNotNull);
        final custom = metadata!['custom'] as Map<String, dynamic>?;
        expect(custom, isNotNull);
        expect(custom!['is_welcome'], isTrue);
        expect(custom['auto_generated'], isTrue);
      },
    );

    test(
      'metadata.custom[triggered_by] matches param — triggeredBy=admin',
      () async {
        final db = FakeFirebaseFirestore();
        final service = TherapistChatService(firestore: db);

        await service.sendWelcomeMessage(
          chatId: chatId,
          therapistId: therapistId,
          therapistName: therapistName,
          content: welcomeContent,
          triggeredBy: 'admin',
        );

        final messages = await readMessages(db, chatId);
        final custom = (messages.first['metadata']
            as Map<String, dynamic>)['custom'] as Map<String, dynamic>;
        expect(custom['triggered_by'], 'admin');
      },
    );

    test(
      'metadata.custom[triggered_by] matches param — triggeredBy=user',
      () async {
        final db = FakeFirebaseFirestore();
        final service = TherapistChatService(firestore: db);

        await service.sendWelcomeMessage(
          chatId: chatId,
          therapistId: therapistId,
          therapistName: therapistName,
          content: welcomeContent,
          triggeredBy: 'user',
        );

        final messages = await readMessages(db, chatId);
        final custom = (messages.first['metadata']
            as Map<String, dynamic>)['custom'] as Map<String, dynamic>;
        expect(custom['triggered_by'], 'user');
      },
    );

    test(
      'content matches input string verbatim',
      () async {
        final db = FakeFirebaseFirestore();
        final service = TherapistChatService(firestore: db);

        const specificContent = 'مرحباً، أنا سعيد بالتحدث معك!';
        await service.sendWelcomeMessage(
          chatId: chatId,
          therapistId: therapistId,
          therapistName: therapistName,
          content: specificContent,
          triggeredBy: 'admin',
        );

        final messages = await readMessages(db, chatId);
        expect(messages.first['content'], specificContent);
      },
    );

    test(
      'senderName matches therapistName param',
      () async {
        final db = FakeFirebaseFirestore();
        final service = TherapistChatService(firestore: db);

        const specificTherapistName = 'Dr. Specific Name';
        await service.sendWelcomeMessage(
          chatId: chatId,
          therapistId: therapistId,
          therapistName: specificTherapistName,
          content: welcomeContent,
          triggeredBy: 'admin',
        );

        final messages = await readMessages(db, chatId);
        expect(messages.first['sender_name'], specificTherapistName);
      },
    );
  });

  // -----------------------------------------------------------------------
  // chatHasMessages
  // -----------------------------------------------------------------------

  group('chatHasMessages', () {
    test(
      'empty chat (no messages subcollection documents) → returns false',
      () async {
        final db = FakeFirebaseFirestore();
        final service = TherapistChatService(firestore: db);

        final result = await service.chatHasMessages('empty-chat-id');

        expect(result, isFalse);
      },
    );

    test(
      'chat with one message → returns true',
      () async {
        final db = FakeFirebaseFirestore();
        final service = TherapistChatService(firestore: db);

        const chatId = 'chat-with-messages';
        await seedMessage(db, chatId, {
          'id': 'msg-1',
          'sender_id': 'therapist-A',
          'sender_type': SenderType.therapist.name,
          'content': 'Hello!',
          'message_type': TherapistMessageType.text.name,
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'is_read': false,
          'status': MessageDeliveryStatus.sent.name,
        });

        final result = await service.chatHasMessages(chatId);

        expect(result, isTrue);
      },
    );
  });
}
