import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/chat/widgets/ai_privacy_consent_dialog.dart';

void main() {
  for (final language in AppLanguage.values) {
    test(
      'consent denial explains patient consent in ${language.name} without exposing raw error',
      () {
        final strings = S(language);
        final error = FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'private raw error',
          details: {'reason': 'ai-consent-required', 'version': '2026-10-01'},
        );
        expect(
          aiPrivacyErrorMessage(error, strings, patientContext: true),
          strings.aiPatientConsentRequired,
        );
        expect(
          aiPrivacyErrorMessage(error, strings),
          strings.aiConsentRequired,
        );
        expect(
          aiPrivacyErrorMessage(
            StateError('private raw error'),
            strings,
            patientContext: true,
          ),
          strings.error,
        );
      },
    );
  }
}
