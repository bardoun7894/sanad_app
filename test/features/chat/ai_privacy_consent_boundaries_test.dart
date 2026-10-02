import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:sanad_app/core/services/gemini_service.dart';
import 'package:sanad_app/features/chat/services/ai_chat_service.dart';
import 'package:sanad_app/features/chat/services/ai_privacy_consent_service.dart';

void main() {
  test(
    'cloud chat sends nothing and writes no messages before consent',
    () async {
      final firestore = FakeFirebaseFirestore();
      var transfers = 0;
      final service = AiChatService(
        firestore: firestore,
        currentUserIdReader: () => 'alice',
        chatCallable: (_) async {
          transfers++;
          return {'content': 'reply'};
        },
      );
      await expectLater(
        service.sendMessage(
          userId: 'alice',
          content: 'health data',
          conversationHistory: [],
        ),
        throwsA(isA<AiConsentRequiredException>()),
      );
      expect(transfers, 0);
      expect(
        (await firestore
                .collection('ai_chats')
                .doc('alice')
                .collection('messages')
                .get())
            .docs,
        isEmpty,
      );
    },
  );
  test(
    'structured consent error remains recognizable instead of generic fallback',
    () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('alice').set({
        'ai_privacy_consent': {
          'accepted': true,
          'version': aiPrivacyConsentVersion,
        },
      });
      final service = AiChatService(
        firestore: firestore,
        currentUserIdReader: () => 'alice',
        chatCallable: (_) async => throw FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'Consent required',
          details: {
            'reason': 'ai-consent-required',
            'version': aiPrivacyConsentVersion,
          },
        ),
      );
      await expectLater(
        service.sendMessage(
          userId: 'alice',
          content: 'health data',
          conversationHistory: [],
        ),
        throwsA(predicate<Object>(isAiConsentRequiredError)),
      );
      final messages = await firestore
          .collection('ai_chats')
          .doc('alice')
          .collection('messages')
          .get();
      expect(messages.docs.length, 1);
      expect(messages.docs.single.data()['type'], 'user');
    },
  );
  test('direct Gemini refuses a patient without current consent', () async {
    final consent = AiPrivacyConsentService(
      currentUserId: () => 'admin',
      readConsent: (id) async => {
        'accepted': id == 'admin',
        'version': aiPrivacyConsentVersion,
      },
      saveConsent: (_, expectedUserId) async => {},
    );
    final service = GeminiService(apiKey: 'unused', consentService: consent);
    await expectLater(
      service.sendMessage(
        userId: 'admin',
        subjectUserIds: {'patient'},
        messages: [GeminiChatMessage(role: 'user', content: 'patient data')],
      ),
      throwsA(isA<AiConsentRequiredException>()),
    );
  });
}
