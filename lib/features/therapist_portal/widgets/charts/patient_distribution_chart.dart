import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/language_provider.dart';
import 'base_chart_card.dart';
import 'chart_utils.dart';

/// Data model for patient distribution
class PatientDistributionData {
  final String category;
  final int count;
  final Color color;

  const PatientDistributionData({
    required this.category,
    required this.count,
    required this.color,
  });

  double get percentage => 0; // Will be calculated in the widget
}

/// Donut chart showing patient distribution by category
class PatientDistributionChart extends ConsumerStatefulWidget {
  final List<PatientDistributionData> data;
  final DistributionCategory selectedCategory;
  final ValueChanged<DistributionCategory>? onCategoryChanged;

  const PatientDistributionChart({
    super.key,
    required this.data,
    this.selectedCategory = DistributionCategory.sessionType,
    this.onCategoryChanged,
  });

  @override
  ConsumerState<PatientDistributionChart> createState() =>
      _PatientDistributionChartState();
}

class _PatientDistributionChartState
    extends ConsumerState<PatientDistributionChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return BaseChartCard(
      title: s.patientDistribution,
      icon: Icons.pie_chart_rounded,
      height: 320,
      selectedPeriod: null,
      trailing: _buildCategorySelector(isDark, s),
      child: widget.data.isEmpty
          ? _buildEmptyState(isDark, s)
          : _buildChartWithLegend(isDark, s),
    );
  }

  Widget _buildCategorySelector(bool isDark, S s) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: DropdownButton<DistributionCategory>(
        value: widget.selectedCategory,
        underline: const SizedBox(),
        isDense: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
        ),
        style: AppTypography.labelMedium.copyWith(
          color: isDark ? AppColors.textMuted : AppColors.textSecondary,
        ),
        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
        items: DistributionCategory.values.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(
              category.getDisplayName(s),
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            widget.onCategoryChanged?.call(value);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.donut_large_outlined,
            size: 48,
            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            s.noDistributionData,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartWithLegend(bool isDark, S s) {
    final total = widget.data.fold<int>(0, (sum, item) => sum + item.count);

    return Row(
      children: [
        // Donut chart
        Expanded(
          flex: 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: _buildSections(total),
                  centerSpaceRadius: 60,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response == null ||
                            response.touchedSection == null) {
                          touchedIndex = null;
                        } else {
                          touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        }
                      });
                    },
                  ),
                ),
              ),
              // Center label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    total.toString(),
                    style: AppTypography.displayMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    s.patients,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 24),

        // Legend
        Expanded(flex: 2, child: _buildLegend(isDark, total, s)),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(int total) {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouch = index == touchedIndex;
      final percentage = total > 0 ? (data.count / total) * 100 : 0;

      return PieChartSectionData(
        value: data.count.toDouble(),
        color: data.color,
        radius: isTouch ? 50 : 40,
        title: isTouch ? '${percentage.toStringAsFixed(0)}%' : '',
        titleStyle: AppTypography.labelMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        titlePositionPercentageOffset: 0.55,
      );
    }).toList();
  }

  Widget _buildLegend(bool isDark, int total, S s) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.data.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final percentage = total > 0 ? (data.count / total) * 100 : 0;
          final isTouch = index == touchedIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                touchedIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isTouch
                    ? data.color.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Color indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: data.color,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Category name and count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.category,
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: isTouch
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.count} (${percentage.toStringAsFixed(1)}%)',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
