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



  Color _getTestColor(String type) {
    switch (type) {
      case 'depression':
        return Colors.blue;
      case 'anxiety':
        return Colors.orange;
      case 'stress':
        return Colors.purple;
      default:
        return AppColors.primary;
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
    final color = _getTestColor(test.type);
    final isArabic = lang == AppLanguage.arabic;
    final title = isArabic ? test.title : test.titleEn;
    final description = isArabic ? test.description : test.descriptionEn;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assignment_outlined, color: color),
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
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBadge(Icons.timer_outlined,
                  '${test.durationMinutes} ${isArabic ? "دقائق" : "min"}'),
              const SizedBox(width: 12),
              _buildBadge(Icons.format_list_numbered,
                  '${test.questionsCount} ${isArabic ? "أسئلة" : "Q"}'),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestTakingScreen(test: test),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
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
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
