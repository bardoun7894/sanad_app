import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/ai_privacy_consent_service.dart';
import 'ai_privacy_consent_dialog.dart';

final aiPrivacyConsentStatusProvider = FutureProvider.autoDispose<bool>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(aiPrivacyConsentServiceProvider).hasConsent();
});

class AiPrivacyConsentControl extends ConsumerStatefulWidget {
  const AiPrivacyConsentControl({super.key});

  @override
  ConsumerState<AiPrivacyConsentControl> createState() =>
      _AiPrivacyConsentControlState();
}

class _AiPrivacyConsentControlState
    extends ConsumerState<AiPrivacyConsentControl> {
  bool _saving = false;

  Future<void> _revoke() async {
    setState(() => _saving = true);
    final strings = ref.read(stringsProvider);
    try {
      await ref.read(aiPrivacyConsentServiceProvider).setConsent(false);
      ref.invalidate(aiPrivacyConsentStatusProvider);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.aiConsentRevoked)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.aiConsentRevokeError)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final status = ref.watch(aiPrivacyConsentStatusProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: status.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.aiConsentError),
            TextButton(
              onPressed: () => ref.invalidate(aiPrivacyConsentStatusProvider),
              child: Text(strings.retry),
            ),
          ],
        ),
        data: (accepted) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.aiConsentTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              accepted ? strings.aiConsentEnabled : strings.aiConsentDisabled,
            ),
            if (_saving) const LinearProgressIndicator(),
            TextButton(
              onPressed: _saving
                  ? null
                  : accepted
                  ? _revoke
                  : () async {
                      await ensureAiPrivacyConsent(context, ref);
                      if (mounted)
                        ref.invalidate(aiPrivacyConsentStatusProvider);
                    },
              child: Text(
                accepted ? strings.aiConsentRevoke : strings.aiConsentAgree,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
