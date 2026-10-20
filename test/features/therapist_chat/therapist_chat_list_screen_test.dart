import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/auth/models/auth_user.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/therapist_chat/models/therapist_chat.dart';
import 'package:sanad_app/features/therapist_chat/providers/therapist_chat_provider.dart';
import 'package:sanad_app/features/therapist_chat/screens/therapist_chat_list_screen.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
      : super(
          AuthState(
            status: AuthStatus.authenticated,
            user: AuthUser(
              uid: 't1',
              email: 'therapist@sanad.app',
              displayName: 'Dr. Therapist',
              role: UserRole.therapist,
              createdAt: DateTime(2026),
              provider: AuthProvider.email,
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets(
    'filters out hidden chats and booking-source chats from therapist list',
    (tester) async {
      final now = DateTime.now();

      final chatVisible = TherapistChatThread(
        chatId: 'chat_visible',
        therapistId: 't1',
        userId: 'u1',
        therapistName: 'Dr. Therapist',
        userName: 'Assigned Patient',
        status: ChatThreadStatus.active,
        source: ChatSource.direct,
        createdAt: now,
        updatedAt: now,
        lastMessage: 'Hello doctor',
        lastMessageTime: now,
        hiddenForTherapist: false,
      );

      final chatHidden = TherapistChatThread(
        chatId: 'chat_hidden',
        therapistId: 't1',
        userId: 'u2',
        therapistName: 'Dr. Therapist',
        userName: 'Hidden Patient',
        status: ChatThreadStatus.active,
        source: ChatSource.direct,
        createdAt: now,
        updatedAt: now,
        lastMessage: 'Deleted chat',
        lastMessageTime: now,
        hiddenForTherapist: true,
      );

      final chatBooking = TherapistChatThread(
        chatId: 'chat_booking',
        therapistId: 't1',
        userId: 'u3',
        therapistName: 'Dr. Therapist',
        userName: 'Booked Patient',
        status: ChatThreadStatus.active,
        source: ChatSource.booking,
        createdAt: now,
        updatedAt: now,
        lastMessage: 'Booked session chat',
        lastMessageTime: now,
        hiddenForTherapist: false,
      );

      final List<TherapistChatThread> chats = [
        chatVisible,
        chatHidden,
        chatBooking,
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier()),
            stringsProvider.overrideWithValue(S(AppLanguage.arabic)),
            therapistChatsProvider('t1').overrideWith(
              (ref) => Stream.value(chats),
            ),
          ],
          child: const MaterialApp(
            home: TherapistChatListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Assigned Patient'), findsOneWidget);
      expect(find.text('Hidden Patient'), findsNothing);
      expect(find.text('Booked Patient'), findsNothing);
    },
  );
}
