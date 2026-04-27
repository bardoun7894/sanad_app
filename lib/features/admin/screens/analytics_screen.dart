import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../providers/admin_analytics_provider.dart';
import '../../../core/l10n/app_strings.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analyticsState = ref.watch(adminAnalyticsProvider);
    final isMobile = AdminResponsive.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: AdminResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.analytics,
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.analyticsSubtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _DateRangeButton(isDark: isDark),
                    _ExportButton(isDark: isDark),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Charts Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1000;

                return Column(
                  children: [
                    // Row 1: Session Volume & Revenue
                    if (isWide)
                      SizedBox(
                        height: 320,
                        child: Row(
                          children: [
                            Expanded(
                              child: _ChartCard(
                                title: AppStrings.adminSessionVolume,
                                subtitle: AppStrings.weeklySessions,
                                isDark: isDark,
                                child: _SessionVolumeChart(
                                  isDark: isDark,
                                  data: analyticsState.sessionVolume,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _ChartCard(
                                title: AppStrings.earnings,
                                subtitle: AppStrings.monthlyRevenue,
                                isDark: isDark,
                                child: _RevenueChart(
                                  isDark: isDark,
                                  data: analyticsState.revenue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 300,
                        child: _ChartCard(
                          title: AppStrings.adminSessionVolume,
                          subtitle: AppStrings.weeklySessions,
                          isDark: isDark,
                          child: _SessionVolumeChart(
                            isDark: isDark,
                            data: analyticsState.sessionVolume,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: _ChartCard(
                          title: AppStrings.earnings,
                          subtitle: AppStrings.monthlyRevenue,
                          isDark: isDark,
                          child: _RevenueChart(
                            isDark: isDark,
                            data: analyticsState.revenue,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Row 2: No-show Rate & Distribution
                    if (isWide)
                      SizedBox(
                        height: 320,
                        child: Row(
                          children: [
                            Expanded(
                              child: _ChartCard(
                                title: AppStrings.adminNoShowRate,
                                subtitle: AppStrings.missedSessionsPercentage,
                                isDark: isDark,
                                child: _NoShowChart(
                                  isDark: isDark,
                                  rate: analyticsState.noShowRate,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _ChartCard(
                                title: AppStrings.adminSessionTypes,
                                subtitle: AppStrings.typeDistribution,
                                isDark: isDark,
                                child: _SessionTypeChart(
                                  isDark: isDark,
                                  distribution:
                                      analyticsState.sessionTypeDistribution,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 300,
                        child: _ChartCard(
                          title: AppStrings.adminNoShowRate,
                          subtitle: AppStrings.missedSessionsPercentage,
                          isDark: isDark,
                          child: _NoShowChart(
                            isDark: isDark,
                            rate: analyticsState.noShowRate,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: _ChartCard(
                          title: AppStrings.adminSessionTypes,
                          subtitle: AppStrings.typeDistribution,
                          isDark: isDark,
                          child: _SessionTypeChart(
                            isDark: isDark,
                            distribution:
                                analyticsState.sessionTypeDistribution,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Row 3: Clinician Performance
                    SizedBox(
                      height: 400,
                      child: _ChartCard(
                        title: AppStrings.adminClinicianPerformance,
                        subtitle: AppStrings.completedSessionsMonth,
                        isDark: isDark,
                        child: _ClinicianPerformanceChart(
                          isDark: isDark,
                          data: analyticsState.clinicianPerformance,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Row 4: Performance Metrics (Response Speed & Ratings)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1000;
                return isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: _ChartCard(
                              title: AppStrings.adminAverageResponseSpeed,
                              subtitle: AppStrings.timeToFirstReply,
                              isDark: isDark,
                              child: _ResponseSpeedChart(
                                isDark: isDark,
                                speed: analyticsState.responseSpeed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _ChartCard(
                              title: AppStrings.adminPatientSatisfaction,
                              subtitle: AppStrings.averageStarRatings,
                              isDark: isDark,
                              child: _StarRatingsChart(
                                isDark: isDark,
                                rating: analyticsState.averageRating,
                                count: analyticsState.totalReviews,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 300,
                            child: _ChartCard(
                              title: AppStrings.adminAverageResponseSpeed,
                              subtitle: AppStrings.timeToFirstReply,
                              isDark: isDark,
                              child: _ResponseSpeedChart(
                                isDark: isDark,
                                speed: analyticsState.responseSpeed,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 300,
                            child: _ChartCard(
                              title: AppStrings.adminPatientSatisfaction,
                              subtitle: AppStrings.averageStarRatings,
                              isDark: isDark,
                              child: _StarRatingsChart(
                                isDark: isDark,
                                rating: analyticsState.averageRating,
                                count: analyticsState.totalReviews,
                              ),
                            ),
                          ),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final bool isDark;

  const _DateRangeButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.last30Days,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.adminTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final bool isDark;

  const _ExportButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        // TODO: Implement export
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exporting as $value...')));
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'PDF', child: Text(AppStrings.exportAsPDF)),
        const PopupMenuItem(value: 'CSV', child: Text(AppStrings.exportAsCSV)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Row(
          children: [
            Icon(Icons.download_rounded, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text(
              AppStrings.export,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// Real-time Analytics Charts using fl_chart
class _SessionVolumeChart extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> data;

  const _SessionVolumeChart({required this.isDark, this.data = const []});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          AppStrings.noSessionData,
          style: TextStyle(
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      );
    }

    // Find max value for scaling left axis
    final maxCount = data.isEmpty
        ? 10.0
        : data
                  .map((e) => (e['count'] as num).toDouble())
                  .reduce((a, b) => a > b ? a : b) +
              2;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                isDark ? const Color(0xFF1F2937) : Colors.white,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                final days = [
                  AppStrings.mon,
                  AppStrings.tue,
                  AppStrings.wed,
                  AppStrings.thu,
                  AppStrings.fri,
                  AppStrings.sat,
                  AppStrings.sun,
                ];
                final dayName = days[flSpot.x.toInt() - 1];
                return LineTooltipItem(
                  '$dayName: ${flSpot.y.toInt()} ${AppStrings.sessions}',
                  TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final days = [
                  AppStrings.mon,
                  AppStrings.tue,
                  AppStrings.wed,
                  AppStrings.thu,
                  AppStrings.fri,
                  AppStrings.sat,
                  AppStrings.sun,
                ];
                if (value.toInt() >= 1 && value.toInt() <= 7) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt() - 1],
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: 7,
        minY: 0,
        maxY: maxCount,
        lineBarsData: [
          LineChartBarData(
            spots: data
                .map((e) => FlSpot(e['day'].toDouble(), e['count'].toDouble()))
                .toList(),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppColors.primary,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> data;

  const _RevenueChart({required this.isDark, this.data = const []});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final maxVal =
        data
            .map((e) => (e['revenue'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? const Color(0xFF1F2937) : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final monthNum = data[group.x.toInt()]['month'] as int;
              final months = [
                '',
                AppStrings.jan,
                AppStrings.feb,
                AppStrings.mar,
                AppStrings.apr,
                AppStrings.mayShort,
                AppStrings.jun,
                AppStrings.jul,
                AppStrings.aug,
                AppStrings.sep,
                AppStrings.oct,
                AppStrings.nov,
                AppStrings.dec,
              ];
              return BarTooltipItem(
                '${months[monthNum]}\n',
                TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '${rod.toY.toInt()} ${AppStrings.sar}',
                    style: const TextStyle(
                      color: AppColors.statusSuccess,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final monthNum = data[value.toInt()]['month'] as int;
                  final months = [
                    '',
                    AppStrings.jan,
                    AppStrings.feb,
                    AppStrings.mar,
                    AppStrings.apr,
                    AppStrings.mayShort,
                    AppStrings.jun,
                    AppStrings.jul,
                    AppStrings.aug,
                    AppStrings.sep,
                    AppStrings.oct,
                    AppStrings.nov,
                    AppStrings.dec,
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      months[monthNum],
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[index]['revenue'].toDouble(),
                gradient: const LinearGradient(
                  colors: [AppColors.statusSuccess, AppColors.success],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _NoShowChart extends StatelessWidget {
  final bool isDark;
  final double rate;

  const _NoShowChart({required this.isDark, this.rate = 0.0});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        startDegreeOffset: -90,
        sections: [
          PieChartSectionData(
            color: AppColors.primary,
            value: 100 - rate,
            title: '${(100 - rate).round()}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _Badge(
              Icons.check_circle_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            badgePositionPercentageOffset: 1.1,
          ),
          PieChartSectionData(
            color: AppColors.statusWarning,
            value: rate,
            title: '${rate.round()}%',
            radius: 55,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: _Badge(
              Icons.warning_rounded,
              size: 20,
              color: AppColors.statusWarning,
            ),
            badgePositionPercentageOffset: 1.1,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const _Badge(this.icon, {required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, size: size * 0.7, color: color),
      ),
    );
  }
}

class _SessionTypeChart extends StatelessWidget {
  final bool isDark;
  final Map<String, int> distribution;

  const _SessionTypeChart({required this.isDark, this.distribution = const {}});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Optional: Handle taps
                },
              ),
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: AppColors.primary,
                  value: (distribution['video'] ?? 0).toDouble(),
                  title: '${(distribution['video'] ?? 0)}',
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.6,
                ),
                PieChartSectionData(
                  color: AppColors.statusInfo,
                  value: (distribution['audio'] ?? 0).toDouble(),
                  title: '${(distribution['audio'] ?? 0)}',
                  radius: 65,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.6,
                ),
                PieChartSectionData(
                  color: AppColors.statusSuccess,
                  value: (distribution['chat'] ?? 0).toDouble(),
                  title: '${(distribution['chat'] ?? 0)}',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.6,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ChartLegend(
          isDark: isDark,
          items: [
            LegendItem(AppColors.primary, AppStrings.sessionVideo),
            LegendItem(AppColors.statusInfo, AppStrings.sessionAudio),
            LegendItem(AppColors.statusSuccess, AppStrings.sessionChat),
          ],
        ),
      ],
    );
  }
}

// Legend for Session Type Chart
class _ChartLegend extends StatelessWidget {
  final List<LegendItem> items;
  final bool isDark;

  const _ChartLegend({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class LegendItem {
  final Color color;
  final String label;
  LegendItem(this.color, this.label);
}

class _ClinicianPerformanceChart extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>>? data;

  const _ClinicianPerformanceChart({required this.isDark, this.data});

  @override
  Widget build(BuildContext context) {
    // Use provided data
    final clinicians = data ?? [];

    return clinicians.isEmpty
        ? Center(
            child: Text(
              AppStrings.noClinicianData,
              style: TextStyle(
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clinicians.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final clinician = clinicians[index];
              final maxSessions = clinicians.isEmpty
                  ? 100
                  : clinicians
                        .map((e) => (e['sessions'] as num).toInt())
                        .reduce((a, b) => a > b ? a : b)
                        .toDouble();
              final percentage = (clinician['sessions'] as int) / maxSessions;

              return Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      clinician['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.adminTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage.clamp(0.05, 1.0),
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${clinician['sessions']}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
  }
}

class _ResponseSpeedChart extends StatelessWidget {
  final bool isDark;
  final String speed;

  const _ResponseSpeedChart({required this.isDark, required this.speed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer_outlined,
              size: 32,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            speed,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.timeToFirstReply,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRatingsChart extends StatelessWidget {
  final bool isDark;
  final double rating;
  final int count;

  const _StarRatingsChart({
    required this.isDark,
    required this.rating,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              // 4.8 -> 4 full stars, 1 half if > 0.5?
              // Simple logic:
              IconData icon;
              if (index < rating.floor()) {
                icon = Icons.star_rounded;
              } else if (index == rating.floor() &&
                  (rating - rating.floor()) >= 0.5) {
                icon = Icons.star_half_rounded;
              } else {
                icon = Icons.star_outline_rounded;
              }

              return Icon(icon, size: 32, color: Colors.amber);
            }),
          ),
          const SizedBox(height: 16),
          Text(
            '${rating.toStringAsFixed(1)} / 5.0',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.basedOnReviewsLabel} $count',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
