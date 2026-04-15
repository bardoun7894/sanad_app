import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

/// Analytics data for bookings overview
class BookingsAnalyticsData {
  final int total;
  final int pending;
  final int confirmed;
  final int completed;
  final List<int> weeklyVolume; // Last 4 weeks

  const BookingsAnalyticsData({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.completed,
    required this.weeklyVolume,
  });

  int get weeklyChange {
    if (weeklyVolume.length < 2) return 0;
    final thisWeek = weeklyVolume.last;
    final lastWeek = weeklyVolume[weeklyVolume.length - 2];
    if (lastWeek == 0) return 0;
    return ((thisWeek - lastWeek) / lastWeek * 100).round();
  }
}

/// Analytics header for bookings screen showing stats and trends
class BookingsAnalyticsHeader extends ConsumerWidget {
  final BookingsAnalyticsData data;

  const BookingsAnalyticsHeader({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              _buildStatColumn(s.total, data.total, Icons.calendar_month),
              const SizedBox(width: 16),
              _buildStatColumn(s.pending, data.pending, Icons.pending_actions),
              const SizedBox(width: 16),
              _buildStatColumn(
                s.confirmed,
                data.confirmed,
                Icons.event_available,
              ),
              const SizedBox(width: 16),
              _buildStatColumn(s.completed, data.completed, Icons.check_circle),
            ],
          ),

          const SizedBox(height: 20),

          // Mini bar chart + change badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bar chart
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: data.weeklyVolume.map((count) {
                      final maxCount = data.weeklyVolume.reduce(
                        (a, b) => a > b ? a : b,
                      );
                      final height = maxCount > 0
                          ? (count / maxCount) * 40
                          : 0.0;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Change badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: data.weeklyChange >= 0
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data.weeklyChange >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data.weeklyChange.abs()}%',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Label
          Text(
            s.last4WeeksTrend,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: AppTypography.headingLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
