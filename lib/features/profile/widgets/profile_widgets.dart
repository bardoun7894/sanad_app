import 'package:flutter/material.dart';
import '../../../core/utils/file_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../features/subscription/models/subscription_status.dart';
import '../../../features/subscription/providers/feature_gating_provider.dart';

class ProfileHeader extends ConsumerWidget {
  // Avatar / badge layout constants
  static const double _kAvatarSize = 72.0;
  static const double _kBadgeOffset = 6.0; // bottom position inside Stack

  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onEditProfile;
  final SubscriptionStatus? subscriptionStatus;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.onEditProfile,
    this.subscriptionStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(subscriptionTierProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 90,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: _kAvatarSize,
                  height: _kAvatarSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(child: _buildAvatarContent()),
                ),
                Positioned(
                  bottom: _kBadgeOffset,
                  child: _buildSubscriptionBadge(
                    tier,
                    ref.watch(languageProvider).locale.languageCode,
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.headingMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEditProfile,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      // Legacy avatar_url values point at assets/images/avatars/avatar_N.svg;
      // only the .png variants ship now. Rewrite so old accounts still render.
      final resolved = _resolveAvatarUrl(avatarUrl!);
      if (resolved.startsWith('assets/')) {
        if (resolved.toLowerCase().endsWith('.svg')) {
          return SvgPicture.asset(
            resolved,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            placeholderBuilder: (_) => _buildInitials(),
          );
        } else {
          return Image.asset(
            resolved,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitials(),
          );
        }
      }
      if (resolved.startsWith('http')) {
        return Image.network(
          resolved,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(),
        );
      }
      final filePath = resolved.replaceFirst('file://', '');
      return buildFileImageWidget(
        filePath,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(),
      );
    }
    return _buildInitials();
  }

  static String _resolveAvatarUrl(String url) {
    if (url.startsWith('assets/images/avatars/avatar_') &&
        url.toLowerCase().endsWith('.svg')) {
      return url.replaceFirst(RegExp(r'\.svg$', caseSensitive: false), '.png');
    }
    return url;
  }

  Widget _buildInitials() {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();
    return Center(
      child: Text(
        initials.isNotEmpty ? initials : 'U',
        style: AppTypography.headingMedium.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildSubscriptionBadge(
    SubscriptionTier tier,
    String langCode,
    bool isDark,
  ) {
    if (tier == SubscriptionTier.free) {
      return const SizedBox.shrink();
    }

    final bgColor = tier.tierPrimaryColor;
    final textColor = tier.tierTextOnColor;
    final label = tier.displayNameFor(langCode);

    // Shadow: halve blur/alpha in dark mode so it does not look heavy on
    // AppColors.surfaceDark.
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.20);
    final shadowBlur = isDark ? 2.0 : 4.0;

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: shadowBlur,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

class StatsCard extends StatelessWidget {
  final int sessions;
  final int moodEntries;
  final int streakDays;
  final int communityPosts;

  const StatsCard({
    super.key,
    required this.sessions,
    required this.moodEntries,
    required this.streakDays,
    required this.communityPosts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: sessions.toString(),
            label: 'Sessions',
            icon: Icons.call_outlined,
            color: AppColors.primary,
            isDark: isDark,
          ),
          _StatDivider(isDark: isDark),
          _StatItem(
            value: moodEntries.toString(),
            label: 'Moods',
            icon: Icons.emoji_emotions_outlined,
            color: AppColors.moodHappy,
            isDark: isDark,
          ),
          _StatDivider(isDark: isDark),
          _StatItem(
            value: '$streakDays',
            label: 'Day Streak',
            icon: Icons.local_fire_department_outlined,
            color: AppColors.moodAnxious,
            isDark: isDark,
          ),
          _StatDivider(isDark: isDark),
          _StatItem(
            value: communityPosts.toString(),
            label: 'Posts',
            icon: Icons.chat_bubble_outline,
            color: AppColors.moodCalm,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  final bool isDark;

  const _StatDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 45,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsToggleItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const SettingsToggleItem({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onChanged(!value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    color: value
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 64,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
      ],
    );
  }
}

class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isDestructive;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.showDivider = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = isDestructive
        ? AppColors.error
        : (iconColor ?? AppColors.primary);
    final effectiveTextColor = isDestructive
        ? AppColors.error
        : (isDark ? Colors.white : AppColors.textPrimary);

    return Column(
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: effectiveIconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.labelLarge.copyWith(
                          color: effectiveTextColor,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 64,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
      ],
    );
  }
}
