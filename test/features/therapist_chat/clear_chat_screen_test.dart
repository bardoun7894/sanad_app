import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/subscription/providers/feature_gating_provider.dart';
import 'package:sanad_app/features/therapist_chat/models/therapist_chat.dart';
import 'package:sanad_app/features/therapist_chat/models/therapist_message.dart';
import 'package:sanad_app/features/therapist_chat/providers/therapist_chat_access_provider.dart';
import 'package:sanad_app/features/therapist_chat/providers/therapist_chat_provider.dart';
import 'package:sanad_app/features/therapist_chat/screens/therapist_chat_detail_screen.dart';
import 'package:sanad_app/features/therapist_chat/screens/user_therapist_chat_screen.dart';
import 'package:sanad_app/features/therapist_chat/services/therapist_chat_service.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(const AuthState(status: AuthStatus.unauthenticated));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  for (final therapist in [true, false]) {
    testWidgets(
      '${therapist ? 'therapist' : 'patient'} sees empty chat and loses selected reply after clear',
      (tester) async {
        final messages = StreamController<List<TherapistMessage>>.broadcast();
        final s = S(AppLanguage.english);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => _Auth()),
              stringsProvider.overrideWithValue(s),
              therapistChatServiceProvider.overrideWithValue(
                TherapistChatService(firestore: FakeFirebaseFirestore()),
              ),
              chatMessagesProvider(
                'chat',
              ).overrideWith((ref) => messages.stream),
              typingStatusProvider(
                'chat',
              ).overrideWith((ref) => Stream.value(const TypingStatus())),
              therapistChatAccessProvider(
                'therapist',
              ).overrideWith((ref) => Stream.value(TherapistChatAccess.full)),
              canSendMessagesProvider.overrideWith((ref) => Stream.value(true)),
            ],
            child: MaterialApp(
              home: therapist
                  // No counterparty ID: keep the unrelated live header offline.
                  ? const TherapistChatDetailScreen(chatId: 'chat')
                  : UserTherapistChatScreen(
                      chatId: 'chat',
                      initialThread: TherapistChatThread(
                        chatId: 'chat',
                        therapistId: 'therapist',
                        userId: 'patient',
                        therapistName: 'Therapist',
                        userName: 'Patient',
                        createdAt: DateTime(2026),
                        updatedAt: DateTime(2026),
                      ),
                    ),
            ),
          ),
        );
        messages.add([
          TherapistMessage(
            id: 'message',
            senderId: 'patient',
            senderType: SenderType.user,
            content: 'Sensitive history',
            timestamp: DateTime(2026, 9, 30),
          ),
        ]);
        await tester.pumpAndSettle();
        await tester.longPress(find.text('Sensitive history'));
        await tester.pumpAndSettle();
        expect(find.text('Sensitive history'), findsNWidgets(2));

        messages.add([]);
        await tester.pumpAndSettle();
        expect(find.text('Sensitive history'), findsNothing);
        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);

        messages.add([
          TherapistMessage(
            id: 'new',
            senderId: 'therapist',
            senderType: SenderType.therapist,
            content: 'Fresh start',
            timestamp: DateTime(2026, 9, 30),
          ),
        ]);
        await tester.pumpAndSettle();
        expect(find.text('Fresh start'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await messages.close();
      },
    );
  }
}
