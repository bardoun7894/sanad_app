import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/chat/widgets/ai_privacy_consent_control.dart';
import 'package:sanad_app/features/more/static_page_screen.dart';

void main() {
  for (final language in AppLanguage.values) {
    testWidgets(
      'live privacy fallback explains processors and authorized access in ${language.name}',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              languageProvider.overrideWith(
                (ref) => LanguageNotifier(initial: language),
              ),
              aiPrivacyConsentStatusProvider.overrideWith((ref) async => false),
              staticPageDocProvider(
                'privacy_policy',
              ).overrideWith((ref) => Stream.error(StateError('offline'))),
            ],
            child: const MaterialApp(
              home: StaticPageScreen(pageType: StaticPageType.privacy),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Firebase'), findsOneWidget);
        final copy = tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data ?? '')
            .join(' ');
        expect(copy, isNot(contains('completely confidential')));
        expect(copy, isNot(contains('سرية تماماً')));
        expect(copy, contains(S(language).aiPrivacyAccessBody));
      },
    );
  }
}
