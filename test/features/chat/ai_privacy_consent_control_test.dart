import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/chat/services/ai_privacy_consent_service.dart';
import 'package:sanad_app/features/chat/widgets/ai_privacy_consent_control.dart';

void main() {
  testWidgets(
    'privacy control revokes via service and confirms human chat remains',
    (tester) async {
      bool? saved;
      final service = AiPrivacyConsentService(
        currentUserId: () => 'alice',
        readConsent: (_) async => {
          'accepted': true,
          'version': aiPrivacyConsentVersion,
        },
        saveConsent: (accepted, expectedUserId) async {
          saved = accepted;
          return {'accepted': accepted, 'version': aiPrivacyConsentVersion};
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiPrivacyConsentServiceProvider.overrideWithValue(service),
            aiPrivacyConsentStatusProvider.overrideWith((ref) async => true),
            languageProvider.overrideWith(
              (ref) => LanguageNotifier(initial: AppLanguage.english),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AiPrivacyConsentControl()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revoke AI consent'));
      await tester.pumpAndSettle();
      expect(saved, false);
      expect(
        find.textContaining('Human chats remain available'),
        findsOneWidget,
      );
    },
  );
  testWidgets('failed revocation never claims success', (tester) async {
    final service = AiPrivacyConsentService(
      currentUserId: () => 'alice',
      readConsent: (_) async => {
        'accepted': true,
        'version': aiPrivacyConsentVersion,
      },
      saveConsent: (_, expectedUserId) async => throw StateError('offline'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiPrivacyConsentServiceProvider.overrideWithValue(service),
          aiPrivacyConsentStatusProvider.overrideWith((ref) async => true),
          languageProvider.overrideWith(
            (ref) => LanguageNotifier(initial: AppLanguage.english),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AiPrivacyConsentControl()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revoke AI consent'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Consent revoked.'), findsNothing);
    expect(find.textContaining('could not'), findsOneWidget);
  });
}
