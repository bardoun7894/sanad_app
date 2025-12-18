import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';

/// Paywall overlay widget shown when user tries to access premium feature
class PaywallOverlay extends ConsumerWidget {
  final String featureName;
  final String? featureDescription;
  final VoidCallback? onClose;
  final bool isDismissible;

  const PaywallOverlay({
    Key? key,
    required this.featureName,
    this.featureDescription,
    this.onClose,
    this.isDismissible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.premiumOnly,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          featureName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDismissible)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        onClose?.call();
                      },
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),

            // Premium icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    s.subscriptionRequired,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (featureDescription != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark.withValues(alpha: 0.5)
                            : AppColors.softBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        featureDescription!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Features list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.premiumFeatures,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FeatureListItem(
                    icon: Icons.chat_outlined,
                    text: s.unlimitedChat,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _FeatureListItem(
                    icon: Icons.videocam_outlined,
                    text: s.bookTherapyCall,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _FeatureListItem(
                    icon: Icons.trending_up_outlined,
                    text: s.accessMoodTracking,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Upgrade button
                  SanadButton(
                    text: s.upgradeToPremium,
                    isFullWidth: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/subscription');
                    },
                  ),
                  const SizedBox(height: 12),
                  // Maybe later button
                  if (isDismissible)
                    SanadButton(
                      text: s.cancel,
                      variant: SanadButtonVariant.outline,
                      isFullWidth: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onClose?.call();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Individual feature list item
class _FeatureListItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _FeatureListItem({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// Show paywall overlay dialog
void showPaywallOverlay(
  BuildContext context, {
  required String featureName,
  String? featureDescription,
  VoidCallback? onClose,
  bool isDismissible = true,
}) {
  showDialog(
    context: context,
    barrierDismissible: isDismissible,
    builder: (context) => PaywallOverlay(
      featureName: featureName,
      featureDescription: featureDescription,
      onClose: onClose,
      isDismissible: isDismissible,
    ),
  );
}
