import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/subscription_status.dart';
import '../providers/subscription_provider.dart';
import '../providers/feature_gating_provider.dart';

/// Badge showing premium subscription status
class PremiumBadge extends ConsumerWidget {
  final double size;
  final bool showText;

  const PremiumBadge({Key? key, this.size = 24, this.showText = false})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final tier = ref.watch(subscriptionTierProvider);

    if (!subscription.isPremium) {
      return const SizedBox.shrink();
    }

    final tierColor = tier.tierPrimaryColor;
    final langCode = ref.watch(languageProvider).locale.languageCode;
    final tierLabel = tier.displayNameFor(langCode);

    if (showText) {
      return Semantics(
        label: tierLabel,
        // excludeSemantics prevents the inner Text from being read twice
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tierColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tierColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tier.tierIcon, size: size, color: tierColor),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tierLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.buttonSmall.copyWith(
                      color: tierColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      label: tierLabel,
      excludeSemantics: true,
      child: Icon(tier.tierIcon, size: size, color: tierColor),
    );
  }
}

/// Premium badge with subscription details
class PremiumBadgeWithDetails extends ConsumerWidget {
  final double iconSize;

  const PremiumBadgeWithDetails({Key? key, this.iconSize = 20})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final tier = ref.watch(subscriptionTierProvider);

    if (!subscription.isPremium) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tierColor = tier.tierPrimaryColor;
    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider).locale.languageCode;
    final tierLabel = tier.displayNameFor(langCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2A24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tier.tierIconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(tier.tierIcon, size: 28, color: tierColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: tierLabel,
                child: Text(
                  tierLabel,
                  style: AppTypography.labelLarge.copyWith(
                    color: tierColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (subscription.status.expiryDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${s.validUntil} ',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                    // Wrap date in LTR directionality so punctuation does not
                    // flip in Arabic (RTL) paragraphs.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        _formatDate(subscription.status.expiryDate!),
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subscription.status.state ==
                    SubscriptionState.cancelled) ...[
                  const SizedBox(height: 2),
                  Text(
                    s.autoRenewOff,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? Colors.white60
                          : AppColors.textSecondary.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Inline premium feature indicator
class PremiumFeatureTag extends ConsumerWidget {
  final double height;

  const PremiumFeatureTag({Key? key, this.height = 20}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(subscriptionTierProvider);
    final tierColor = tier.tierPrimaryColor;
    final langCode = ref.watch(languageProvider).locale.languageCode;
    final tierLabel = tier.displayNameFor(langCode);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tier.tierIcon, size: height - 4, color: tierColor),
          const SizedBox(width: 4),
          Text(
            tierLabel,
            style: AppTypography.buttonSmall.copyWith(
              color: tierColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

