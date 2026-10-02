import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../services/ai_privacy_consent_service.dart';

String aiPrivacyErrorMessage(
  Object error,
  S strings, {
  bool patientContext = false,
}) {
  if (isAiConsentRequiredError(error)) {
    return patientContext
        ? strings.aiPatientConsentRequired
        : strings.aiConsentRequired;
  }
  return strings.error;
}

class AiPrivacyConsentDialog extends StatelessWidget {
  final S strings;
  const AiPrivacyConsentDialog({super.key, required this.strings});

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: strings.language == AppLanguage.arabic
        ? TextDirection.rtl
        : TextDirection.ltr,
    child: AlertDialog(
      title: Text(strings.aiConsentTitle),
      content: SingleChildScrollView(child: Text(strings.aiConsentBody)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.aiConsentNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(strings.aiConsentAgree),
        ),
      ],
    ),
  );
}

/// The message is retained by the caller until explicit consent is saved.
Future<bool> ensureAiPrivacyConsent(BuildContext context, WidgetRef ref) async {
  final strings = ref.read(stringsProvider);
  final service = ref.read(aiPrivacyConsentServiceProvider);
  Object? failure;
  final allowed = await service.ensureConsent(
    prompt: () async {
      if (!context.mounted) return null;
      return showDialog<bool>(
        context: context,
        builder: (_) => AiPrivacyConsentDialog(strings: strings),
      );
    },
    onError: (error) => failure = error,
  );
  if (!allowed && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null ? strings.aiConsentRequired : strings.aiConsentError,
        ),
      ),
    );
  }
  return allowed && context.mounted;
}
