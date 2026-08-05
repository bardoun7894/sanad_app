import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../routes/app_routes.dart';
import '../../therapists/models/therapist.dart';
import '../../therapists/providers/therapist_provider.dart';
import '../providers/nudge_recommendation_provider.dart';

/// Shows the personalized subscription nudge bottom sheet.
///
/// The caller is responsible for eligibility (not premium, cooldown) and for
/// recording that the nudge was shown. Always dismissible.
Future<void> showSubscriptionNudge(
  BuildContext context,
  WidgetRef ref,
  NudgeRecommendation rec,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _NudgeSheet(rec: rec, parentRef: ref),
  );
}

class _NudgeSheet extends ConsumerWidget {
  final NudgeRecommendation rec;
  final WidgetRef parentRef;

  const _NudgeSheet({required this.rec, required this.parentRef});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider).language.code;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final therapist = rec.therapist;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing2xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing2xl),

          // Emotional hook line (mood / interest / generic).
          Row(
            children: [
              Icon(Icons.favorite_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rec.reasonLine,
                  style: AppTypography.headingSmall.copyWith(
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            s.nudgeSupportLine,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2xl),

          // Matched therapist (the reward).
          if (therapist != null)
            _TherapistRow(therapist: therapist, langCode: langCode),
          if (therapist != null)
            const SizedBox(height: AppTheme.spacing2xl),

          // Primary CTA — subscribe.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.subscription);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                s.nudgeSubscribeCta,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Secondary CTA — book the matched therapist.
          if (therapist != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  parentRef.read(selectedTherapistProvider.notifier).state =
                      therapist;
                  Navigator.of(context).pop();
                  context.push(AppRoutes.therapistProfile);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  s.nudgeBookCta,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacingSm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              s.nudgeMaybeLater,
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TherapistRow extends StatelessWidget {
  final Therapist therapist;
  final String langCode;

  const _TherapistRow({required this.therapist, required this.langCode});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = therapist.imageUrl;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    )
                  : _avatarFallback(),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  therapist.localizedName(langCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  therapist.localizedTitle(langCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        isDark ? AppColors.textMuted : AppColors.textMutedLight,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      therapist.rating.toStringAsFixed(1),
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppColors.textLight : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: AppColors.primary.withValues(alpha: 0.12),
        child: const Icon(Icons.person_rounded,
            size: 32, color: AppColors.primary),
      );
}
