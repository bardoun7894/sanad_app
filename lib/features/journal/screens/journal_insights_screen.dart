import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sanad_card.dart';
import '../../mood/models/mood_enums.dart';
import '../l10n/journal_strings.dart';
import '../providers/journal_provider.dart';

/// On-device (no network) analytics over the current month's entries.
class JournalInsightsScreen extends ConsumerWidget {
  const JournalInsightsScreen({super.key});

  static const _stopwords = {
    // Arabic
    'في', 'من', 'على', 'الى', 'إلى', 'عن', 'مع', 'هذا', 'هذه', 'ذلك', 'التي',
    'الذي', 'كان', 'كانت', 'انا', 'أنا', 'هو', 'هي', 'ان', 'أن', 'او', 'أو',
    'لا', 'ما', 'قد', 'كل', 'يوم', 'اليوم', 'كنت', 'وقد', 'ثم', 'بعد', 'قبل',
    // English
    'the', 'and', 'was', 'for', 'that', 'this', 'with', 'you', 'have', 'not',
    'but', 'are', 'his', 'her', 'they', 'from', 'were', 'today', 'about',
    'what', 'when', 'just', 'like', 'been', 'will', 'them', 'then',
  };

  Color _moodColor(MoodType m) {
    switch (m) {
      case MoodType.happy:
        return AppColors.moodHappyIcon;
      case MoodType.calm:
        return AppColors.moodCalmIcon;
      case MoodType.anxious:
        return AppColors.moodAnxiousIcon;
      case MoodType.sad:
        return AppColors.moodSadIcon;
      case MoodType.angry:
        return AppColors.moodAngryIcon;
      case MoodType.tired:
        return AppColors.statusPending;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider).language;
    final js = JournalStrings(lang);
    final state = ref.watch(journalProvider);
    final bg = isDark ? AppColors.journalBgDark : AppColors.journalBgLight;
    final ink = isDark ? AppColors.journalInkDark : AppColors.journalInkLight;

    final now = DateTime.now();
    final monthEntries = state.entries
        .where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month)
        .toList();

    // Mood distribution
    final moodCounts = <MoodType, int>{};
    for (final e in monthEntries) {
      if (e.mood != null) {
        moodCounts[e.mood!] = (moodCounts[e.mood!] ?? 0) + 1;
      }
    }

    // Word frequency
    final wordCounts = <String, int>{};
    for (final e in monthEntries) {
      final tokens = e.body
          .toLowerCase()
          .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), ' ')
          .split(RegExp(r'\s+'));
      for (final t in tokens) {
        if (t.length < 3 || _stopwords.contains(t)) continue;
        wordCounts[t] = (wordCounts[t] ?? 0) + 1;
      }
    }
    final topWords = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top6 = topWords.take(6).toList();

    MoodType? dominant;
    var maxC = 0;
    moodCounts.forEach((k, v) {
      if (v > maxC) {
        maxC = v;
        dominant = k;
      }
    });

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(js.insights),
      ),
      body: monthEntries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing3xl),
                child: Text(
                  js.noData,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              children: [
                SanadCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        js.monthSummary,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      if (moodCounts.isEmpty)
                        Text(
                          '—',
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      else
                        SizedBox(
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 52,
                                  sections: moodCounts.entries.map((e) {
                                    return PieChartSectionData(
                                      value: e.value.toDouble(),
                                      color: _moodColor(e.key),
                                      title: MoodTypeExtension.emoji(e.key),
                                      radius: 34,
                                      titleStyle:
                                          const TextStyle(fontSize: 16),
                                    );
                                  }).toList(),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${monthEntries.length}',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: ink,
                                    ),
                                  ),
                                  Text(
                                    js.entriesCount,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: moodCounts.entries
                            .map((e) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _moodColor(e.key),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${MoodTypeExtension.label(e.key)} ${e.value}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                if (top6.isNotEmpty)
                  SanadCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          js.topWords,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: top6
                              .map((w) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${w.key} (${w.value})',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                if (dominant != null) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  SanadCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          js.smartNotes,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        Text(
                          _smartNote(js, dominant!, top6),
                          style: TextStyle(
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingLg),
                Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        js.privateNote,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  String _smartNote(
    JournalStrings js,
    MoodType dominant,
    List<MapEntry<String, int>> top,
  ) {
    final mood = MoodTypeExtension.label(dominant);
    if (top.isEmpty) return mood;
    return '$mood • ${top.first.key}';
  }
}
