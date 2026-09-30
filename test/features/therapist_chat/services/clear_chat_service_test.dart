import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_app/features/therapist_chat/services/therapist_chat_service.dart';

class _Functions extends Mock implements FirebaseFunctions {}

class _Callable extends Mock implements HttpsCallable {}

class _Result extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  setUpAll(() => registerFallbackValue(HttpsCallableOptions()));

  test(
    'clearChat sends chatId to callable and returns deletion count',
    () async {
      final functions = _Functions();
      final callable = _Callable();
      final result = _Result();
      final db = FakeFirebaseFirestore();
      await db.collection('therapist_chats').doc('chat').set({
        'user_id': 'user',
      });
      when(
        () => functions.httpsCallable(
          'clearTherapistChat',
          options: any(named: 'options'),
        ),
      ).thenReturn(callable);
      when(
        () => callable.call<Map<String, dynamic>>({'chatId': 'chat'}),
      ).thenAnswer((_) async => result);
      when(() => result.data).thenReturn({'deleted': 401});

      final service = TherapistChatService(firestore: db, functions: functions);
      expect(await service.clearChat('chat'), 401);
      verify(
        () => callable.call<Map<String, dynamic>>({'chatId': 'chat'}),
      ).called(1);
      expect(
        (await db.collection('therapist_chats').doc('chat').get()).exists,
        true,
      );
    },
  );

  test('clearChat surfaces callable errors to the list control', () async {
    final functions = _Functions();
    final callable = _Callable();
    when(
      () => functions.httpsCallable(
        'clearTherapistChat',
        options: any(named: 'options'),
      ),
    ).thenReturn(callable);
    when(() => callable.call<Map<String, dynamic>>(any())).thenThrow(
      FirebaseFunctionsException(code: 'permission-denied', message: 'Denied'),
    );
    final service = TherapistChatService(
      firestore: FakeFirebaseFirestore(),
      functions: functions,
    );
    expect(
      service.clearChat('chat'),
      throwsA(isA<FirebaseFunctionsException>()),
    );
  });
}
