import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/language_provider.dart';
import 'chart_utils.dart';

/// Base card container for all chart widgets
/// Provides consistent styling, header, and period toggles
class BaseChartCard extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final double? height;
  final ChartPeriod? selectedPeriod;
  final List<ChartPeriod>? availablePeriods;
  final ValueChanged<ChartPeriod>? onPeriodChanged;
  final Widget? trailing;

  const BaseChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.height,
    this.selectedPeriod,
    this.availablePeriods,
    this.onPeriodChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon, title, and period toggles
          _buildHeader(context, isDark, s),

          const SizedBox(height: 20),

          // Chart content
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, S s) {
    return Row(
      children: [
        // Icon container
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),

        const SizedBox(width: 12),

        // Title
        Expanded(
          child: Text(
            title,
            style: AppTypography.headingSmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),

        // Period toggles or trailing widget
        if (trailing != null)
          trailing!
        else if (availablePeriods != null && selectedPeriod != null)
          _buildPeriodToggles(isDark, s),
      ],
    );
  }

  Widget _buildPeriodToggles(bool isDark, S s) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availablePeriods!.map((period) {
          final isSelected = period == selectedPeriod;

          return GestureDetector(
            onTap: () => onPeriodChanged?.call(period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                period.getDisplayName(s),
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondary),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Compact chart card without period toggles (for KPI sparklines)
class CompactChartCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double? width;
  final double? height;

  const CompactChartCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color:
            backgroundColor ?? (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}
