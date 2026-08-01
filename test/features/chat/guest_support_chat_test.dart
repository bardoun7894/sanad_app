import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_app/features/admin/services/admin_chat_service.dart';
import 'package:sanad_app/features/chat/services/user_support_chat_service.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

FirebaseAuth _authWith({required bool anonymous}) {
  final auth = _MockAuth();
  final user = _MockUser();
  when(() => user.isAnonymous).thenReturn(anonymous);
  when(() => auth.currentUser).thenReturn(user);
  return auth;
}

void main() {
  group('guests cannot open support threads', () {
    // "Continue as Guest" produced 86 threads in the admin inbox from accounts
    // with no name, email or phone — nobody the admin could ever reply to.
    test('getOrCreateThread is refused for an anonymous account', () async {
      final firestore = FakeFirebaseFirestore();
      final service = UserSupportChatService(
        firestore: firestore,
        auth: _authWith(anonymous: true),
      );

      await expectLater(
        service.getOrCreateThread(userId: 'guest1', userEmail: ''),
        throwsA(isA<GuestSupportChatDenied>()),
      );
      final doc = await firestore.collection('support_chats').doc('guest1').get();
      expect(doc.exists, isFalse, reason: 'no thread should be written');
    });

    test('sendUserMessage is refused even if a thread already exists', () async {
      final firestore = FakeFirebaseFirestore();
      // A thread from before the restriction existed.
      await firestore.collection('support_chats').doc('guest1').set({
        'user_id': 'guest1',
        'user_name': '',
      });
      final service = UserSupportChatService(
        firestore: firestore,
        auth: _authWith(anonymous: true),
      );

      await expectLater(
        service.sendUserMessage(
          userId: 'guest1',
          userEmail: '',
          content: 'hello',
        ),
        throwsA(isA<GuestSupportChatDenied>()),
      );
    });

    test('a signed-up user is unaffected', () async {
      final firestore = FakeFirebaseFirestore();
      final service = UserSupportChatService(
        firestore: firestore,
        auth: _authWith(anonymous: false),
      );

      await service.getOrCreateThread(
        userId: 'real1',
        userEmail: 'a@b.com',
        userName: 'Real Person',
      );

      final doc = await firestore.collection('support_chats').doc('real1').get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['user_name'], 'Real Person');
    });
  });

  group('admin inbox names guests instead of calling them unknown', () {
    Future<String> resolve(
      FakeFirebaseFirestore firestore,
      Map<String, dynamic> userDoc,
    ) async {
      await firestore.collection('users').doc('u1').set(userDoc);
      await firestore.collection('support_chats').doc('u1').set({
        'user_id': 'u1',
        'user_name': '',
        'user_email': '',
      });
      final snap =
          await firestore.collection('support_chats').doc('u1').get();
      return AdminChatService(firestore: firestore)
          .resolveDisplayNameForThread(ChatThread.fromFirestore(snap));
    }

    test('an anonymous account resolves to Guest', () async {
      expect(
        await resolve(FakeFirebaseFirestore(), {'auth_provider': 'anonymous'}),
        'Guest',
      );
    });

    test('an identity-less stub with unknown provider resolves to Guest', () {
      expect(
        resolve(FakeFirebaseFirestore(), {'auth_provider': 'unknown'}),
        completion('Guest'),
      );
    });

    test('a real signup missing only a name is not called a Guest', () async {
      final name = await resolve(FakeFirebaseFirestore(), {
        'auth_provider': 'google',
        'email': 'someone@example.com',
      });
      expect(name, isNot('Guest'));
      expect(name, 'someone@example.com');
    });

    test('a real name still wins', () async {
      expect(
        await resolve(FakeFirebaseFirestore(), {
          'auth_provider': 'google',
          'name': 'Real Person',
        }),
        'Real Person',
      );
    });
  });
}
