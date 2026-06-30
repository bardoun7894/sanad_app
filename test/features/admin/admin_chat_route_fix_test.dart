import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/services/admin_chat_service.dart';

Future<void> _seedSupportChat(
  FakeFirebaseFirestore fake, {
  required String userId,
  String? userName,
  String? userEmail,
  String? lastMessage,
  int unreadCountAdmin = 0,
}) async {
  await fake.collection('support_chats').doc(userId).set({
    if (userEmail != null) 'user_email': userEmail,
    if (userName != null) 'user_name': userName,
    if (lastMessage != null) 'last_message': lastMessage,
    'last_message_time': Timestamp.fromDate(DateTime(2026, 6, 21)),
    'unread_count_admin': unreadCountAdmin,
  });
}

Future<void> _seedUser(
  FakeFirebaseFirestore fake, {
  required String userId,
  String? name,
  String? displayName,
  String? firstName,
  String? lastName,
  String? email,
}) async {
  await fake.collection('users').doc(userId).set({
    if (name != null) 'name': name,
    if (displayName != null) 'display_name': displayName,
    if (firstName != null) 'first_name': firstName,
    if (lastName != null) 'last_name': lastName,
    if (email != null) 'email': email,
  });
}

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

  group('ChatThread.fallbackDisplayName', () {
    test('returns real userName when present', () {
      final thread = ChatThread(
        userId: 'u1',
        userEmail: 'u1@example.com',
        userName: 'Sara Hassan',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
      );
      expect(thread.fallbackDisplayName, 'Sara Hassan');
    });

    test('ignores legacy User placeholder and falls back to email', () {
      final thread = ChatThread(
        userId: 'u1',
        userEmail: 'u1@example.com',
        userName: 'User',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
      );
      expect(thread.fallbackDisplayName, 'u1@example.com');
    });

    test('falls back to Unknown User when name and email are missing', () {
      final thread = ChatThread(
        userId: 'u1',
        userEmail: 'Unknown User',
        userName: '',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
      );
      expect(thread.fallbackDisplayName, 'Unknown User');
    });
  });

  group('AdminChatService.resolveRealName', () {
    test('returns real name from users collection', () async {
      final fake = FakeFirebaseFirestore();
      await _seedUser(
        fake,
        userId: 'u1',
        firstName: 'Basmala',
        lastName: 'Ahmed',
        email: 'basmala@example.com',
      );

      final service = AdminChatService(firestore: fake);
      final name = await service.resolveRealName('u1');
      expect(name, 'Basmala Ahmed');
    });

    test('returns null when user doc does not exist', () async {
      final fake = FakeFirebaseFirestore();
      final service = AdminChatService(firestore: fake);
      final name = await service.resolveRealName('missing');
      expect(name, isNull);
    });

    test('ignores legacy User placeholder in users doc', () async {
      final fake = FakeFirebaseFirestore();
      await _seedUser(
        fake,
        userId: 'u1',
        name: 'User',
        firstName: 'Real',
        lastName: 'Name',
      );

      final service = AdminChatService(firestore: fake);
      final name = await service.resolveRealName('u1');
      expect(name, 'Real Name');
    });
  });

  group('AdminChatService.resolveDisplayNameForThread', () {
    test('uses cached thread name when real', () async {
      final fake = FakeFirebaseFirestore();
      await _seedUser(fake, userId: 'u1', firstName: 'Other', lastName: 'Name');
      await _seedSupportChat(
        fake,
        userId: 'u1',
        userName: 'Cached Name',
        userEmail: 'cached@example.com',
      );

      final service = AdminChatService(firestore: fake);
      final thread = await service.getChatThread('u1').first;
      final name = await service.resolveDisplayNameForThread(thread!);
      expect(name, 'Cached Name');
    });

    test('resolves from users collection when thread name is User', () async {
      final fake = FakeFirebaseFirestore();
      await _seedUser(
        fake,
        userId: 'u1',
        firstName: 'Sara',
        lastName: 'Hassan',
        email: 'sara@example.com',
      );
      await _seedSupportChat(
        fake,
        userId: 'u1',
        userName: 'User',
        userEmail: 'sara@example.com',
      );

      final service = AdminChatService(firestore: fake);
      final thread = await service.getChatThread('u1').first;
      final name = await service.resolveDisplayNameForThread(thread!);
      expect(name, 'Sara Hassan');
    });

    test('falls back to email when no real name exists', () async {
      final fake = FakeFirebaseFirestore();
      await _seedSupportChat(
        fake,
        userId: 'u1',
        userName: 'User',
        userEmail: 'fallback@example.com',
      );

      final service = AdminChatService(firestore: fake);
      final thread = await service.getChatThread('u1').first;
      final name = await service.resolveDisplayNameForThread(thread!);
      expect(name, 'fallback@example.com');
    });

    test('falls back to phone for phone-only signup (no name, no email)',
        () async {
      final fake = FakeFirebaseFirestore();
      // Phone-only signup: support thread has placeholder name and no email.
      await _seedSupportChat(fake, userId: 'u1', userName: 'User');
      await fake.collection('users').doc('u1').set({'phone': '+966500000000'});

      final service = AdminChatService(firestore: fake);
      final thread = await service.getChatThread('u1').first;
      final name = await service.resolveDisplayNameForThread(thread!);
      // Previously this rendered as "Unknown User".
      expect(name, '+966500000000');
    });

    test('real name still wins over phone', () async {
      final fake = FakeFirebaseFirestore();
      await _seedSupportChat(fake, userId: 'u1', userName: 'User');
      await fake.collection('users').doc('u1').set({
        'name': 'Sara',
        'phone': '+966500000000',
      });

      final service = AdminChatService(firestore: fake);
      final thread = await service.getChatThread('u1').first;
      final name = await service.resolveDisplayNameForThread(thread!);
      expect(name, 'Sara');
    });
  });

  group('AdminChatService.broadcastMessageWithReport', () {
    test('does not write legacy User placeholder into support_chats',
        () async {
      final fake = FakeFirebaseFirestore();
      await _seedUser(
        fake,
        userId: 'u1',
        name: 'User',
        firstName: 'Real',
        lastName: 'Name',
        email: 'real@example.com',
      );

      final service = AdminChatService(firestore: fake);
      await service.broadcastMessageWithReport('Hello everyone');

      final thread =
          await fake.collection('support_chats').doc('u1').get();
      expect(thread.exists, isTrue);
      expect(thread.data()?['user_name'], isNot('User'));
      expect(thread.data()?['user_name'], 'Real Name');
    });

    test('writes empty user_name when user has no real name', () async {
      final fake = FakeFirebaseFirestore();
      await _seedUser(
        fake,
        userId: 'u1',
        name: 'User',
        email: 'anon@example.com',
      );

      final service = AdminChatService(firestore: fake);
      await service.broadcastMessageWithReport('Hello everyone');

      final thread =
          await fake.collection('support_chats').doc('u1').get();
      expect(thread.exists, isTrue);
      expect(thread.data()?['user_name'], '');
    });
  });

  group('AdminChatService.deleteChatThread', () {
    test('removes the thread doc and all its messages (both sides)', () async {
      final fake = FakeFirebaseFirestore();
      await _seedSupportChat(
        fake,
        userId: 'u1',
        userEmail: 'a@example.com',
        lastMessage: 'hi',
      );
      // Two messages in the subcollection.
      final msgs = fake.collection('support_chats').doc('u1').collection('messages');
      await msgs.add({'sender_id': 'u1', 'content': 'hi'});
      await msgs.add({'sender_id': 'admin', 'content': 'hello'});

      final service = AdminChatService(firestore: fake);
      await service.deleteChatThread('u1');

      final thread = await fake.collection('support_chats').doc('u1').get();
      expect(thread.exists, isFalse);
      final remaining = await msgs.get();
      expect(remaining.docs, isEmpty);
    });

    test('is a no-op-safe call when the thread does not exist', () async {
      final fake = FakeFirebaseFirestore();
      final service = AdminChatService(firestore: fake);
      // Should not throw.
      await service.deleteChatThread('ghost');
      final thread = await fake.collection('support_chats').doc('ghost').get();
      expect(thread.exists, isFalse);
    });
  });
}
