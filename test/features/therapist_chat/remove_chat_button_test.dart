import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/therapist_chat/providers/therapist_chat_provider.dart';
import 'package:sanad_app/features/therapist_chat/services/therapist_chat_service.dart';
import 'package:sanad_app/features/therapist_chat/widgets/remove_chat_button.dart';

class _Service implements TherapistChatService {
  final hidden = <String>[];
  var cleared = 0;

  @override
  Future<void> hideChatForTherapist(String chatId) async => hidden.add(chatId);

  @override
  Future<int> clearChat(String chatId) async {
    cleared++;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final s = S(AppLanguage.arabic);

  Future<_Service> pump(WidgetTester tester) async {
    final service = _Service();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stringsProvider.overrideWithValue(s),
          therapistChatServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(
          home: Scaffold(body: RemoveChatButton(chatId: 'c1')),
        ),
      ),
    );
    return service;
  }

  testWidgets('cancel does not hide the chat', (tester) async {
    final service = await pump(tester);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('إزالة المحادثة من قائمتك؟'), findsOneWidget);
    await tester.tap(find.text(s.cancel));
    await tester.pumpAndSettle();
    expect(service.hidden, isEmpty);
  });

  testWidgets('confirm hides for therapist without clearing', (tester) async {
    final service = await pump(tester);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.clearChatDelete));
    await tester.pumpAndSettle();
    expect(service.hidden, ['c1']);
    expect(service.cleared, 0);
  });
}
