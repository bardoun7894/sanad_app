import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../chat/models/chat_handoff.dart';

/// 7-day mood trend line chart for the therapist view.
///
/// Uses [fl_chart] to render mood scores (1-5) over the past 7 days.
/// Color-coded: green for scores >= 3, red for scores < 3.
/// Displays the average score and trend direction text below the chart.
class MoodContextChart extends StatelessWidget {
  final MoodSnapshot moodSnapshot;

  const MoodContextChart({super.key, required this.moodSnapshot});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 18,
                color: isDark ? AppColors.textMuted : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '7-Day Mood Trend',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _TrendBadge(trend: moodSnapshot.trend, isDark: isDark),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          SizedBox(height: 140, child: _buildChart(isDark)),
          const SizedBox(height: 12),

          // Summary row
          Row(
            children: [
              _StatChip(
                label: 'Average',
                value: moodSnapshot.averageScore.toStringAsFixed(1),
                color: moodSnapshot.averageScore >= 3
                    ? AppColors.success
                    : AppColors.error,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              if (moodSnapshot.consecutiveLowDays > 0)
                _StatChip(
                  label: 'Low days',
                  value: '${moodSnapshot.consecutiveLowDays}',
                  color: AppColors.warning,
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark) {
    final scores = _parseMoodScores();

    if (scores.isEmpty) {
      return Center(
        child: Text(
          'No mood data available',
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < scores.length; i++) {
      spots.add(FlSpot(i.toDouble(), scores[i]));
    }

    return LineChart(
      LineChartData(
        minY: 0.5,
        maxY: 5.5,
        minX: 0,
        maxX: (scores.length - 1).toDouble().clamp(1, 6),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 1,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark
                ? AppColors.borderDark.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.5),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value < 1 || value > 5) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= moodSnapshot.dates.length) {
                  return const SizedBox.shrink();
                }
                final date = moodSnapshot.dates[index];
                // Show short day label (last 2 chars of date or day number)
                final label = date.length >= 2
                    ? date.substring(date.length - 2)
                    : date;
                return Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: moodSnapshot.averageScore >= 3
                ? AppColors.success
                : AppColors.error,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                final isGood = spot.y >= 3;
                return FlDotCirclePainter(
                  radius: 3,
                  color: isGood ? AppColors.success : AppColors.error,
                  strokeWidth: 1.5,
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
                  (moodSnapshot.averageScore >= 3
                          ? AppColors.success
                          : AppColors.error)
                      .withValues(alpha: 0.15),
                  (moodSnapshot.averageScore >= 3
                          ? AppColors.success
                          : AppColors.error)
                      .withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Reference line at score 3 (neutral threshold)
          LineChartBarData(
            spots: [
              FlSpot(0, 3),
              FlSpot((scores.length - 1).toDouble().clamp(1, 6), 3),
            ],
            isCurved: false,
            color: AppColors.textMuted.withValues(alpha: 0.3),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: [4, 4],
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                if (spot.barIndex != 0) return null;
                return LineTooltipItem(
                  'Score: ${spot.y.toStringAsFixed(1)}',
                  AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Convert mood strings to numeric scores (1-5 scale).
  List<double> _parseMoodScores() {
    return moodSnapshot.moods.map((mood) {
      switch (mood.toLowerCase()) {
        case 'happy':
        case 'energetic':
          return 5.0;
        case 'calm':
          return 4.0;
        case 'neutral':
        case 'stable':
          return 3.0;
        case 'anxious':
        case 'tired':
          return 2.0;
        case 'sad':
        case 'angry':
          return 1.0;
        default:
          // Try parsing as a number
          return double.tryParse(mood) ?? 3.0;
      }
    }).toList();
  }
}

// ── Trend Badge ────────────────────────────────────────────────────────────

class _TrendBadge extends StatelessWidget {
  final String trend;
  final bool isDark;

  const _TrendBadge({required this.trend, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _colorForTrend();
    final icon = _iconForTrend();
    final label = trend[0].toUpperCase() + trend.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForTrend() {
    switch (trend.toLowerCase()) {
      case 'improving':
        return AppColors.success;
      case 'declining':
        return AppColors.error;
      case 'stable':
      default:
        return AppColors.info;
    }
  }

  IconData _iconForTrend() {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Icons.trending_up_rounded;
      case 'declining':
        return Icons.trending_down_rounded;
      case 'stable':
      default:
        return Icons.trending_flat_rounded;
    }
  }
}

// ── Stat Chip ──────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
