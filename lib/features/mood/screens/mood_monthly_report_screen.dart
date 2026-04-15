import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/mood_entry.dart';
import '../models/mood_enums.dart';
import '../providers/mood_tracker_provider.dart';

/// Dedicated monthly mood report screen.
/// Shows calendar, mood distribution, completion rate, and insights for a selected month.
class MoodMonthlyReportScreen extends ConsumerStatefulWidget {
  const MoodMonthlyReportScreen({super.key});

  @override
  ConsumerState<MoodMonthlyReportScreen> createState() =>
      _MoodMonthlyReportScreenState();
}

class _MoodMonthlyReportScreenState
    extends ConsumerState<MoodMonthlyReportScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() => _selectedMonth = nextMonth);
    }
  }

  List<MoodEntry> _getEntriesForMonth(List<MoodEntry> allEntries) {
    final monthStart = _selectedMonth;
    final monthEnd = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    return allEntries
        .where((e) =>
            e.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
            e.date.isBefore(monthEnd))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  int _daysInMonth() {
    return DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
  }

  Map<MoodType, int> _getMoodDistribution(List<MoodEntry> entries) {
    final dist = <MoodType, int>{};
    for (final entry in entries) {
      dist[entry.mood] = (dist[entry.mood] ?? 0) + 1;
    }
    return dist;
  }

  MoodType? _getDominantMood(Map<MoodType, int> distribution) {
    if (distribution.isEmpty) return null;
    return distribution.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moodTrackerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(languageProvider).language;
    final isArabic = lang == AppLanguage.arabic;

    final monthEntries = _getEntriesForMonth(state.entries);
    final totalDays = _daysInMonth();
    final loggedDays = monthEntries.length;
    final completionRate =
        totalDays > 0 ? (loggedDays / totalDays * 100).round() : 0;
    final distribution = _getMoodDistribution(monthEntries);
    final dominantMood = _getDominantMood(distribution);
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          s.monthlyReport,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month picker
            _buildMonthPicker(isDark, isCurrentMonth, isArabic),
            const SizedBox(height: 24),

            // Completion rate card
            _buildCompletionCard(
              isDark,
              loggedDays,
              totalDays,
              completionRate,
              s,
            ),
            const SizedBox(height: 20),

            // Dominant mood
            if (dominantMood != null)
              _buildDominantMoodCard(isDark, dominantMood, s),
            if (dominantMood != null) const SizedBox(height: 20),

            // Mood distribution
            if (distribution.isNotEmpty) ...[
              Text(
                s.moodDistribution,
                style: AppTypography.headingSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...distribution.entries.map(
                (e) => _buildMoodBar(
                  isDark,
                  e.key,
                  e.value,
                  loggedDays,
                  s,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Calendar grid for the month
            _buildCalendarGrid(isDark, monthEntries, s),
            const SizedBox(height: 24),

            // Summary text
            if (monthEntries.isNotEmpty)
              _buildSummaryText(
                isDark,
                loggedDays,
                totalDays,
                dominantMood,
                s,
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthPicker(bool isDark, bool isCurrentMonth, bool isArabic) {
    final months = isArabic
        ? [
            'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
            'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
          ]
        : [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December',
          ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
            style: AppTypography.headingSmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: isCurrentMonth ? null : _nextMonth,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: isCurrentMonth
                  ? AppColors.textMuted.withValues(alpha: 0.3)
                  : (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard(
    bool isDark,
    int loggedDays,
    int totalDays,
    int completionRate,
    dynamic s,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: completionRate / 100,
                  strokeWidth: 6,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
                Text(
                  '$completionRate%',
                  style: AppTypography.headingSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.completionRate,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$loggedDays / $totalDays ${s.daysLogged}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDominantMoodCard(bool isDark, MoodType mood, dynamic s) {
    final moodEmoji = MoodTypeExtension.emoji(mood);
    final moodLabel = MoodTypeExtension.label(mood);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(moodEmoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.dominantMood,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                moodLabel,
                style: AppTypography.headingSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBar(
    bool isDark,
    MoodType mood,
    int count,
    int total,
    dynamic s,
  ) {
    final percentage = total > 0 ? count / total : 0.0;
    final moodEmoji = MoodTypeExtension.emoji(mood);
    final moodLabel = MoodTypeExtension.label(mood);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(moodEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              moodLabel,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                valueColor: AlwaysStoppedAnimation(
                  _getMoodColor(mood),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return const Color(0xFFFFC107);
      case MoodType.calm:
        return const Color(0xFF4CAF50);
      case MoodType.anxious:
        return const Color(0xFFFF9800);
      case MoodType.sad:
        return const Color(0xFF2196F3);
      case MoodType.angry:
        return const Color(0xFFF44336);
      case MoodType.tired:
        return const Color(0xFF9E9E9E);
    }
  }

  Widget _buildCalendarGrid(
    bool isDark,
    List<MoodEntry> entries,
    dynamic s,
  ) {
    final daysInMonth = _daysInMonth();
    final firstDayWeekday =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;

    // Map entries by day
    final entriesByDay = <int, MoodEntry>{};
    for (final entry in entries) {
      entriesByDay[entry.date.day] = entry;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.moodCalendar,
            style: AppTypography.labelLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: daysInMonth + (firstDayWeekday - 1),
            itemBuilder: (context, index) {
              if (index < firstDayWeekday - 1) {
                return const SizedBox.shrink();
              }
              final day = index - (firstDayWeekday - 1) + 1;
              if (day > daysInMonth) return const SizedBox.shrink();

              final entry = entriesByDay[day];
              final isToday = _selectedMonth.year == DateTime.now().year &&
                  _selectedMonth.month == DateTime.now().month &&
                  day == DateTime.now().day;

              return Container(
                decoration: BoxDecoration(
                  color: entry != null
                      ? _getMoodColor(entry.mood).withValues(alpha: 0.2)
                      : (isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight),
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: entry != null
                      ? Text(
                          MoodTypeExtension.emoji(entry.mood),
                          style: const TextStyle(fontSize: 16),
                        )
                      : Text(
                          '$day',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryText(
    bool isDark,
    int loggedDays,
    int totalDays,
    MoodType? dominantMood,
    dynamic s,
  ) {
    final moodLabel =
        dominantMood != null ? MoodTypeExtension.label(dominantMood) : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.softBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dominantMood != null
                  ? '${s.youLoggedMood} $loggedDays ${s.outOf} $totalDays ${s.daysLogged}. ${s.dominantMood}: $moodLabel'
                  : '${s.youLoggedMood} $loggedDays ${s.outOf} $totalDays ${s.daysLogged}.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
