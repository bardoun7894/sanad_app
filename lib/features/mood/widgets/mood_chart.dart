import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../models/mood_entry.dart';
import 'mood_selector.dart';

class MoodChart extends StatelessWidget {
  final List<MoodEntry> entries;

  const MoodChart({
    super.key,
    required this.entries,
  });

  List<FlSpot> _generateSpots() {
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);

      final entry = entries.where((e) {
        final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
        return entryDate == dateOnly;
      }).firstOrNull;

      if (entry != null) {
        spots.add(FlSpot(
          (6 - i).toDouble(),
          MoodMetadata.getMoodScore(entry.mood).toDouble(),
        ));
      }
    }

    return spots;
  }

  String _getDayLabel(int index) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: 6 - index));
    return DateFormat('E').format(date).substring(0, 1);
  }

  String _getMoodLabel(int value) {
    switch (value) {
      case 5:
        return '😊';
      case 4:
        return '😌';
      case 3:
        return '😴';
      case 2:
        return '😨';
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
              Text(
                'Weekly Overview',
                style: AppTypography.headingSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? _buildEmptyChart(isDark)
                : _buildChart(isDark, spots),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(bool isDark) {
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
            'Log your moods to see trends',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark, List<FlSpot> spots) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
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
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              show: true,
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
            getTooltipColor: (_) => isDark ? AppColors.surfaceDark : Colors.white,
            tooltipRoundedRadius: 12,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final mood = _getMoodLabel(spot.y.toInt());
                return LineTooltipItem(
                  mood,
                  const TextStyle(fontSize: 20),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

// Calendar grid view alternative
class MoodCalendarGrid extends StatelessWidget {
  final List<MoodEntry> entries;

  const MoodCalendarGrid({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                child: const Icon(
                  Icons.calendar_view_week_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'This Week',
                style: AppTypography.headingSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = now.subtract(Duration(days: 6 - index));
              final dateOnly = DateTime(date.year, date.month, date.day);
              final entry = entries.where((e) {
                final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
                return entryDate == dateOnly;
              }).firstOrNull;

              return _CalendarDay(
                date: date,
                entry: entry,
                isToday: index == 6,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime date;
  final MoodEntry? entry;
  final bool isToday;

  const _CalendarDay({
    required this.date,
    this.entry,
    this.isToday = false,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayName = DateFormat('E').format(date).substring(0, 1);

    return Column(
      children: [
        Text(
          dayName,
          style: AppTypography.labelSmall.copyWith(
            color: isToday ? AppColors.primary : AppColors.textMuted,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
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
                    style: const TextStyle(fontSize: 20),
                  )
                : Text(
                    date.day.toString(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
