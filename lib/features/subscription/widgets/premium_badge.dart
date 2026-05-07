import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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

    final tierColor = _tierColor(tier);
    final tierLabel = _tierLabelAr(tier);

    if (showText) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tierColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tierColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: size, color: tierColor),
            const SizedBox(width: 6),
            Text(
              tierLabel,
              style: AppTypography.buttonSmall.copyWith(
                color: tierColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Icon(Icons.star_rounded, size: size, color: tierColor);
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
    final tierColor = _tierColor(tier);
    final tierLabel = _tierLabelAr(tier);
    final tierIconBg = _tierIconBg(tier);

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
              color: tierIconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(_tierIcon(tier), size: 28, color: tierColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tierLabel,
                style: AppTypography.labelLarge.copyWith(
                  color: tierColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              if (subscription.status.expiryDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'صالح حتى ${_formatDate(subscription.status.expiryDate!)}',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
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
    final tierColor = _tierColor(tier);
    final tierLabel = tier.displayName;

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
          Icon(Icons.star_rounded, size: height - 4, color: tierColor),
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

Color _tierColor(SubscriptionTier tier) {
  switch (tier) {
    case SubscriptionTier.premiumVip:
      return const Color(0xFFFFD700);
    case SubscriptionTier.premium:
      return const Color(0xFFB8860B);
    case SubscriptionTier.basic:
      return const Color(0xFF4CAF50);
    case SubscriptionTier.weekly:
      return const Color(0xFF0088FF);
    case SubscriptionTier.free:
      return AppColors.textSecondary;
  }
}

Color _tierIconBg(SubscriptionTier tier) {
  switch (tier) {
    case SubscriptionTier.premiumVip:
      return const Color(0xFFFFF3B0);
    case SubscriptionTier.premium:
      return const Color(0xFFFFE0B2);
    case SubscriptionTier.basic:
      return const Color(0xFFE8F5E9);
    case SubscriptionTier.weekly:
      return const Color(0xFFE3F2FD);
    case SubscriptionTier.free:
      return Colors.grey.shade200;
  }
}

IconData _tierIcon(SubscriptionTier tier) {
  switch (tier) {
    case SubscriptionTier.premiumVip:
      return Icons.workspace_premium_rounded;
    case SubscriptionTier.premium:
      return Icons.star_rounded;
    case SubscriptionTier.basic:
      return Icons.verified_rounded;
    case SubscriptionTier.weekly:
      return Icons.timer_rounded;
    case SubscriptionTier.free:
      return Icons.circle_outlined;
  }
}

String _tierLabelAr(SubscriptionTier tier) {
  switch (tier) {
    case SubscriptionTier.premiumVip:
      return 'عضو VIP';
    case SubscriptionTier.premium:
      return 'عضو ذهبي';
    case SubscriptionTier.basic:
      return 'عضو أساسي';
    case SubscriptionTier.weekly:
      return 'عضو أسبوعي';
    case SubscriptionTier.free:
      return 'مجاني';
  }
}
