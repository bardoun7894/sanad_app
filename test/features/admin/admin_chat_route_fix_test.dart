import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/services/admin_chat_service.dart';

/// Tests for Issue-1 fix: getChatThread(userId) fallback accessor +
///   Issue-3 fix: displayName helper logic (userName preferred over email).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminChatService.getChatThread', () {
    test('emits matching ChatThread when the doc exists', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('support_chats').doc('uid_abc').set({
        'user_email': 'alice@example.com',
        'user_name': 'Alice',
        'last_message': 'Hello',
        'last_message_time': Timestamp.fromDate(DateTime(2026, 6, 21)),
        'unread_count_admin': 2,
      });

      final service = AdminChatService(firestore: fake);
      final thread = await service.getChatThread('uid_abc').first;

      expect(thread, isNotNull);
      expect(thread!.userId, 'uid_abc');
      expect(thread.userName, 'Alice');
      expect(thread.userEmail, 'alice@example.com');
      expect(thread.unreadCount, 2);
    });

    test('emits null when no doc exists for userId', () async {
      final fake = FakeFirebaseFirestore();
      final service = AdminChatService(firestore: fake);
      final thread = await service.getChatThread('nonexistent').first;

      expect(thread, isNull);
    });

    test('emits correct data from existing doc', () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('support_chats').doc('uid_xyz').set({
        'user_email': 'bob@example.com',
        'user_name': 'Bob',
        'last_message': 'Hi',
        'last_message_time': Timestamp.fromDate(DateTime(2026, 6, 21)),
        'unread_count_admin': 0,
      });

      final service = AdminChatService(firestore: fake);
      final thread = await service.getChatThread('uid_xyz').first;

      expect(thread, isNotNull);
      expect(thread!.lastMessage, 'Hi');
      expect(thread.userName, 'Bob');
    });
  });

  group('ChatThread displayName logic', () {
    test('prefers userName over email when userName is non-empty', () {
      final thread = ChatThread(
        userId: 'u1',
        userEmail: 'user@example.com',
        userName: 'Jane Doe',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
      );
      final displayName = thread.userName.isNotEmpty
          ? thread.userName
          : thread.userEmail;
      expect(displayName, 'Jane Doe');
    });

    test('falls back to email when userName is empty', () {
      final thread = ChatThread(
        userId: 'u2',
        userEmail: 'user@example.com',
        userName: '',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
      );
      final displayName = thread.userName.isNotEmpty
          ? thread.userName
          : thread.userEmail;
      expect(displayName, 'user@example.com');
    });
  });
}
