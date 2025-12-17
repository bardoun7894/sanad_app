import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sanad_button.dart';
import '../../core/l10n/language_provider.dart';
import 'models/mood_entry.dart';
import 'providers/mood_tracker_provider.dart';
import 'widgets/mood_chart.dart';
import 'widgets/mood_history_list.dart';
import 'widgets/log_mood_sheet.dart';
import 'widgets/mood_selector.dart';

class MoodTrackerScreen extends ConsumerWidget {
  const MoodTrackerScreen({super.key});

  void _showLogMoodSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogMoodSheet(
        onSave: (mood, note) {
          ref.read(moodTrackerProvider.notifier).logMood(mood, note: note);
        },
      ),
    );
  }

  void _showEntryDetails(BuildContext context, WidgetRef ref, MoodEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.read(stringsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _getMoodColor(entry.mood, isDark),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    MoodMetadata.getEmoji(entry.mood),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                MoodMetadata.getLabel(entry.mood, strings: s),
                style: AppTypography.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatFullDate(entry.date, s),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              if (entry.note != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    entry.note!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  s.close,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(MoodType mood, bool isDark) {
    final baseColor = switch (mood) {
      MoodType.happy => AppColors.moodHappy,
      MoodType.calm => AppColors.moodCalm,
      MoodType.anxious => AppColors.moodAnxious,
      MoodType.sad => AppColors.moodSad,
      MoodType.tired => AppColors.moodTired,
    };
    return isDark ? baseColor.withValues(alpha: 0.3) : baseColor;
  }

  String _formatFullDate(DateTime date, S s) {
    final months = [
      s.january,
      s.february,
      s.march,
      s.april,
      s.may,
      s.june,
      s.july,
      s.august,
      s.september,
      s.october,
      s.november,
      s.december,
    ];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'م' : 'ص';
    return '${date.day} ${months[date.month - 1]} ${date.year} - $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moodTrackerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _Header(
              onBack: () => Navigator.of(context).pop(),
              todayLogged: state.todayEntry != null,
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's mood card
                    _TodayMoodCard(
                      entry: state.todayEntry,
                      onLogMood: () => _showLogMoodSheet(context, ref),
                    ),
                    const SizedBox(height: 20),

                    // Calendar grid
                    MoodCalendarGrid(entries: state.entries),
                    const SizedBox(height: 20),

                    // Mood chart
                    MoodChart(entries: state.entries, strings: s),
                    const SizedBox(height: 24),

                    // History section
                    Text(
                      s.recentHistory,
                      style: AppTypography.headingMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    MoodHistoryList(
                      entries: state.weeklyEntries,
                      onEntryTap: (entry) =>
                          _showEntryDetails(context, ref, entry),
                      strings: s,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogMoodSheet(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(s.logMood, style: AppTypography.buttonMedium),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final VoidCallback onBack;
  final bool todayLogged;

  const _Header({required this.onBack, required this.todayLogged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          Expanded(
            child: Text(
              s.moodTracker,
              style: AppTypography.headingMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textLight,
              ),
            ),
          ),
          if (todayLogged)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radius2xl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.today,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TodayMoodCard extends ConsumerWidget {
  final MoodEntry? entry;
  final VoidCallback onLogMood;

  const _TodayMoodCard({required this.entry, required this.onLogMood});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    if (entry == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              s.howAreYouFeelingToday,
              style: AppTypography.headingMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              s.takeAMoment,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            SanadButton(
              text: s.logMyMood,
              icon: Icons.mood_rounded,
              onPressed: onLogMood,
              variant: SanadButtonVariant.secondary,
              backgroundColor: Colors.white,
              textColor: AppColors.primary,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getMoodColor(entry!.mood, isDark),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                MoodMetadata.getEmoji(entry!.mood),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.todaysMood,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  MoodMetadata.getLabel(entry!.mood, strings: s),
                  style: AppTypography.headingSmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textLight,
                  ),
                ),
                if (entry!.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry!.note!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onLogMood,
            icon: Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(MoodType mood, bool isDark) {
    final baseColor = switch (mood) {
      MoodType.happy => AppColors.moodHappy,
      MoodType.calm => AppColors.moodCalm,
      MoodType.anxious => AppColors.moodAnxious,
      MoodType.sad => AppColors.moodSad,
      MoodType.tired => AppColors.moodTired,
    };
    return isDark ? baseColor.withValues(alpha: 0.3) : baseColor;
  }
}
