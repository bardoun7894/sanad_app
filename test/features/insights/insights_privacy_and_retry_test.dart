import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/auth/models/auth_user.dart';
import 'package:sanad_app/features/chat/services/ai_privacy_consent_service.dart';
import 'package:sanad_app/features/insights/insights_screen.dart';

void main() {
  final user = AuthUser(
    uid: 'alice',
    email: 'alice@example.test',
    createdAt: DateTime(2026),
    provider: AuthProvider.email,
  );
  testWidgets(
    'ordinary calculated insights remain available with declined Gemini consent',
    (tester) async {
      var analyses = 0;
      var consentReads = 0;
      final declinedConsent = AiPrivacyConsentService(
        currentUserId: () => 'alice',
        readConsent: (_) async {
          consentReads++;
          return {'accepted': false, 'version': aiPrivacyConsentVersion};
        },
        saveConsent: (_, expectedUserId) async =>
            fail('must not request AI consent for ordinary insights'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(user),
            languageProvider.overrideWith(
              (ref) => LanguageNotifier(initial: AppLanguage.english),
            ),
            aiPrivacyConsentServiceProvider.overrideWithValue(declinedConsent),
            insightsPatternsCallableProvider.overrideWithValue((uid) async {
              analyses++;
              return <String, dynamic>{};
            }),
          ],
          child: const MaterialApp(home: InsightsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(analyses, 1);
      expect(consentReads, 0);
      expect(find.textContaining('Google Gemini'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('insight retry replaces its future without a late-final error', (
    tester,
  ) async {
    var analyses = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          languageProvider.overrideWith(
            (ref) => LanguageNotifier(initial: AppLanguage.english),
          ),
          insightsPatternsCallableProvider.overrideWithValue((uid) async {
            analyses++;
            if (analyses == 1) throw StateError('offline');
            return <String, dynamic>{};
          }),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(analyses, 2);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
