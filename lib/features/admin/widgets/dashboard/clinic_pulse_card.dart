import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/admin_provider.dart';

/// 2026 Bento analytics card surfacing clinic engagement, premium conversion,
/// clinical team capacity, and CMS content distribution from [dashboardStatsProvider].
class ClinicPulseCard extends ConsumerWidget {
  const ClinicPulseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider).language;
    final isAr = lang == AppLanguage.arabic;
    final s = S(lang);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : const Color(0xFFE6ECF1),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'نبض العيادة والمحتوى' : 'Clinic Pulse & Library',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr
                          ? 'معدلات النشاط والاشتراكات وجاهزية المكتبة العلاجية'
                          : 'Engagement rates, premium mix, and therapeutic library readiness',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.adminTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/admin/analytics'),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text(
                  s.analytics,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          statsAsync.when(
            loading: () => const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                s.errorLoadingStats,
                style: TextStyle(
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            data: (stats) => LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 680;
                final donut = _EngagementDonut(
                  stats: stats,
                  isDark: isDark,
                  isAr: isAr,
                );
                final bars = _ClinicBreakdownBars(
                  stats: stats,
                  isDark: isDark,
                  isAr: isAr,
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(width: 240, child: donut),
                      const SizedBox(width: 24),
                      Container(
                        width: 1,
                        height: 150,
                        color: isDark
                            ? AppColors.adminBorder
                            : const Color(0xFFE6ECF1),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: bars),
                    ],
                  );
                }

                return Column(
                  children: [
                    donut,
                    const SizedBox(height: 20),
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.adminBorder
                          : const Color(0xFFE6ECF1),
                    ),
                    const SizedBox(height: 16),
                    bars,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementDonut extends StatelessWidget {
  final DashboardStats stats;
  final bool isDark;
  final bool isAr;

  const _EngagementDonut({
    required this.stats,
    required this.isDark,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final total = stats.totalUsers;
    final premium = stats.premiumUsers.clamp(0, total);
    final activeNonPremium = (stats.activeUsers - premium).clamp(0, total);
    final inactive = (total - premium - activeNonPremium).clamp(0, total);
    final hasData = total > 0;

    final sections = hasData
        ? [
            if (premium > 0)
              PieChartSectionData(
                value: premium.toDouble(),
                color: AppColors.primary,
                radius: 20,
                showTitle: false,
              ),
            if (activeNonPremium > 0)
              PieChartSectionData(
                value: activeNonPremium.toDouble(),
                color: AppColors.statusSuccess,
                radius: 18,
                showTitle: false,
              ),
            if (inactive > 0)
              PieChartSectionData(
                value: inactive.toDouble(),
                color: isDark
                    ? AppColors.adminBorder
                    : const Color(0xFFE2E8F0),
                radius: 16,
                showTitle: false,
              ),
          ]
        : [
            PieChartSectionData(
              value: 1,
              color: isDark ? AppColors.adminBorder : const Color(0xFFE2E8F0),
              radius: 16,
              showTitle: false,
            ),
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 136,
          width: 136,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 44,
                  startDegreeOffset: -90,
                  sections: sections,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isAr ? 'مستخدم' : 'Users',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _LegendDot(
              color: AppColors.primary,
              label: isAr ? 'مميز ($premium)' : 'Premium ($premium)',
              isDark: isDark,
            ),
            _LegendDot(
              color: AppColors.statusSuccess,
              label: isAr
                  ? 'نشط (${stats.activeUsers})'
                  : 'Active (${stats.activeUsers})',
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ClinicBreakdownBars extends StatelessWidget {
  final DashboardStats stats;
  final bool isDark;
  final bool isAr;

  const _ClinicBreakdownBars({
    required this.stats,
    required this.isDark,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final activeRatio = stats.totalUsers > 0
        ? (stats.activeUsers / stats.totalUsers).clamp(0.0, 1.0)
        : 0.0;
    final premiumRatio = stats.totalUsers > 0
        ? (stats.premiumUsers / stats.totalUsers).clamp(0.0, 1.0)
        : 0.0;
    final publishedTotal = stats.publishedContentCount + stats.draftContentCount;
    final publishedRatio = publishedTotal > 0
        ? (stats.publishedContentCount / publishedTotal).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricBarRow(
          label: isAr ? 'نشاط آخر 30 يوماً' : '30-Day Active Rate',
          valueText:
              '${stats.activeUsers} / ${stats.totalUsers} (${(activeRatio * 100).round()}%)',
          ratio: activeRatio,
          color: AppColors.primary,
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        _MetricBarRow(
          label: isAr ? 'نسبة الاشتراكات المميزة' : 'Premium Conversion',
          valueText:
              '${stats.premiumUsers} / ${stats.totalUsers} (${(premiumRatio * 100).round()}%)',
          ratio: premiumRatio,
          color: AppColors.statusSuccess,
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        _MetricBarRow(
          label: isAr ? 'المحتوى العلاجي المنشور' : 'Published Therapeutic Content',
          valueText:
              '${stats.publishedContentCount} / $publishedTotal (${(publishedRatio * 100).round()}%)',
          ratio: publishedRatio,
          color: AppColors.statusInfo,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniPillStat(
              icon: Icons.medical_services_outlined,
              label: isAr
                  ? '${stats.therapistsCount} معالج'
                  : '${stats.therapistsCount} Clinicians',
              isDark: isDark,
              onTap: () => context.go('/admin/therapists'),
            ),
            _MiniPillStat(
              icon: Icons.article_outlined,
              label: isAr
                  ? '${stats.totalContentCount} مادة محتوى'
                  : '${stats.totalContentCount} Content Items',
              isDark: isDark,
              onTap: () => context.go('/admin/cms/content'),
            ),
            _MiniPillStat(
              icon: Icons.psychology_outlined,
              label: isAr
                  ? '${stats.psychTestsCount} اختبار نفسي'
                  : '${stats.psychTestsCount} Psych Tests',
              isDark: isDark,
              onTap: () => context.go('/admin/cms/psych-tests'),
            ),
            _MiniPillStat(
              icon: Icons.format_quote_rounded,
              label: isAr
                  ? '${stats.dailyQuotesCount} اقتباس يومي'
                  : '${stats.dailyQuotesCount} Daily Quotes',
              isDark: isDark,
              onTap: () => context.go('/admin/cms/quotes'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricBarRow extends StatelessWidget {
  final String label;
  final String valueText;
  final double ratio;
  final Color color;
  final bool isDark;

  const _MetricBarRow({
    required this.label,
    required this.valueText,
    required this.ratio,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: isDark
                  ? AppColors.adminBorder
                  : const Color(0xFFEDF2F7),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniPillStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _MiniPillStat({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.adminGlass.withValues(alpha: 0.55)
                : const Color(0xFFF4F7FA),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? AppColors.adminBorder : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
