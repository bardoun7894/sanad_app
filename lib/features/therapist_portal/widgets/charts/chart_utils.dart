import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/language_provider.dart';

/// Chart period options for data visualization
enum ChartPeriod {
  week,
  month,
  quarter,
  year,
  custom;

  String getDisplayName(S s) {
    switch (this) {
      case ChartPeriod.week:
        return s.week;
      case ChartPeriod.month:
        return s.month;
      case ChartPeriod.quarter:
        return s.quarter;
      case ChartPeriod.year:
        return s.yearPeriod;
      case ChartPeriod.custom:
        return s.custom;
    }
  }

  int get days {
    switch (this) {
      case ChartPeriod.week:
        return 7;
      case ChartPeriod.month:
        return 30;
      case ChartPeriod.quarter:
        return 90;
      case ChartPeriod.year:
        return 365;
      case ChartPeriod.custom:
        return 30; // default
    }
  }
}

/// Patient distribution category options
enum DistributionCategory {
  sessionType,
  ageGroup,
  presentingIssue;

  String getDisplayName(S s) {
    switch (this) {
      case DistributionCategory.sessionType:
        return s.sessionTypeDistribution;
      case DistributionCategory.ageGroup:
        return s.ageGroup;
      case DistributionCategory.presentingIssue:
        return s.presentingIssue;
    }
  }
}

/// Chart color palette for consistent styling
class ChartColors {
  ChartColors._();

  // Category colors for pie charts and bar charts
  static const List<Color> categoryColors = [
    Color(0xFF117A8D), // Primary teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Green
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFF97316), // Orange
    Color(0xFFEC4899), // Pink
    Color(0xFF6366F1), // Indigo
  ];

  // Semantic colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  // Gradient colors
  static const Color gradientStart = Color(0xFF1594AC);
  static const Color gradientEnd = Color(0xFF117A8D);

  /// Get color by index with cycling
  static Color getColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  /// Get gradient for area charts
  static LinearGradient getChartGradient(Color color, {double opacity = 0.2}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: opacity),
        color.withValues(alpha: 0.05),
      ],
    );
  }
}

/// Chart styling utilities
class ChartStyles {
  ChartStyles._();

  /// Default grid style for line and bar charts
  static FlGridData defaultGrid(bool isDark) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: 1,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          strokeWidth: 1,
        );
      },
    );
  }

  /// Default border style
  static FlBorderData defaultBorder(bool isDark) {
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
        left: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    );
  }

  /// Default tooltip style
  static LineTooltipItem? defaultLineTooltip(
    LineBarSpot spot,
    bool isDark,
    String Function(double value)? formatter,
  ) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final value = formatter?.call(spot.y) ?? spot.y.toStringAsFixed(0);

    return LineTooltipItem(
      value,
      TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
    );
  }

  /// Default tooltip background
  static Color defaultTooltipBackground(bool isDark) {
    return isDark ? AppColors.surfaceDark : Colors.white;
  }

  /// Default touch response for pie charts
  static PieTouchResponse defaultPieTouch(
    FlTouchEvent event,
    PieTouchResponse? pieTouchResponse,
  ) {
    return pieTouchResponse ?? PieTouchResponse(null);
  }
}

/// Data transformation helpers
class ChartDataProcessor {
  ChartDataProcessor._();

  /// Calculate percentage change between two values
  static double calculatePercentageChange(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  /// Format percentage with sign
  static String formatPercentage(double percentage, {bool includeSign = true}) {
    final sign = percentage >= 0 ? '+' : '';
    return includeSign
        ? '$sign${percentage.toStringAsFixed(1)}%'
        : '${percentage.toStringAsFixed(1)}%';
  }

  static String _currencySymbol(String code) => const {
        'USD': '\$', 'SAR': '\$', 'AED': 'AED', 'EUR': '€', 'GBP': '£',
      }[code] ?? '\$';

  /// Format currency
  static String formatCurrency(double amount, String currency) {
    return '${_currencySymbol(currency)}${amount.toStringAsFixed(2)}';
  }

  /// Format large numbers with K/M suffix
  static String formatLargeNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  /// Generate date labels for X-axis
  static List<String> generateDateLabels(
    ChartPeriod period,
    DateTime startDate,
    S s,
  ) {
    final labels = <String>[];
    final days = period.days;

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      if (period == ChartPeriod.week) {
        // Show day abbreviation (Mon, Tue, etc.)
        labels.add(getDayAbbreviation(date.weekday, s));
      } else if (period == ChartPeriod.month) {
        // Show date (1, 5, 10, 15, 20, 25, 30)
        if (i % 5 == 0) {
          labels.add(date.day.toString());
        } else {
          labels.add('');
        }
      } else {
        // Show month abbreviation for quarter/year
        if (i % 30 == 0) {
          labels.add(getMonthAbbreviation(date.month, s));
        } else {
          labels.add('');
        }
      }
    }

    return labels;
  }

  /// Get day abbreviation
  static String getDayAbbreviation(int weekday, S s) {
    final days = [s.mon, s.tue, s.wed, s.thu, s.fri, s.sat, s.sun];
    return days[weekday - 1];
  }

  /// Get month abbreviation
  static String getMonthAbbreviation(int month, S s) {
    final months = [
      s.jan,
      s.feb,
      s.mar,
      s.apr,
      s.mayShort,
      s.jun,
      s.jul,
      s.aug,
      s.sep,
      s.oct,
      s.nov,
      s.dec,
    ];
    return months[month - 1];
  }

  /// Normalize data to 0-100 range for sparklines
  static List<FlSpot> normalizeSparklineData(List<double> data) {
    if (data.isEmpty) return [];

    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = max - min;

    if (range == 0) {
      return data
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), 50))
          .toList();
    }

    return data.asMap().entries.map((e) {
      final normalized = ((e.value - min) / range) * 100;
      return FlSpot(e.key.toDouble(), normalized);
    }).toList();
  }
}
