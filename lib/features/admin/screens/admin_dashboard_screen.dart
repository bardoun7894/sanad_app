import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../chat/providers/handoff_provider.dart';
import '../providers/activity_log_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/signup_failures_provider.dart';
import '../widgets/dashboard/clinic_pulse_card.dart';
import '../widgets/dashboard/crisis_alerts_panel.dart';
import '../widgets/dashboard/dashboard_kpi_row.dart';
import '../widgets/dashboard/dashboard_operational_cards.dart';
import '../widgets/dashboard/risk_alerts_panel.dart';
import '../widgets/dashboard/weekly_agenda.dart';
import '../widgets/handoff_queue_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = ref.watch(languageProvider).language;
    final isAr = lang == AppLanguage.arabic;
    final s = S(lang);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Modern Command Header (Greeting + Date Pill + Refresh)
          _buildHeader(context, ref, theme, isDark, isMobile, isAr, s),
          const SizedBox(height: 16),

          // 2. Quick Actions Pill Strip (2026 Bento pattern)
          _buildQuickActionsStrip(context, isDark, s),
          const SizedBox(height: 20),

          // 3. Hero Bento KPI Row
          const DashboardKpiRow(),
          const SizedBox(height: 20),

          // 4. Clinical Triage Bento Row (Crisis Alerts + AI Handoff Queue)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 960) {
                return Column(
                  children: [
                    SizedBox(
                      height: isMobile ? 250 : 270,
                      child: const CrisisAlertsPanel(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: isMobile ? 240 : 270,
                      child: const HandoffQueueWidget(),
                    ),
                  ],
                );
              }
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(height: 280, child: CrisisAlertsPanel()),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: SizedBox(height: 280, child: HandoffQueueWidget()),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 5. Main Operational Bento Row (Weekly Agenda + Risk Alerts)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1000) {
                return Column(
                  children: [
                    SizedBox(
                      height: isMobile ? 400 : 480,
                      child: const WeeklyAgenda(),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    SizedBox(
                      height: isMobile ? 340 : 400,
                      child: const RiskAlertsPanel(),
                    ),
                  ],
                );
              }
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(height: 480, child: WeeklyAgenda()),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: SizedBox(height: 480, child: RiskAlertsPanel()),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 6. Clinic Pulse & Content Breakdown (fl_chart Donut + Metric Bars)
          const ClinicPulseCard(),
          const SizedBox(height: 20),

          // 7. Bottom Operational Row (Signup Health + Recent Activity)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 960) {
                return const Column(
                  children: [
                    DashboardIncompleteProfilesCard(),
                    SizedBox(height: 16),
                    DashboardRecentActivityCard(),
                  ],
                );
              }
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: DashboardIncompleteProfilesCard()),
                  SizedBox(width: 20),
                  Expanded(child: DashboardRecentActivityCard()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isDark,
    bool isMobile,
    bool isAr,
    S s,
  ) {
    final now = DateTime.now();
    String formattedDate;
    try {
      formattedDate = DateFormat('d MMM yyyy', isAr ? 'ar' : 'en').format(now);
    } catch (_) {
      formattedDate = DateFormat('d MMM yyyy').format(now);
    }

    final controls = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.adminSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.adminBorder : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: isAr ? 'تحديث البيانات' : 'Refresh dashboard',
          child: Material(
            color: isDark ? AppColors.adminSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                ref.invalidate(dashboardStatsProvider);
                ref.invalidate(recentActivityProvider);
                ref.invalidate(incompleteProfilesProvider);
                ref.invalidate(pendingHandoffsProvider);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.adminBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.adminTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.clinicOverview,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.clinicOverviewSubtitle,
            style: TextStyle(
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          controls,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.clinicOverview,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.clinicOverviewSubtitle,
                style: TextStyle(
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        controls,
      ],
    );
  }

  Widget _buildQuickActionsStrip(BuildContext context, bool isDark, S s) {
    final actions = [
      (
        icon: Icons.person_add_alt_1_rounded,
        label: s.newPatient,
        color: AppColors.primary,
        route: '/admin/users',
      ),
      (
        icon: Icons.calendar_month_rounded,
        label: s.scheduleSession,
        color: AppColors.statusSuccess,
        route: '/admin/bookings',
      ),
      (
        icon: Icons.medical_services_rounded,
        label: s.addClinician,
        color: AppColors.statusInfo,
        route: '/admin/therapists',
      ),
      (
        icon: Icons.payments_rounded,
        label: s.sidebarBilling,
        color: AppColors.statusWarning,
        route: '/admin/payments',
      ),
      (
        icon: Icons.psychology_outlined,
        label: s.aiAnalytics,
        color: AppColors.statusPending,
        route: '/admin/ai-analytics',
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            _QuickPillAction(
              icon: actions[i].icon,
              label: actions[i].label,
              color: actions[i].color,
              isDark: isDark,
              onTap: () => context.go(actions[i].route),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickPillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickPillAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.adminSurface : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? AppColors.adminBorder : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.add_rounded,
                size: 14,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
