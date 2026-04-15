import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../engagement/providers/streak_provider.dart';
import '../../mood/providers/mood_tracker_provider.dart';

/// Horizontal scrolling row of insight stat cards
class ProgressInsightsRow extends ConsumerWidget {
  const ProgressInsightsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakData = ref.watch(streakProvider);
    final moodState = ref.watch(moodTrackerProvider);
    final s = ref.watch(stringsProvider);

    // Calculate mood trend
    final weeklyMoods = moodState.weeklyEntries;
    final moodTrend = _calculateMoodTrend(weeklyMoods.length);

    return SizedBox(
      height: 115,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
        children: [
          // Mood Trend Card
          _InsightCard(
            icon: Icons.insights_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: s.moodTrend,
            value: weeklyMoods.isEmpty ? '-' : '${weeklyMoods.length}',
            subtitle: s.thisWeek,
            trend: moodTrend,
          ),
          const SizedBox(width: 12),

          // Streak Card
          _InsightCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFF97316),
            title: s.streak,
            value: '${streakData.currentStreak}',
            subtitle: streakData.currentStreak == 1 ? s.day : s.days,
            showFireEffect: streakData.currentStreak >= 7,
          ),
          const SizedBox(width: 12),

          // Sessions Card
          _InsightCard(
            icon: Icons.video_camera_front_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: s.sessions,
            value: '${streakData.totalSessions}',
            subtitle: s.total,
          ),
          const SizedBox(width: 12),

          // Challenges Card
          _InsightCard(
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF10B981),
            title: s.challenges,
            value: '${streakData.challengesCompleted}',
            subtitle: s.completed,
          ),
        ],
      ),
    );
  }

  String _calculateMoodTrend(int moodCount) {
    if (moodCount == 0) return 'neutral';
    if (moodCount >= 5) return 'up';
    if (moodCount >= 3) return 'stable';
    return 'down';
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final String? trend;
  final bool showFireEffect;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.trend,
    this.showFireEffect = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Icon(icon, size: 16, color: iconColor),
                ],
              ),
              if (trend != null || showFireEffect) const Spacer(),
              if (trend != null) _TrendIndicator(trend: trend!),
              if (showFireEffect) const _FireBadge(),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.headingSmall.copyWith(
              fontSize: 20,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  final String trend;

  const _TrendIndicator({required this.trend});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (trend) {
      case 'up':
        icon = Icons.trending_up_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'down':
        icon = Icons.trending_down_rounded;
        color = const Color(0xFFEF4444);
        break;
      default:
        icon = Icons.trending_flat_rounded;
        color = const Color(0xFFF59E0B);
    }

    return Icon(icon, size: 16, color: color);
  }
}

class _FireBadge extends StatelessWidget {
  const _FireBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.whatshot_rounded, size: 12, color: Colors.white),
    );
  }
}
