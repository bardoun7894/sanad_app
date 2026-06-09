import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/psychological_test.dart';
import 'test_taking_screen.dart';

/// Pre-test landing screen: shows the test's title + topic/description and a
/// short disclaimer before the user commits to taking it. Replaces the old
/// behaviour where tapping a card jumped straight into the questions.
class TestIntroScreen extends ConsumerWidget {
  final PsychologicalTest test;

  const TestIntroScreen({super.key, required this.test});

  // Per-type accent + gradient, mirroring the tests list so the intro stays
  // visually consistent with the card the user tapped.
  Color _accentColor(String type) {
    switch (type) {
      case 'depression':
        return const Color(0xFF2563EB);
      case 'anxiety':
        return const Color(0xFFEA580C);
      case 'stress':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.primary;
    }
  }

  LinearGradient _glassGradient(Color accent, bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              accent.withValues(alpha: 0.22),
              accent.withValues(alpha: 0.06),
            ]
          : [
              accent.withValues(alpha: 0.14),
              accent.withValues(alpha: 0.04),
            ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(languageProvider).language;
    final isArabic = lang == AppLanguage.arabic;

    final accent = _accentColor(test.type);
    final title = isArabic ? test.title : test.titleEn;
    final description = isArabic ? test.description : test.descriptionEn;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final bodyColor = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Glassmorphic hero card
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: _glassGradient(accent, isDark),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? 0.35 : 0.22),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                          blurRadius: 30,
                          spreadRadius: -8,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.assignment_outlined,
                            color: accent,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          style: AppTypography.headingLarge.copyWith(
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _MetaBadge(
                              icon: Icons.timer_outlined,
                              label:
                                  '${test.durationMinutes} ${s.minutes}',
                              accent: accent,
                            ),
                            const SizedBox(width: 12),
                            _MetaBadge(
                              icon: Icons.format_list_numbered,
                              label:
                                  '${test.questionsCount} ${isArabic ? "سؤال" : "Q"}',
                              accent: accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Topic / description
              Text(
                isArabic ? 'عن الاختبار' : 'About this test',
                style: AppTypography.headingSmall.copyWith(color: titleColor),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTypography.bodyMedium.copyWith(
                  color: bodyColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.statusWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.statusWarning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.statusWarning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.testDisclaimer,
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Start CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TestTakingScreen(test: test),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(s.startTest),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: AppTypography.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _MetaBadge({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
