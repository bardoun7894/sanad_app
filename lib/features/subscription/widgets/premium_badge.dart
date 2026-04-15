import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/subscription_provider.dart';

/// Badge showing premium subscription status
class PremiumBadge extends ConsumerWidget {
  final double size;
  final bool showText;

  const PremiumBadge({Key? key, this.size = 24, this.showText = false})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    if (!subscription.isPremium) {
      return const SizedBox.shrink();
    }

    if (showText) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: size, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Premium',
              style: AppTypography.buttonSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Just the icon
    return Icon(Icons.star_rounded, size: size, color: AppColors.primary);
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

    if (!subscription.isPremium) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2A24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3B0), // Light yellow circle bg for icon
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 28,
              color: Color(0xFFFFD700), // Gold star
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'عضو سند الذهبي', // Translated Sanad Premium Member
                style: AppTypography.labelLarge.copyWith(
                  color: const Color(0xFFB8860B), // Dark gold text
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              if (subscription.status.expiryDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'صالح حتى ${_formatDate(subscription.status.expiryDate!)}', // Translated Valid until
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
class PremiumFeatureTag extends StatelessWidget {
  final double height;

  const PremiumFeatureTag({Key? key, this.height = 20}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: height - 4, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: AppTypography.buttonSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
