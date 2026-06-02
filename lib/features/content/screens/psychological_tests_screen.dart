import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/psychological_test.dart';
import '../providers/content_provider.dart';
import 'test_taking_screen.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../subscription/providers/feature_gating_provider.dart';
import '../../subscription/widgets/paywall_overlay.dart';

class PsychologicalTestsScreen extends ConsumerWidget {
  const PsychologicalTestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(languageProvider).language;
    final testsAsync = ref.watch(psychTestsProvider);
    final hasAccess = ref.watch(isFeatureAccessibleProvider('psychological_tests'));

    // Show paywall for users without access (free and weekly tiers)
    if (!hasAccess) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            s.psychologicalTests,
            style: AppTypography.displayMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.subscriptionRequired,
                  style: AppTypography.headingSmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  s.psychTestsRequireSubscription,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => showPaywallOverlay(
                    context,
                    featureName: s.psychologicalTests,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  child: Text(s.upgradeToPremium),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.psychologicalTests,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: testsAsync.when(
        loading: () => LoadingStateWidget(message: s.loadingContent),
        error: (e, _) => ErrorStateWidget(
          message: s.errorLoadingData,
          retryLabel: s.retry,
          onRetry: () => ref.invalidate(psychTestsProvider),
        ),
        data: (tests) {
          if (tests.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.assignment_outlined,
              message: s.noContentYet,
              description: s.contentComingSoon,
              iconColor: Colors.purple,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(psychTestsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildTestCard(
                context,
                ref,
                tests[index],
                isDark,
                lang,
                s,
              ),
            ),
          );
        },
      ),
    );
  }



  // Returns a per-type LinearGradient for the card background.
  // Light mode: a soft diagonal gradient from a light tint of the type color to
  // a slightly deeper shade, keeping text readable over white/near-white.
  // Dark mode: a subtle dark gradient with a hint of the type color so the card
  // still reads as colored without blowing contrast.
  LinearGradient _getTestGradient(String type, bool isDark) {
    switch (type) {
      case 'depression':
        // Blue family
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF1A2744), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFEBF4FF), Color(0xFFD1E8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
      case 'anxiety':
        // Orange / amber family
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF2A1A0A), Color(0xFF3D2410)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
      case 'stress':
        // Purple family
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E1535), Color(0xFF2A1D4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
      default:
        // Teal / AppColors.primary family
        return isDark
            ? const LinearGradient(
                colors: [Color(0xFF0A1F24), Color(0xFF0D2D35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFE6F6F8), Color(0xFFCCEEF2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              );
    }
  }

  // Returns the accent color for icon, border, and CTA button for the given type.
  Color _getTestAccentColor(String type) {
    switch (type) {
      case 'depression':
        return const Color(0xFF2563EB); // blue-600
      case 'anxiety':
        return const Color(0xFFEA580C); // orange-600
      case 'stress':
        return const Color(0xFF7C3AED); // violet-600
      default:
        return AppColors.primary; // teal
    }
  }

  Widget _buildTestCard(
    BuildContext context,
    WidgetRef ref,
    PsychologicalTest test,
    bool isDark,
    AppLanguage lang,
    S s,
  ) {
    final gradient = _getTestGradient(test.type, isDark);
    final accentColor = _getTestAccentColor(test.type);
    final isArabic = lang == AppLanguage.arabic;
    final title = isArabic ? test.title : test.titleEn;
    final description = isArabic ? test.description : test.descriptionEn;

    // Text color: dark on light-mode pastels; white on dark-mode surfaces.
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : AppColors.textSecondary;
    final badgeColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 16,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtitleColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildBadge(
                  Icons.timer_outlined,
                  '${test.durationMinutes} ${isArabic ? "دقائق" : "min"}',
                  badgeColor,
                ),
                const SizedBox(width: 12),
                _buildBadge(
                  Icons.format_list_numbered,
                  '${test.questionsCount} ${isArabic ? "أسئلة" : "Q"}',
                  badgeColor,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TestTakingScreen(test: test),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 0,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(s.startTest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
