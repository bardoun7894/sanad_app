import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/core/services/gemini_service.dart';
import 'package:sanad_app/features/admin/providers/admin_provider.dart';
import 'package:sanad_app/features/admin/providers/risk_alerts_provider.dart';
import 'package:sanad_app/features/admin/widgets/dashboard/ai_assistant_panel.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/auth/models/auth_user.dart';
import 'package:sanad_app/features/chat/services/ai_privacy_consent_service.dart';

class _Gemini extends Mock implements GeminiService {}

final _account = StateProvider<String>((ref) => 'alice');

void main() {
  setUpAll(() => registerFallbackValue(<GeminiChatMessage>[]));
  testWidgets(
    'late AI response is neither displayed nor saved after account changes',
    (tester) async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('admin_ai_chats')
          .doc('alice')
          .collection('messages')
          .doc('history')
          .set({
            'content': 'Alice history',
            'role': 'model',
            'timestamp': Timestamp.now(),
            'ai_subject_user_ids': <String>[],
          });
      final reply = Completer<GeminiResponse>();
      final ai = _Gemini();
      when(
        () => ai.sendMessage(
          userId: any(named: 'userId'),
          subjectUserIds: any(named: 'subjectUserIds'),
          messages: any(named: 'messages'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenAnswer((_) => reply.future);
      late ProviderContainer container;
      final consent = AiPrivacyConsentService(
        currentUserId: () => container.read(_account),
        readConsent: (_) async => {
          'accepted': true,
          'version': aiPrivacyConsentVersion,
        },
        saveConsent: (_, expectedUserId) async => {},
      );
      container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => AuthUser(
              uid: ref.watch(_account),
              email: 'admin@example.test',
              createdAt: DateTime(2026),
              provider: AuthProvider.email,
              role: UserRole.admin,
            ),
          ),
          languageProvider.overrideWith(
            (ref) => LanguageNotifier(initial: AppLanguage.english),
          ),
          aiPrivacyConsentServiceProvider.overrideWithValue(consent),
          riskAlertsProvider.overrideWith((ref) => Stream.value([])),
          dashboardStatsProvider.overrideWith(
            (ref) async => const DashboardStats(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AiAssistantPanel(firestore: firestore, aiService: ai),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Summarize today');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));
      container.read(_account.notifier).state = 'bob';
      await tester.pump(const Duration(milliseconds: 100));
      reply.complete(
        GeminiResponse(
          content: 'Alice sensitive response',
          tokensUsed: 0,
          model: 'test',
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Alice sensitive response'), findsNothing);
      final bob = await firestore
          .collection('admin_ai_chats')
          .doc('bob')
          .collection('messages')
          .get();
      expect(bob.docs, isEmpty);
      final alice = await firestore
          .collection('admin_ai_chats')
          .doc('alice')
          .collection('messages')
          .get();
      expect(
        alice.docs.any(
          (doc) => doc.data()['content'] == 'Alice sensitive response',
        ),
        false,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 400));
    },
  );
}
