import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/risk_alerts_provider.dart';

enum RiskLevel { low, moderate, high, critical }

class RiskAlert {
  final String patientId;
  final String patientName;
  final RiskLevel level;
  final int daysCount;
  final DateTime lastUpdated;

  RiskAlert({
    required this.patientId,
    required this.patientName,
    required this.level,
    required this.daysCount,
    required this.lastUpdated,
  });
}

class RiskAlertsPanel extends ConsumerWidget {
  const RiskAlertsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S(ref.watch(languageProvider).language);
    final alertsAsync = ref.watch(riskAlertsProvider);

    return Container(
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.statusDanger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: AppColors.statusDanger,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.riskAlerts,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    alertsAsync.when(
                      data: (alerts) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusDanger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${alerts.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusDanger,
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    s.viewAll,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),

          // Alerts list
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    s.failedToLoadAlerts,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 48,
                            color: AppColors.statusSuccess,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.noHighRiskAlerts,
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
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return _RiskAlertItem(
                      alert: alert,
                      strings: s,
                      isDark: isDark,
                      onTap: () {
                        context.go('/admin/users/${alert.patientId}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskAlertItem extends StatelessWidget {
  final RiskAlert alert;
  final S strings;
  final bool isDark;
  final VoidCallback onTap;

  const _RiskAlertItem({
    required this.alert,
    required this.strings,
    required this.isDark,
    required this.onTap,
  });

  Color get _levelColor {
    switch (alert.level) {
      case RiskLevel.low:
        return AppColors.riskLow;
      case RiskLevel.moderate:
        return AppColors.riskModerate;
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.critical:
        return AppColors.riskCritical;
    }
  }

  String get _levelLabel {
    switch (alert.level) {
      case RiskLevel.low:
        return strings.riskLow;
      case RiskLevel.moderate:
        return strings.riskModerate;
      case RiskLevel.high:
        return strings.riskHigh;
      case RiskLevel.critical:
        return strings.riskCritical;
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(alert.lastUpdated);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}${strings.minutesAgo}';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}${strings.hoursAgo}';
    } else {
      return '${diff.inDays}${strings.daysAgo}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _levelColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: _levelColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              // Risk level indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _levelColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.patientName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _levelColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _levelLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _levelColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${strings.moodDecliningFor} ${alert.daysCount} ${strings.days}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.adminTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          _timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.adminTextSecondary.withValues(
                                    alpha: 0.7,
                                  )
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Risk badge widget for use in tables and lists
class RiskBadge extends ConsumerWidget {
  final RiskLevel level;

  const RiskBadge({super.key, required this.level});

  Color get _color {
    switch (level) {
      case RiskLevel.low:
        return AppColors.riskLow;
      case RiskLevel.moderate:
        return AppColors.riskModerate;
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.critical:
        return AppColors.riskCritical;
    }
  }

  String _label(S strings) {
    switch (level) {
      case RiskLevel.low:
        return strings.riskLow;
      case RiskLevel.moderate:
        return strings.riskModerate;
      case RiskLevel.high:
        return strings.riskHigh;
      case RiskLevel.critical:
        return strings.riskCritical;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S(ref.watch(languageProvider).language);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _label(strings),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
