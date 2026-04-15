import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_app/routes/app_routes.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';

class ProfileProgressCard extends ConsumerWidget {
  final double progress;
  final VoidCallback? onDismiss;
  final bool showWhenComplete;
  final EdgeInsetsGeometry? margin;

  const ProfileProgressCard({
    super.key,
    required this.progress,
    this.onDismiss,
    this.showWhenComplete = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If progress is 100% and we shouldn't show it when complete, hide the card
    if (progress >= 1.0 && !showWhenComplete) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int percentage = (progress * 100).toInt();
    final bool isComplete = progress >= 1.0;

    final s = ref.watch(stringsProvider);

    // Use generic text for 'complete' state since we don't have dedicated localized strings for this specific state yet.
    final String titleText = isComplete
        ? 'Profile Complete'
        : s.completeProfile;
    final String descText = isComplete
        ? 'Awesome! Your profile is 100% set up.'
        : s.helpUsKnowYou;

    final String completeNow = s.next;

    return Container(
      margin:
          margin ??
          const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingXl,
            vertical: AppTheme.spacingMd,
          ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isComplete
              ? AppColors.moodHappy.withValues(alpha: 0.5)
              : AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? AppColors.moodHappy : AppColors.primary)
                .withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (isComplete) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.moodHappy,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        titleText,
                        style: AppTypography.headingSmall.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            descText,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white12
                        : (isComplete ? AppColors.moodHappy : AppColors.primary)
                              .withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? AppColors.moodHappy : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                '$percentage%',
                style: AppTypography.labelMedium.copyWith(
                  color: isComplete ? AppColors.moodHappy : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isComplete) ...[
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.profileCompletion),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  completeNow,
                  style: AppTypography.labelLarge.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
