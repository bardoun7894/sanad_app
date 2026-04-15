import 'package:flutter/material.dart';
import '../../../core/utils/file_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../engagement/widgets/streak_badge.dart';
import '../../subscription/providers/feature_gating_provider.dart';

/// Enhanced header with time-based greeting and streak indicator
class GreetingHeader extends ConsumerWidget {
  final String userName;
  final String? avatarUrl;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final bool isPremium;
  final SubscriptionTier subscriptionTier;

  const GreetingHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onAvatarTap,
    this.isPremium = false,
    this.subscriptionTier = SubscriptionTier.free,
  });

  String _getTimeBasedGreeting(S s) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return s.goodMorning;
    } else if (hour < 17) {
      return s.goodAfternoon;
    } else if (hour < 21) {
      return s.goodEvening;
    } else {
      return s.goodNight;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final greeting = _getTimeBasedGreeting(s);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingXl,
        0,
        AppTheme.spacingXl,
        AppTheme.spacingLg,
      ),
      child: Row(
        children: [
          // Avatar and greeting
          Expanded(
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Row(
                children: [
                  _Avatar(
                    name: userName,
                    imageUrl: avatarUrl,
                    isPremium: isPremium,
                    subscriptionTier: subscriptionTier,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              greeting,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const StreakIndicator(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName,
                          style: AppTypography.headingMedium.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Notification button
          _NotificationButton(
            count: notificationCount,
            onTap: onNotificationTap,
          ),
        ],
      ),
    );
  }
}

/// Badge configuration for each subscription tier
class _TierBadgeConfig {
  final String labelAr;
  final String labelEn;
  final String labelFr;
  final Color gradientStart;
  final Color gradientEnd;
  final Color textColor;
  final Color ringColor;

  const _TierBadgeConfig({
    required this.labelAr,
    required this.labelEn,
    required this.labelFr,
    required this.gradientStart,
    required this.gradientEnd,
    required this.textColor,
    required this.ringColor,
  });

  static _TierBadgeConfig forTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return const _TierBadgeConfig(
          labelAr: 'مجاني',
          labelEn: 'FREE',
          labelFr: 'GRATUIT',
          gradientStart: Color(0xFFCBD5E1),
          gradientEnd: Color(0xFF94A3B8),
          textColor: Color(0xFF475569),
          ringColor: Color(0xFFCBD5E1),
        );
      case SubscriptionTier.weekly:
        return const _TierBadgeConfig(
          labelAr: 'أسبوعي',
          labelEn: 'WEEK',
          labelFr: 'SEMAINE',
          gradientStart: Color(0xFF38BDF8),
          gradientEnd: Color(0xFF0284C7),
          textColor: Colors.white,
          ringColor: Color(0xFF7DD3FC),
        );
      case SubscriptionTier.basic:
        return const _TierBadgeConfig(
          labelAr: 'أساسي',
          labelEn: 'BASIC',
          labelFr: 'BASIQUE',
          gradientStart: Color(0xFF34D399),
          gradientEnd: Color(0xFF059669),
          textColor: Colors.white,
          ringColor: Color(0xFF6EE7B7),
        );
      case SubscriptionTier.premium:
        return const _TierBadgeConfig(
          labelAr: 'مميز',
          labelEn: 'PREMIUM',
          labelFr: 'PREMIUM',
          gradientStart: Color(0xFFF59E0B),
          gradientEnd: Color(0xFFB45309),
          textColor: Colors.white,
          ringColor: Color(0xFFFBBF24),
        );
      case SubscriptionTier.premiumVip:
        return const _TierBadgeConfig(
          labelAr: 'VIP مميز',
          labelEn: 'PREMIUM VIP',
          labelFr: 'VIP PREMIUM',
          gradientStart: Color(0xFFFDE047),
          gradientEnd: Color(0xFFF59E0B),
          textColor: Color(0xFF713F12),
          ringColor: Color(0xFFFDE68A),
        );
    }
  }

  String label(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return labelAr;
      case 'fr':
        return labelFr;
      default:
        return labelEn;
    }
  }
}

class _Avatar extends ConsumerWidget {
  final String name;
  final String? imageUrl;
  final bool isPremium;
  final SubscriptionTier subscriptionTier;

  const _Avatar({
    required this.name,
    this.imageUrl,
    this.isPremium = false,
    this.subscriptionTier = SubscriptionTier.free,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final langState = ref.watch(languageProvider);
    final languageCode = langState.locale.languageCode;
    final badgeConfig = _TierBadgeConfig.forTier(subscriptionTier);
    final isPaidTier = subscriptionTier.isPaid;
    final scaffoldBg =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    // Ring color: tier color for paid, subtle gray for free
    final ringColor = isPaidTier
        ? badgeConfig.ringColor
        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1));

    return SizedBox(
      width: 62,
      height: isPaidTier ? 66 : 56,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Outer decorative ring (like Image #4)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ringColor.withValues(alpha: isPaidTier ? 0.7 : 0.4),
                width: 2,
              ),
            ),
            child: Center(
              // Inner avatar with gap
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildAvatarImage(initial, isDark),
                ),
              ),
            ),
          ),

          // Subscription badge pill
          if (isPaidTier)
            Positioned(
              bottom: 0,
              child: _SubscriptionBadge(
                config: badgeConfig,
                languageCode: languageCode,
                scaffoldBg: scaffoldBg,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String initial, bool isDark) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _InitialAvatar(initial: initial, isDark: isDark);
    }

    // SVG asset avatars
    if (imageUrl!.startsWith('assets/') &&
        imageUrl!.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        imageUrl!,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
      );
    }

    // Regular asset images
    if (imageUrl!.startsWith('assets/')) {
      return Image.asset(
        imageUrl!,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _InitialAvatar(initial: initial, isDark: isDark),
      );
    }

    // Network images (http/https)
    if (imageUrl!.startsWith('http')) {
      return Image.network(
        imageUrl!,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _InitialAvatar(initial: initial, isDark: isDark),
      );
    }

    // Local file (file:// or path from image picker)
    final filePath = imageUrl!.replaceFirst('file://', '');
    return buildFileImageWidget(
      filePath,
      width: 46,
      height: 46,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          _InitialAvatar(initial: initial, isDark: isDark),
    );
  }
}

/// The actual badge widget — pill with gradient, highlight, shadow
class _SubscriptionBadge extends StatelessWidget {
  final _TierBadgeConfig config;
  final String languageCode;
  final Color scaffoldBg;

  const _SubscriptionBadge({
    required this.config,
    required this.languageCode,
    required this.scaffoldBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Outer white ring to separate from avatar
        border: Border.all(color: scaffoldBg, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: config.gradientEnd.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: config.gradientStart.withValues(alpha: 0.3),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              config.gradientStart,
              config.gradientEnd,
            ],
          ),
        ),
        child: Text(
          config.label(languageCode),
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            color: config.textColor,
            letterSpacing: 0.6,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;
  final bool isDark;

  const _InitialAvatar({required this.initial, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E3A5F), const Color(0xFF0F172A)]
              : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTypography.headingMedium.copyWith(
            color: isDark ? const Color(0xFF7DD3FC) : AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _NotificationButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.soft,
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.notifications_outlined,
                size: 24,
                color: isDark ? AppColors.textMuted : AppColors.textSecondary,
              ),
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.backgroundDark : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
