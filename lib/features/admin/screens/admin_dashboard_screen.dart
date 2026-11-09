import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../notifications/providers/notification_provider.dart';
import '../widgets/dashboard/weekly_agenda.dart';
import '../widgets/dashboard/risk_alerts_panel.dart';
import '../widgets/dashboard/crisis_alerts_panel.dart';
import '../widgets/handoff_queue_widget.dart';
import '../providers/admin_provider.dart';
import '../providers/activity_log_provider.dart';
import '../providers/signup_failures_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine if we are in dark mode (Roobin Mood)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S(ref.watch(languageProvider).language);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Text(
            s.clinicOverview,
            style:
                (isMobile
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.headlineMedium)
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.clinicOverviewSubtitle,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              // Notification Bell
              Consumer(
                builder: (context, ref, _) {
                  final unreadCount = ref.watch(
                    unreadNotificationCountProvider,
                  );
                  return IconButton(
                    onPressed: () => context.push('/notifications'),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          size: 28,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. KPI Cards Row
          _buildKpiRow(context, isDark, ref),
          const SizedBox(height: 24),

          // 1.5. Crisis Alerts Panel (above main content for visibility)
          SizedBox(
            height: isMobile ? 280 : 320,
            child: const CrisisAlertsPanel(),
          ),
          const SizedBox(height: 24),

          // 1.6. Handoff Queue (pending AI->therapist transfers)
          SizedBox(
            height: isMobile ? 240 : 280,
            child: const HandoffQueueWidget(),
          ),
          const SizedBox(height: 24),

          // 2. Main Dashboard Content (Agenda + Risk)
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive switch: Stack vertically on smaller screens
              if (constraints.maxWidth < 1000) {
                return Column(
                  children: [
                    SizedBox(
                      height: isMobile ? 380 : 500,
                      child: const WeeklyAgenda(),
                    ),
                    SizedBox(height: isMobile ? 16 : 24),
                    SizedBox(
                      height: isMobile ? 320 : 400,
                      child: const RiskAlertsPanel(),
                    ),
                  ],
                );
              } else {
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(height: 500, child: WeeklyAgenda()),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: SizedBox(height: 500, child: RiskAlertsPanel()),
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Incomplete profiles + signup health
          _buildIncompleteProfilesCard(context, ref, theme),

          const SizedBox(height: 24),

          // 3. Recent Activity Section
          _SectionCard(
            title: s.recentActivity,
            child: _buildRecentActivityList(ref, isDark),
          ),
        ],
      ),
    );
  }

  /// Surfaces users who signed up but never completed their profile, inline on
  /// the dashboard, with a count badge and a short preview. Taps through to the
  /// full Signup Health screen.
  Widget _buildIncompleteProfilesCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final async = ref.watch(incompleteProfilesProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              Icons.person_off_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Incomplete Profiles'),
            subtitle: async.when(
              loading: () => const Text('Loading…'),
              error: (e, _) => Text('Error: $e'),
              data: (list) => Text(
                list.isEmpty
                    ? 'Everyone has completed their profile.'
                    : '${list.length} user(s) signed up but never finished.',
              ),
            ),
            trailing: async.maybeWhen(
              data: (list) => list.isEmpty
                  ? const Icon(Icons.chevron_right)
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusDanger,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${list.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              orElse: () => const Icon(Icons.chevron_right),
            ),
            onTap: () => context.push('/admin/signup-health'),
          ),
          async.maybeWhen(
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const Divider(height: 1),
                      ...list
                          .take(5)
                          .map(
                            (u) => ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.account_circle_outlined,
                              ),
                              title: Text(
                                (u.displayName?.trim().isNotEmpty ?? false)
                                    ? u.displayName!
                                    : 'No name',
                              ),
                              subtitle: Text(
                                [
                                  if (u.platform != null) u.platform!,
                                  if (u.attemptedAt != null)
                                    _relativeTime(u.attemptedAt!),
                                ].join(' · '),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 18,
                              ),
                              onTap: () => context.push('/admin/signup-health'),
                            ),
                          ),
                      if (list.length > 5)
                        TextButton(
                          onPressed: () => context.push('/admin/signup-health'),
                          child: Text('View all ${list.length}'),
                        ),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'just now';
  }

  Widget _buildKpiRow(BuildContext context, bool isDark, WidgetRef ref) {
    final s = S(ref.watch(languageProvider).language);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(s.errorLoadingStats),
      data: (stats) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final isCompact = width < 600;

          final children = [
            _StatCard(
              title: s.activeUsers,
              value: _formatNumber(stats.activeUsers),
              trend: stats.usersTrend,
              trendUp: true,
              isDark: isDark,
              compact: isCompact,
            ),
            _StatCard(
              title: s.criticalFlags,
              value: stats.criticalFlags.toString(),
              trend: stats.criticalFlags > 0 ? s.needsAttention : s.allClear,
              trendUp: stats.criticalFlags == 0,
              isDanger: stats.criticalFlags > 0,
              isDark: isDark,
              compact: isCompact,
            ),
            _StatCard(
              title: s.todaysSessions,
              value: stats.sessionsToday.toString(),
              trend: '${stats.pendingSessions} ${s.pending}',
              trendUp: true,
              isDark: isDark,
              compact: isCompact,
            ),
            _StatCard(
              title: s.earnings,
              value: stats.formattedRevenue,
              trend: '${stats.premiumUsers} ${s.premium}',
              trendUp: true,
              isDark: isDark,
              compact: isCompact,
            ),
          ];

          if (width < 600) {
            // 2-column grid on mobile for compact stat cards
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

  Widget _buildRecentActivityList(WidgetRef ref, bool isDark) {
    final s = S(ref.watch(languageProvider).language);
    final activitiesAsync = ref.watch(recentActivityProvider);

    return activitiesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            s.failedToLoadActivity,
            style: TextStyle(
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 32,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.noRecentActivity,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.take(5).length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),
          itemBuilder: (context, index) {
            final activity = activities[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(activity.icon, size: 18, color: AppColors.primary),
              ),
              title: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: activity.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: ' ${activity.description}'),
                  ],
                ),
              ),
              subtitle: Text(
                activity.timeAgo,
                style: TextStyle(
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool trendUp;
  final bool isDanger;
  final bool isDark;
  final bool compact;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
    this.isDanger = false,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isDanger
        ? AppColors.statusDanger
        : (trendUp ? AppColors.primary : AppColors.statusDanger);

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              fontSize: compact ? 12 : 13,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                trendUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 13,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
