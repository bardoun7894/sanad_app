import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import 'chart_utils.dart';

/// Data model for KPI metrics
class KPIData {
  final String label;
  final String value;
  final double percentageChange;
  final List<double> trendData; // Last 7 days
  final IconData icon;
  final Color color;

  const KPIData({
    required this.label,
    required this.value,
    required this.percentageChange,
    required this.trendData,
    required this.icon,
    required this.color,
  });

  bool get isPositive => percentageChange >= 0;
}

/// Compact KPI card with sparkline trend
class KPISparklineCard extends StatelessWidget {
  final KPIData data;

  const KPISparklineCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 160,
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and change badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 16, color: data.color),
              ),
              const Spacer(),
              _buildChangeBadge(isDark),
            ],
          ),

          const SizedBox(height: 8),

          // Value
          Text(
            data.value,
            style: AppTypography.headingMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          // Label
          Text(
            data.label,
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Sparkline
          Flexible(child: SizedBox(height: 28, child: _buildSparkline(isDark))),
        ],
      ),
    );
  }

  Widget _buildChangeBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: data.isPositive
            ? ChartColors.success.withValues(alpha: 0.1)
            : ChartColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            size: 10,
            color: data.isPositive ? ChartColors.success : ChartColors.error,
          ),
          const SizedBox(width: 2),
          Text(
            ChartDataProcessor.formatPercentage(data.percentageChange.abs()),
            style: AppTypography.labelSmall.copyWith(
              color: data.isPositive ? ChartColors.success : ChartColors.error,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkline(bool isDark) {
    if (data.trendData.isEmpty) {
      return const SizedBox();
    }

    // Normalize data to 0-100 range for better visualization
    final spots = ChartDataProcessor.normalizeSparklineData(data.trendData);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: data.color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  data.color.withValues(alpha: 0.2),
                  data.color.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrollable row of KPI cards
class KPISparklineRow extends StatelessWidget {
  final List<KPIData> kpiData;

  const KPISparklineRow({super.key, required this.kpiData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
        itemCount: kpiData.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return KPISparklineCard(data: kpiData[index]);
        },
      ),
    );
  }
}
