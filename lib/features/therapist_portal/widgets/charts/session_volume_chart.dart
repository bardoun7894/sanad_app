import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/language_provider.dart';
import 'base_chart_card.dart';
import 'chart_utils.dart';

/// Data model for session volume
class SessionVolumeData {
  final DateTime date;
  final int sessionCount;

  const SessionVolumeData({required this.date, required this.sessionCount});
}

/// Line chart showing session volume trends over time
class SessionVolumeChart extends ConsumerStatefulWidget {
  final List<SessionVolumeData> data;
  final ChartPeriod selectedPeriod;
  final ValueChanged<ChartPeriod>? onPeriodChanged;

  const SessionVolumeChart({
    super.key,
    required this.data,
    this.selectedPeriod = ChartPeriod.week,
    this.onPeriodChanged,
  });

  @override
  ConsumerState<SessionVolumeChart> createState() => _SessionVolumeChartState();
}

class _SessionVolumeChartState extends ConsumerState<SessionVolumeChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return BaseChartCard(
      title: s.sessionVolume,
      icon: Icons.trending_up_rounded,
      height: 280,
      selectedPeriod: widget.selectedPeriod,
      availablePeriods: const [
        ChartPeriod.week,
        ChartPeriod.month,
        ChartPeriod.quarter,
      ],
      onPeriodChanged: widget.onPeriodChanged,
      child: widget.data.isEmpty
          ? _buildEmptyState(isDark, s)
          : _buildChart(isDark, s),
    );
  }

  Widget _buildEmptyState(bool isDark, S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            s.noSessionData,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark, S s) {
    final spots = _generateSpots();
    final maxY = _calculateMaxY(spots);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (widget.selectedPeriod.days - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: ChartStyles.defaultGrid(isDark),
        borderData: ChartStyles.defaultBorder(isDark),
        titlesData: _buildTitles(isDark, s),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                ChartStyles.defaultTooltipBackground(isDark),
            tooltipBorder: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final date = widget.data[spot.x.toInt()].date;
                final sessions = spot.y.toInt();
                final label = sessions == 1 ? s.session : s.sessionsCountLabel;

                return LineTooltipItem(
                  '$sessions $label\n',
                  TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          touchCallback: (event, response) {
            setState(() {
              if (response == null || response.lineBarSpots == null) {
                touchedIndex = null;
              } else {
                touchedIndex = response.lineBarSpots!.first.x.toInt();
              }
            });
          },
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: widget.selectedPeriod == ChartPeriod.week,
              getDotPainter: (spot, percent, barData, index) {
                final isTouch = index == touchedIndex;
                return FlDotCirclePainter(
                  radius: isTouch ? 6 : 4,
                  color: isTouch ? AppColors.primary : Colors.white,
                  strokeWidth: isTouch ? 3 : 2,
                  strokeColor: AppColors.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: ChartColors.getChartGradient(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    return widget.data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.sessionCount.toDouble());
    }).toList();
  }

  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 10;

    final maxValue = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    // Add 20% padding to max value for better visualization
    final padding = maxValue * 0.2;
    final result = maxValue + padding;

    // Round up to nearest 5
    return (result / 5).ceil() * 5;
  }

  FlTitlesData _buildTitles(bool isDark, S s) {
    final textColor = isDark ? AppColors.textMuted : AppColors.textSecondary;

    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: _getBottomInterval(),
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= widget.data.length) return const SizedBox();

            final date = widget.data[value.toInt()].date;
            String text;

            if (widget.selectedPeriod == ChartPeriod.week) {
              text = ChartDataProcessor.getDayAbbreviation(date.weekday, s);
            } else if (widget.selectedPeriod == ChartPeriod.month) {
              text = date.day.toString();
            } else {
              text = date.day == 1
                  ? ChartDataProcessor.getMonthAbbreviation(date.month, s)
                  : '';
            }

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: AppTypography.caption.copyWith(color: textColor),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: _getLeftInterval(),
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                value.toInt().toString(),
                style: AppTypography.caption.copyWith(color: textColor),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _getBottomInterval() {
    switch (widget.selectedPeriod) {
      case ChartPeriod.week:
        return 1;
      case ChartPeriod.month:
        return 5;
      case ChartPeriod.quarter:
        return 15;
      default:
        return 1;
    }
  }

  double? _getLeftInterval() {
    final spots = _generateSpots();
    if (spots.isEmpty) return 1; // Guard: return 1 instead of null

    final maxY = _calculateMaxY(spots);
    final interval = maxY / 4; // Show 4-5 labels on Y-axis
    return interval > 0 ? interval : 1; // Guard: never return 0
  }
}
