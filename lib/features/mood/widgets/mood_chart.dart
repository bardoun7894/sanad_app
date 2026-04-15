import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/mood_enums.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../models/mood_entry.dart';

import '../../../core/l10n/language_provider.dart';

class MoodChart extends StatefulWidget {
  final List<MoodEntry> entries;
  final S strings;

  const MoodChart({super.key, required this.entries, required this.strings});

  @override
  State<MoodChart> createState() => _MoodChartState();
}

class _MoodChartState extends State<MoodChart> {
  bool _isMonthly = false;

  List<FlSpot> _generateSpots() {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final daysCount = _isMonthly ? 30 : 7;

    for (int i = daysCount - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);

      final entry = widget.entries.where((e) {
        final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
        return entryDate == dateOnly;
      }).firstOrNull;

      if (entry != null) {
        spots.add(
          FlSpot(
            (daysCount - 1 - i).toDouble(),
            MoodMetadata.getMoodScore(entry.mood).toDouble(),
          ),
        );
      }
    }

    return spots;
  }

  String _getDayLabel(int index) {
    final now = DateTime.now();
    final daysCount = _isMonthly ? 30 : 7;
    final date = now.subtract(Duration(days: daysCount - 1 - index));

    if (_isMonthly) {
      // For monthly, show day number for every 5 days or so
      if (index % 5 == 0) {
        return date.day.toString();
      }
      return '';
    }

    final label = DateFormat('E').format(date);
    return label.isNotEmpty ? label.substring(0, 1) : '';
  }

  String _getMoodLabel(int value) {
    switch (value) {
      case 5:
        return '😊';
      case 4:
        return '😌';
      case 2:
        return '😴';
      case 1:
        return '😢';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spots = _generateSpots();
    final s = widget.strings;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.softBlue,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isMonthly ? s.thisMonth : s.weeklyOverview,
                  style: AppTypography.headingSmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              // View Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _ToggleButton(
                      label: s.week,
                      isSelected: !_isMonthly,
                      onTap: () => setState(() => _isMonthly = false),
                    ),
                    _ToggleButton(
                      label: s.month,
                      isSelected: _isMonthly,
                      onTap: () => setState(() => _isMonthly = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? _buildEmptyChart(isDark, s)
                : _buildChart(isDark, spots),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(bool isDark, S strings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_rounded,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            strings.startTracking,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark, List<FlSpot> spots) {
    final daysCount = _isMonthly ? 30 : 7;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (daysCount - 1).toDouble(),
        minY: 0,
        maxY: 6,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.5)
                  : AppColors.borderLight,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getDayLabel(value.toInt()),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == 6) return const SizedBox.shrink();
                return Text(
                  _getMoodLabel(value.toInt()),
                  style: const TextStyle(fontSize: 14),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: !_isMonthly, // Hide dots in monthly view to avoid clutter
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: AppColors.primary,
                  strokeWidth: 3,
                  strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : Colors.white,
            tooltipRoundedRadius: 12,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final mood = _getMoodLabel(spot.y.toInt());
                return LineTooltipItem(mood, const TextStyle(fontSize: 20));
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// Calendar grid view alternative
class MoodCalendarGrid extends StatefulWidget {
  final List<MoodEntry> entries;
  final S strings;

  const MoodCalendarGrid({
    super.key,
    required this.entries,
    required this.strings,
  });

  @override
  State<MoodCalendarGrid> createState() => _MoodCalendarGridState();
}

class _MoodCalendarGridState extends State<MoodCalendarGrid> {
  bool _isMonthly = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.strings;
    final now = DateTime.now();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.softBlue,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  _isMonthly
                      ? Icons.calendar_month_rounded
                      : Icons.calendar_view_week_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isMonthly ? s.thisMonth : s.thisWeek,
                  style: AppTypography.headingSmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              // View Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _ToggleButton(
                      label: s.week,
                      isSelected: !_isMonthly,
                      onTap: () => setState(() => _isMonthly = false),
                    ),
                    _ToggleButton(
                      label: s.month,
                      isSelected: _isMonthly,
                      onTap: () => setState(() => _isMonthly = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_isMonthly)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final date = now.subtract(Duration(days: 6 - index));
                final dateOnly = DateTime(date.year, date.month, date.day);
                final entry = widget.entries.where((e) {
                  final entryDate = DateTime(
                    e.date.year,
                    e.date.month,
                    e.date.day,
                  );
                  return entryDate == dateOnly;
                }).firstOrNull;

                return _CalendarDay(
                  date: date,
                  entry: entry,
                  isToday: index == 6,
                );
              }),
            )
          else
            _buildMonthlyGrid(now, isDark, widget.entries),
        ],
      ),
    );
  }

  Widget _buildMonthlyGrid(DateTime now, bool isDark, List<MoodEntry> entries) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final weekdayOfFirst = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Adjust for Monday start (or whichever you prefer)
    // We'll use 0-indexed for 7 columns
    final leadingSpaces = (weekdayOfFirst - 1) % 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: daysInMonth + leadingSpaces,
      itemBuilder: (context, index) {
        if (index < leadingSpaces) return const SizedBox.shrink();

        final dayNumber = index - leadingSpaces + 1;
        final date = DateTime(now.year, now.month, dayNumber);
        final dateOnly = DateTime(date.year, date.month, date.day);

        final entry = entries.where((e) {
          final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
          return entryDate == dateOnly;
        }).firstOrNull;

        final isToday = dayNumber == now.day;

        return _CalendarDay(
          date: date,
          entry: entry,
          isToday: isToday,
          showLabel: false,
        );
      },
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime date;
  final MoodEntry? entry;
  final bool isToday;
  final bool showLabel;

  const _CalendarDay({
    required this.date,
    this.entry,
    this.isToday = false,
    this.showLabel = true,
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
      case MoodType.angry:
        return AppColors.moodAngry;
      case MoodType.tired:
        return AppColors.moodTired;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = DateFormat('E').format(date);
    final dayName = label.isNotEmpty ? label.substring(0, 1) : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            dayName,
            style: AppTypography.labelSmall.copyWith(
              color: isToday ? AppColors.primary : AppColors.textMuted,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: entry != null
                ? (isDark
                      ? _getMoodColor(entry!.mood).withValues(alpha: 0.3)
                      : _getMoodColor(entry!.mood))
                : (isDark
                      ? AppColors.borderDark.withValues(alpha: 0.3)
                      : AppColors.backgroundLight),
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Center(
            child: entry != null
                ? Text(
                    MoodMetadata.getEmoji(entry!.mood),
                    style: const TextStyle(fontSize: 18),
                  )
                : Text(
                    date.day.toString(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
