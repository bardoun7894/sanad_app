import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/psychological_test.dart';
import '../providers/content_provider.dart';
import 'test_intro_screen.dart';
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
    final accentColor = _getTestAccentColor(test.type);
    final isArabic = lang == AppLanguage.arabic;
    final title = isArabic ? test.title : test.titleEn;
    final description = isArabic ? test.description : test.descriptionEn;

    // Translucent per-type gradient so the frosted-glass blur shows through.
    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              accentColor.withValues(alpha: 0.22),
              accentColor.withValues(alpha: 0.06),
            ]
          : [
              accentColor.withValues(alpha: 0.13),
              accentColor.withValues(alpha: 0.03),
            ],
    );

    // Text color: dark on light-mode pastels; white on dark-mode surfaces.
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : AppColors.textSecondary;
    final badgeColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : AppColors.textSecondary;

    void openIntro() => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TestIntroScreen(test: test),
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: openIntro,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                gradient: glassGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.20 : 0.10),
                    blurRadius: 24,
                    spreadRadius: -6,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: accentColor.withValues(alpha: isDark ? 0.30 : 0.20),
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
                  onPressed: openIntro,
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
            ),
          ),
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
