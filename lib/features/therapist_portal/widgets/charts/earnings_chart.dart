import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/language_provider.dart';
import 'base_chart_card.dart';
import 'chart_utils.dart';

/// Data model for earnings
class EarningsData {
  final String label;
  final double current;
  final double previous;

  const EarningsData({
    required this.label,
    required this.current,
    required this.previous,
  });

  double get percentageChange =>
      ChartDataProcessor.calculatePercentageChange(current, previous);
}

/// Bar chart showing earnings with period comparison
class EarningsChart extends ConsumerStatefulWidget {
  final List<EarningsData> data;
  final ChartPeriod selectedPeriod;
  final String currency;
  final ValueChanged<ChartPeriod>? onPeriodChanged;

  const EarningsChart({
    super.key,
    required this.data,
    this.selectedPeriod = ChartPeriod.week,
    this.currency = 'USD',
    this.onPeriodChanged,
  });

  @override
  ConsumerState<EarningsChart> createState() => _EarningsChartState();
}

class _EarningsChartState extends ConsumerState<EarningsChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return BaseChartCard(
      title: s.earnings,
      icon: Icons.attach_money_rounded,
      height: 260,
      selectedPeriod: widget.selectedPeriod,
      availablePeriods: const [ChartPeriod.week, ChartPeriod.month],
      onPeriodChanged: widget.onPeriodChanged,
      child: Column(
        children: [
          // Total earnings with change
          _buildTotalEarnings(isDark),

          const SizedBox(height: 20),

          // Bar chart
          Expanded(
            child: widget.data.isEmpty
                ? _buildEmptyState(isDark, s)
                : _buildChart(isDark, s),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalEarnings(bool isDark) {
    final total = widget.data.fold<double>(
      0,
      (sum, item) => sum + item.current,
    );
    final prevTotal = widget.data.fold<double>(
      0,
      (sum, item) => sum + item.previous,
    );
    final change = ChartDataProcessor.calculatePercentageChange(
      total,
      prevTotal,
    );

    return Row(
      children: [
        Text(
          ChartDataProcessor.formatCurrency(total, widget.currency),
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: change >= 0
                ? ChartColors.success.withValues(alpha: 0.1)
                : ChartColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                change >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14,
                color: change >= 0 ? ChartColors.success : ChartColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                ChartDataProcessor.formatPercentage(change.abs()),
                style: AppTypography.labelSmall.copyWith(
                  color: change >= 0 ? ChartColors.success : ChartColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            s.noEarningsData,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark, S s) {
    final maxY = _calculateMaxY();

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        barGroups: _buildBarGroups(),
        gridData: ChartStyles.defaultGrid(isDark),
        borderData: ChartStyles.defaultBorder(isDark),
        titlesData: _buildTitles(isDark),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
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
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = widget.data[group.x];
              final isCurrent = rodIndex == 0;
              final value = isCurrent ? data.current : data.previous;

              return BarTooltipItem(
                '${isCurrent ? s.current : s.previousPeriod}\n',
                TextStyle(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(
                    text: ChartDataProcessor.formatCurrency(
                      value,
                      widget.currency,
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
          touchCallback: (event, response) {
            setState(() {
              if (response == null || response.spot == null) {
                touchedIndex = null;
              } else {
                touchedIndex = response.spot!.touchedBarGroupIndex;
              }
            });
          },
          handleBuiltInTouches: true,
        ),
        groupsSpace: 16,
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouch = index == touchedIndex;

      return BarChartGroupData(
        x: index,
        barRods: [
          // Current period bar
          BarChartRodData(
            toY: data.current,
            color: AppColors.primary,
            width: isTouch ? 18 : 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          // Previous period bar (ghost)
          BarChartRodData(
            toY: data.previous,
            color: AppColors.primary.withValues(alpha: 0.3),
            width: isTouch ? 18 : 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();
  }

  double _calculateMaxY() {
    if (widget.data.isEmpty) return 1000;

    final maxCurrent = widget.data
        .map((e) => e.current)
        .reduce((a, b) => a > b ? a : b);
    final maxPrevious = widget.data
        .map((e) => e.previous)
        .reduce((a, b) => a > b ? a : b);
    final max = maxCurrent > maxPrevious ? maxCurrent : maxPrevious;

    // Add 20% padding
    return max * 1.2;
  }

  FlTitlesData _buildTitles(bool isDark) {
    final textColor = isDark ? AppColors.textMuted : AppColors.textSecondary;

    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= widget.data.length) return const SizedBox();

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.data[value.toInt()].label,
                style: AppTypography.caption.copyWith(color: textColor),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                ChartDataProcessor.formatLargeNumber(value),
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
}
