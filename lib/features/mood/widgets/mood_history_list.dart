import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../models/mood_entry.dart';
import 'mood_selector.dart';

class MoodHistoryList extends StatelessWidget {
  final List<MoodEntry> entries;
  final Function(MoodEntry)? onEntryTap;

  const MoodHistoryList({
    super.key,
    required this.entries,
    this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _MoodHistoryItem(
          entry: entries[index],
          onTap: onEntryTap != null ? () => onEntryTap!(entries[index]) : null,
        );
      },
    );
  }
}

class _MoodHistoryItem extends StatelessWidget {
  final MoodEntry entry;
  final VoidCallback? onTap;

  const _MoodHistoryItem({
    required this.entry,
    this.onTap,
  });

  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return AppColors.moodHappy;
      case MoodType.calm:
        return AppColors.moodCalm;
      case MoodType.anxious:
        return AppColors.moodAnxious;
      case MoodType.sad:
        return AppColors.moodSad;
      case MoodType.tired:
        return AppColors.moodTired;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moodColor = _getMoodColor(entry.mood);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          children: [
            // Mood emoji circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? moodColor.withValues(alpha: 0.3) : moodColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  MoodMetadata.getEmoji(entry.mood),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Date and note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDate(entry.date),
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark ? Colors.white : AppColors.textLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('h:mm a').format(entry.date),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.note ?? MoodMetadata.getLabel(entry.mood),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow icon
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.softBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mood_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No mood entries yet',
            style: AppTypography.headingSmall.copyWith(
              color: isDark ? Colors.white : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your mood to see your history here',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
