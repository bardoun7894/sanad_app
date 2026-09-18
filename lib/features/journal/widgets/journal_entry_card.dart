import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sanad_card.dart';
import '../../mood/models/mood_enums.dart';
import '../models/journal_entry.dart';

/// List row for a single journal entry.
class JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final String localeCode;

  const JournalEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.localeCode = 'ar',
  });

  /// Strip common markdown markers for a clean preview snippet.
  String get _preview {
    var t = entry.body
        .replaceAll(RegExp(r'[*_#>`~-]'), '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat.MMMd(localeCode).format(entry.createdAt);

    return SanadCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (entry.mood != null)
                Text(
                  MoodTypeExtension.emoji(entry.mood!),
                  style: const TextStyle(fontSize: 22),
                ),
              if (entry.mood != null) const SizedBox(width: 8),
              if (entry.mood != null)
                Text(
                  MoodTypeExtension.label(entry.mood!),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              const Spacer(),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            _preview.isEmpty ? '—' : _preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$t',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
