import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanad_app/features/mood/models/mood_entry.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import 'package:sanad_app/features/mood/providers/mood_tracker_provider.dart';

class MoodInsightsRow extends ConsumerWidget {
  const MoodInsightsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moodTrackerProvider);
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dominantMood = state.dominantMood;
    final streak = state.currentStreak;
    final totalLogs = state.entries.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Dominant Mood Card
          if (dominantMood != null)
            _InsightCard(
              icon: MoodMetadata.getEmoji(dominantMood),
              label: s
                  .todaysMood, // Reusing existing string for now, could be "Dominant"
              value: MoodMetadata.getLabel(dominantMood, strings: s),
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.softBlue,
              textColor: AppColors.primary,
            ),

          if (dominantMood != null) const SizedBox(width: 12),

          // Streak Card
          _InsightCard(
            icon: '🔥',
            label: s.streak, // Need to add to strings or use generic
            value: '$streak ${s.days}', // Need to ensure s.days exists
            color: isDark
                ? Colors.orange.withValues(alpha: 0.2)
                : Colors.orange.shade50,
            textColor: Colors.orange,
            isEmoji: true,
          ),

          const SizedBox(width: 12),

          // Total Logs Card
          _InsightCard(
            icon: '📝',
            label: s.history, // Reusing history string
            value: '$totalLogs',
            color: isDark
                ? Colors.purple.withValues(alpha: 0.2)
                : Colors.purple.shade50,
            textColor: Colors.purple,
            isEmoji: true,
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final bool isEmoji;

  const _InsightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    this.isEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isEmoji
                  ? Text(icon, style: const TextStyle(fontSize: 20))
                  : Icon(
                      Icons.mood_rounded,
                      color: textColor,
                    ), // Fallback if needed
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
