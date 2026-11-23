import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';

/// Responsive 4-card Bento KPI row with a deep Sanad Teal hero card for Active
/// Users and three crisp elevated operational cards.
class DashboardKpiRow extends ConsumerWidget {
  const DashboardKpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider).language;
    final isAr = lang == AppLanguage.arabic;
    final s = S(lang);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          final skeleton = Container(
            height: isCompact ? 132 : 148,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.adminSurface
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.adminBorder : const Color(0xFFE6ECF1),
              ),
            ),
          );
          if (isCompact) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                4,
                (_) => SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: skeleton,
                ),
              ),
            );
          }
          return Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: i == 3 ? 0 : 16),
                  child: skeleton,
                ),
              ),
            ),
          );
        },
      ),
      error: (e, _) => Text(s.errorLoadingStats),
      data: (stats) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompact = width < 700;
          final activeRatio = stats.totalUsers > 0
              ? (stats.activeUsers / stats.totalUsers).clamp(0.0, 1.0)
              : 0.0;

          final children = [
            _HeroStatCard(
              title: s.activeUsers,
              value: _formatNumber(stats.activeUsers),
              trend: stats.usersTrend,
              footerLabel: isAr
                  ? 'من إجمالي ${stats.totalUsers} مستخدم'
                  : 'of ${stats.totalUsers} total users',
              progress: activeRatio,
              compact: isCompact,
              onTap: () => context.go('/admin/users'),
            ),
            _BentoStatCard(
              title: s.criticalFlags,
              value: stats.criticalFlags.toString(),
              badgeText: stats.criticalFlags > 0
                  ? s.needsAttention
                  : s.allClear,
              icon: stats.criticalFlags > 0
                  ? Icons.warning_amber_rounded
                  : Icons.verified_user_outlined,
              accentColor: stats.criticalFlags > 0
                  ? AppColors.statusDanger
                  : AppColors.statusSuccess,
              badgePositive: stats.criticalFlags == 0,
              footerText: stats.criticalFlags > 0
                  ? (isAr ? 'يتطلب مراجعة فورية' : 'Requires triage')
                  : (isAr ? 'لا توجد حالات حرجة' : 'Clinic is clear'),
              isDark: isDark,
              compact: isCompact,
              highlightBorder: stats.criticalFlags > 0,
              onTap: () => context.push('/admin/crisis-alerts'),
            ),
            _BentoStatCard(
              title: s.todaysSessions,
              value: stats.sessionsToday.toString(),
              badgeText: '${stats.pendingSessions} ${s.pending}',
              icon: Icons.event_available_rounded,
              accentColor: AppColors.statusInfo,
              badgePositive: stats.pendingSessions == 0,
              footerText: isAr
                  ? '${stats.therapistsCount} معالج متاح'
                  : '${stats.therapistsCount} active clinicians',
              isDark: isDark,
              compact: isCompact,
              onTap: () => context.go('/admin/bookings'),
            ),
            _BentoStatCard(
              title: s.earnings,
              value: stats.formattedRevenue,
              badgeText: '${stats.premiumUsers} ${s.premium}',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: AppColors.statusSuccess,
              badgePositive: true,
              footerText: isAr
                  ? '${stats.newUsersThisMonth} مشترك جديد هذا الشهر'
                  : '+${stats.newUsersThisMonth} new this month',
              isDark: isDark,
              compact: isCompact,
              onTap: () => context.go('/admin/payments'),
            ),
          ];

          if (width < 700) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: children
                  .map((e) => SizedBox(width: (width - 12) / 2, child: e))
                  .toList(),
            );
          }

          return Row(
            children: children.asMap().entries.map((entry) {
              final isLast = entry.key == children.length - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: isLast ? 0 : 16),
                  child: entry.value,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

/// Primary hero KPI card inspired by WeCare / late-2026 Bento clinical dashboards.
class _HeroStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final String footerLabel;
  final double progress;
  final bool compact;
  final VoidCallback onTap;

  const _HeroStatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.footerLabel,
    required this.progress,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: EdgeInsets.all(compact ? 16 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF138397), Color(0xFF0A5462)],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 24 : 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trend,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 5,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                footerLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean elevated Bento KPI card with icon chip, tabular numeral, and status pill.
class _BentoStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String badgeText;
  final IconData icon;
  final Color accentColor;
  final bool badgePositive;
  final String footerText;
  final bool isDark;
  final bool compact;
  final bool highlightBorder;
  final VoidCallback onTap;

  const _BentoStatCard({
    required this.title,
    required this.value,
    required this.badgeText,
    required this.icon,
    required this.accentColor,
    required this.badgePositive,
    required this.footerText,
    required this.isDark,
    required this.compact,
    this.highlightBorder = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = badgePositive
        ? AppColors.statusSuccess
        : (highlightBorder ? AppColors.statusDanger : AppColors.statusWarning);

    return Material(
      color: isDark ? AppColors.adminSurface : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.all(compact ? 16 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlightBorder
                  ? AppColors.statusDanger.withValues(alpha: 0.45)
                  : (isDark
                        ? AppColors.adminBorder
                        : const Color(0xFFE6ECF1)),
              width: highlightBorder ? 1.4 : 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.035),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.adminTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: accentColor),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 12),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 22 : 28,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              SizedBox(height: compact ? 8 : 12),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                footerText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
