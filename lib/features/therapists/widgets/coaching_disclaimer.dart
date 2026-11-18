import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/store_profile.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Visible note on booking screens, shown on the Apple build only.
class CoachingDisclaimer extends ConsumerWidget {
  const CoachingDisclaimer({super.key});

  static const ar =
      'جلسات كوتشينج للتطوير الشخصي، وليست علاجاً نفسياً أو طبياً ولا تشخيصاً.';
  static const en =
      'Coaching sessions for personal development, not psychological or medical treatment or diagnosis.';
  static const fr =
      'Séances de coaching pour le développement personnel, pas un traitement psychologique ou médical ni un diagnostic.';

  static String textFor(AppLanguage l) => switch (l) {
    AppLanguage.arabic => ar,
    AppLanguage.english => en,
    AppLanguage.french => fr,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isAppleCoachingBuild) return const SizedBox.shrink();
    final lang = ref.watch(languageProvider).language;
    return Container(
      key: const Key('coaching_disclaimer'),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        textFor(lang),
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}
