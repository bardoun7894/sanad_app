import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sanad_button.dart';
import '../../core/widgets/login_prompt.dart';
import '../../core/l10n/language_provider.dart';
import '../../routes/app_router.dart';
import '../auth/providers/auth_provider.dart';
import '../subscription/providers/subscription_provider.dart';
import 'models/therapist.dart';
import 'providers/therapist_provider.dart';
import 'widgets/booking_sheet.dart';

class TherapistProfileScreen extends ConsumerWidget {
  const TherapistProfileScreen({super.key});

  Future<void> _showBookingSheet(BuildContext context, WidgetRef ref, Therapist therapist) async {
    final authState = ref.read(authProvider);
    final s = ref.read(stringsProvider);

    // Check if user is logged in
    if (!authState.isAuthenticated) {
      // Show login prompt
      final shouldLogin = await showLoginPrompt(
        context,
        feature: s.bookSession,
        description: s.loginToBook,
      );

      // If user chose not to login, don't proceed
      if (shouldLogin != true) return;

      // After login prompt, check auth again
      final newAuthState = ref.read(authProvider);
      if (!newAuthState.isAuthenticated) return;
    }

    // Check if user has subscription
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      // Show subscription required dialog
      if (context.mounted) {
        _showSubscriptionRequired(context, s);
      }
      return;
    }

    // User is authenticated and has subscription, show booking sheet
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BookingSheet(therapist: therapist),
      );
    }
  }

  void _showSubscriptionRequired(BuildContext context, dynamic s) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.workspace_premium_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              s.subscriptionRequired,
              style: AppTypography.headingMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              s.subscribeToBook,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SanadButton(
              text: s.subscribe,
              isFullWidth: true,
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.subscription);
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.maybeLater),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final therapist = ref.watch(selectedTherapistProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    if (therapist == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(child: Text(s.therapistNotFound)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 18,
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            therapist.name
                                .split(' ')
                                .map((e) => e[0])
                                .take(2)
                                .join(),
                            style: AppTypography.headingLarge.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        therapist.name,
                        style: AppTypography.headingMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        therapist.title,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick stats
                  _QuickStats(therapist: therapist, isDark: isDark, strings: s),
                  const SizedBox(height: 24),

                  // About section
                  _SectionTitle(title: s.about, isDark: isDark),
                  const SizedBox(height: 12),
                  Text(
                    therapist.bio,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Specialties
                  _SectionTitle(title: s.specialties, isDark: isDark),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: therapist.specialties.map((specialty) {
                      final color = SpecialtyData.getColor(specialty);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? color.withValues(alpha: 0.2)
                              : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              SpecialtyData.getIcon(specialty),
                              size: 16,
                              color: color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              SpecialtyData.getLabel(specialty, strings: s),
                              style: AppTypography.labelSmall.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Session types
                  _SectionTitle(title: s.sessionTypes, isDark: isDark),
                  const SizedBox(height: 12),
                  Row(
                    children: therapist.sessionTypes.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                SessionTypeData.getIcon(type),
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                SessionTypeData.getLabel(type, strings: s),
                                style: AppTypography.labelMedium.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Languages
                  _SectionTitle(title: s.languages, isDark: isDark),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: therapist.languages.map((lang) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          lang,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.textDark : AppColors.textLight,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Qualifications
                  _SectionTitle(title: s.qualifications, isDark: isDark),
                  const SizedBox(height: 12),
                  ...therapist.qualifications.map((qual) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 18,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              qual,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Reviews
                  if (therapist.reviews.isNotEmpty) ...[
                    Row(
                      children: [
                        _SectionTitle(title: s.reviews, isDark: isDark),
                        const Spacer(),
                        Text(
                          '${s.seeAllReviews} (${therapist.reviewCount})',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...therapist.reviews.take(2).map((review) {
                      return _ReviewCard(review: review, isDark: isDark);
                    }),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BookingBar(
        therapist: therapist,
        isDark: isDark,
        onBook: () => _showBookingSheet(context, ref, therapist),
        strings: s,
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final Therapist therapist;
  final bool isDark;
  final S strings;

  const _QuickStats({
    required this.therapist,
    required this.isDark,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
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
            icon: Icons.star_rounded,
            iconColor: AppColors.moodHappy,
            value: therapist.rating.toStringAsFixed(1),
            label: '${therapist.reviewCount} ${strings.reviews}',
            isDark: isDark,
          ),
          _StatDivider(isDark: isDark),
          _StatItem(
            icon: Icons.work_outline_rounded,
            iconColor: AppColors.primary,
            value: '${therapist.yearsExperience}',
            label: strings.yearsExp,
            isDark: isDark,
          ),
          _StatDivider(isDark: isDark),
          _StatItem(
            icon: Icons.people_outline_rounded,
            iconColor: AppColors.moodCalm,
            value: '${(therapist.reviewCount * 2.5).toInt()}+',
            label: strings.patients,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.headingSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textLight,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
          ),
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
      height: 50,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.headingSmall.copyWith(
        color: isDark ? Colors.white : AppColors.textLight,
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final bool isDark;

  const _ReviewCard({required this.review, required this.isDark});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.softBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.authorName[0],
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textLight,
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.moodHappy,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.textDark : AppColors.textLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  final Therapist therapist;
  final bool isDark;
  final VoidCallback onBook;
  final S strings;

  const _BookingBar({
    required this.therapist,
    required this.isDark,
    required this.onBook,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  therapist.formattedPrice,
                  style: AppTypography.headingMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  strings.perSession,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SanadButton(
                text: strings.bookSession,
                icon: Icons.calendar_today_rounded,
                onPressed: onBook,
                size: SanadButtonSize.large,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
