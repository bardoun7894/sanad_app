import 'dart:async';
import 'dart:math';

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

/// A single slide in the promo carousel — either a therapist ad or a
/// "go premium" upsell.
sealed class _PromoSlide {
  const _PromoSlide();
}

class _TherapistSlide extends _PromoSlide {
  final Therapist therapist;
  const _TherapistSlide(this.therapist);
}

class _PremiumSlide extends _PromoSlide {
  const _PremiumSlide();
}

/// Auto-playing promo/ads carousel shown near the bottom of the home feed.
///
/// Blends therapist ads with a premium upsell in a shuffled ("random") order,
/// auto-advances every few seconds, and lets the user tap through to book a
/// therapist or open the subscription screen. Renders nothing while therapists
/// are still loading or unavailable, so it never leaves an empty gap.
class PromoCarousel extends ConsumerStatefulWidget {
  const PromoCarousel({super.key});

  @override
  ConsumerState<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends ConsumerState<PromoCarousel> {
  static const _slideInterval = Duration(seconds: 5);
  static const _maxTherapistSlides = 6;

  final PageController _controller = PageController();
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  // Built once per screen mount so the shuffle order stays stable while the
  // user scrolls, instead of re-randomising on every rebuild.
  List<_PromoSlide>? _slides;

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  List<_PromoSlide> _buildSlides(List<Therapist> therapists) {
    final shuffled = List<Therapist>.from(therapists)..shuffle(Random());
    final slides = <_PromoSlide>[
      for (final t in shuffled.take(_maxTherapistSlides)) _TherapistSlide(t),
    ];
    // Drop the premium upsell roughly in the middle so it never feels like the
    // whole section is just a paywall.
    final insertAt = slides.isEmpty ? 0 : (slides.length / 2).floor();
    slides.insert(insertAt, const _PremiumSlide());
    return slides;
  }

  void _startAutoPlay(int slideCount) {
    _autoPlayTimer?.cancel();
    if (slideCount <= 1) return;
    _autoPlayTimer = Timer.periodic(_slideInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_currentPage + 1) % slideCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _openTherapist(Therapist therapist) {
    ref.read(selectedTherapistProvider.notifier).state = therapist;
    context.push(AppRoutes.therapistProfile);
  }

  void _openPremium() => context.push(AppRoutes.subscription);

  @override
  Widget build(BuildContext context) {
    final therapists = ref.watch(therapistProvider).therapists;
    if (therapists.isEmpty) return const SizedBox.shrink();

    final s = ref.watch(stringsProvider);
    final langCode = ref.watch(languageProvider).language.code;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final slides = _slides ??= _buildSlides(therapists);
    if (slides.isEmpty) return const SizedBox.shrink();

    // Kick off auto-play after the first frame so PageController is attached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoPlayTimer == null) _startAutoPlay(slides.length);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingXl,
          ),
          child: Text(
            s.featuredForYou,
            style: AppTypography.headingSmall.copyWith(
              color: isDark
                  ? AppColors.textLight
                  : AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXl,
                ),
                child: switch (slide) {
                  _TherapistSlide(:final therapist) => _TherapistAdCard(
                      therapist: therapist,
                      langCode: langCode,
                      ctaLabel: s.promoBookCta,
                      tagLabel: s.promoTherapistTag,
                      onTap: () => _openTherapist(therapist),
                    ),
                  _PremiumSlide() => _PremiumAdCard(
                      title: s.promoPremiumTitle,
                      subtitle: s.promoPremiumSubtitle,
                      ctaLabel: s.upgradeToPremium,
                      onTap: _openPremium,
                    ),
                },
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _DotsIndicator(count: slides.length, current: _currentPage),
      ],
    );
  }
}

class _TherapistAdCard extends StatelessWidget {
  final Therapist therapist;
  final String langCode;
  final String ctaLabel;
  final String tagLabel;
  final VoidCallback onTap;

  const _TherapistAdCard({
    required this.therapist,
    required this.langCode,
    required this.ctaLabel,
    required this.tagLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = therapist.imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 96,
                height: 136,
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(),
                      )
                    : _avatarFallback(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tagLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    therapist.localizedName(langCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textLight
                          : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    therapist.localizedTitle(langCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        therapist.rating.toStringAsFixed(1),
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            ctaLabel,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: AppColors.primary.withValues(alpha: 0.12),
        child: const Icon(
          Icons.person_rounded,
          size: 40,
          color: AppColors.primary,
        ),
      );
}

class _PremiumAdCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  const _PremiumAdCard({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: AppTheme.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ctaLabel,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
