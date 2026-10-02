import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/chat/widgets/ai_privacy_consent_dialog.dart';

void main() {
  for (final language in AppLanguage.values) {
    testWidgets('explicit disclosure and decline in ${language.name}', (
      tester,
    ) async {
      bool? answer;
      final strings = S(language);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                answer = await showDialog<bool>(
                  context: context,
                  builder: (_) => AiPrivacyConsentDialog(strings: strings),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Google Gemini'), findsOneWidget);
      expect(find.text(strings.aiConsentAgree), findsOneWidget);
      await tester.tap(find.text(strings.aiConsentNotNow));
      await tester.pumpAndSettle();
      expect(answer, false);
    });
  }
  testWidgets('dismissing is not agreement', (tester) async {
    bool? answer = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showDialog<bool>(
                context: context,
                builder: (_) =>
                    AiPrivacyConsentDialog(strings: S(AppLanguage.english)),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(answer, null);
  });
}
