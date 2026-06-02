import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// A visually rich CTA card that encourages users to reach a counselor.
///
/// Replaces the old plain outlined "تواصل مع دعم سند ثيرابي" button with a
/// gradient-backed card that draws the eye without feeling pushy.
///
/// Animations: 400ms opacity fade-in on first mount, respects
/// [MediaQueryData.disableAnimations].
class SupportCtaCard extends ConsumerStatefulWidget {
  final VoidCallback onTap;

  const SupportCtaCard({super.key, required this.onTap});

  @override
  ConsumerState<SupportCtaCard> createState() => _SupportCtaCardState();
}

class _SupportCtaCardState extends ConsumerState<SupportCtaCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // Amendment #3: 400ms opacity fade-in replaces the 0.97→1.0 scale.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    // One-shot entrance; honor reduced-motion preference.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0; // Skip animation — show at full opacity.
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use actual text direction for RTL-aware icon mirroring.
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Amendment #7: tightened gradient + border alphas per panel verdict.
    // Light: primary 10% → 3%, border 18%.
    // Dark:  primary 16% → 5% (using primary, not white), border 22%.
    final gradientColors = isDark
        ? [
            AppColors.primary.withValues(alpha: 0.16),
            AppColors.primary.withValues(alpha: 0.05),
          ]
        : [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.primary.withValues(alpha: 0.03),
          ];

    final borderColor = AppColors.primary.withValues(
      alpha: isDark ? 0.22 : 0.18,
    );

    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              // Amendment #9: ensure full card is at least 56px high
              // (InkWell + Ink fill the whole card; min height enforced here).
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Main row: icon | text body | CTA pill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon container
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.headset_mic_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Text body
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Amendment #6: standard foreground tokens,
                                // NOT primary-tinted.
                                Text(
                                  s.supportCtaHeadline,
                                  style: AppTypography.bodyLarge.copyWith(
                                    // textPrimary in light / white in dark —
                                    // high-contrast neutral foreground on gradient.
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // Amendment #8: subtitle bumped 13→14px,
                                // black54→black87 / white70 for WCAG AA.
                                Text(
                                  s.supportCtaSubtitle,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // CTA pill button — visual affordance; whole card tappable.
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s.supportCtaButton,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  // Amendment #10 (chevron): RTL-aware.
                                  // Flutter does NOT auto-mirror arrow icons —
                                  // explicit direction check required.
                                  isRtl
                                      ? Icons.arrow_back_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Amendment #5: single consolidated trust line replaces
                      // the two separate _MicroBadge pills.
                      Text(
                        s.supportCtaTrustLine,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
