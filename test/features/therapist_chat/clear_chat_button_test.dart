import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/therapist_chat/providers/therapist_chat_provider.dart';
import 'package:sanad_app/features/therapist_chat/services/therapist_chat_service.dart';
import 'package:sanad_app/features/therapist_chat/widgets/clear_chat_button.dart';

class _ChatService extends TherapistChatService {
  _ChatService() : super(firestore: FakeFirebaseFirestore());
  final completion = Completer<int>();
  final calls = <String>[];

  @override
  Future<int> clearChat(String chatId) {
    calls.add(chatId);
    return completion.future;
  }
}

void main() {
  Future<void> pumpButton(
    WidgetTester tester,
    _ChatService service,
    AppLanguage language, {
    bool showButton = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stringsProvider.overrideWithValue(S(language)),
          therapistChatServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: language == AppLanguage.arabic
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: showButton
                  ? const ClearChatButton(chatId: 'therapist_patient')
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  for (final language in AppLanguage.values) {
    testWidgets('cancel leaves messages untouched in ${language.name}', (
      tester,
    ) async {
      final service = _ChatService();
      final s = S(language);
      await pumpButton(tester, service, language);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text(s.clearChatConfirmTitle), findsOneWidget);
      expect(find.text(s.clearChatConfirmBody), findsOneWidget);
      expect(service.calls, isEmpty);
      await tester.tap(find.text(s.cancel));
      await tester.pumpAndSettle();
      expect(service.calls, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    });
  }

  testWidgets('shows completion if the row moves away during clearing', (
    tester,
  ) async {
    final service = _ChatService();
    final s = S(AppLanguage.english);
    await pumpButton(tester, service, AppLanguage.english);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.clearChatDelete));
    await tester.pump();
    await pumpButton(tester, service, AppLanguage.english, showButton: false);
    service.completion.complete(1);
    await tester.pumpAndSettle();
    expect(find.text(s.clearChatSuccess), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirm calls service once, disables button, shows success', (
    tester,
  ) async {
    final service = _ChatService();
    final s = S(AppLanguage.arabic);
    await pumpButton(tester, service, AppLanguage.arabic);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    final delete = find.widgetWithText(TextButton, s.clearChatDelete);
    expect(
      tester.widget<TextButton>(delete).style!.foregroundColor!.resolve({}),
      Colors.red,
    );
    await tester.tap(delete);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.calls, ['therapist_patient']);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    service.completion.complete(12);
    await tester.pumpAndSettle();
    expect(find.text(s.clearChatSuccess), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('service failure shows localized error and permits retry', (
    tester,
  ) async {
    final service = _ChatService();
    final s = S(AppLanguage.english);
    await pumpButton(tester, service, AppLanguage.english);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.clearChatDelete));
    await tester.pump();
    service.completion.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text(s.clearChatError), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNotNull,
    );
  });
}
