import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../crisis/models/crisis_alert.dart';
import '../../../crisis/providers/crisis_alerts_provider.dart';
import '../../../crisis/widgets/crisis_alert_card.dart';
import '../../../crisis/widgets/crisis_alert_action_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Dashboard panel that shows active crisis alerts alongside mood risk alerts.
/// Crisis alerts are shown first with a pulsing red indicator.
class CrisisAlertsPanel extends ConsumerWidget {
  const CrisisAlertsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S(ref.watch(languageProvider).language);
    final crisisAlertsAsync = ref.watch(activeCrisisAlertsProvider);

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
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.crisis_alert_rounded,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.crisisAlerts,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    crisisAlertsAsync.when(
                      data: (alerts) {
                        if (alerts.isEmpty) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${alerts.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
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
                  onPressed: () => context.push('/admin/crisis-alerts'),
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

          // Crisis alerts list
          Expanded(
            child: crisisAlertsAsync.when(
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
                            s.crisisNoActiveAlerts,
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
                  padding: const EdgeInsets.all(12),
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return CrisisAlertCard(
                      alert: alert,
                      onTap: () => _showActionSheet(context, alert),
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

  void _showActionSheet(BuildContext context, CrisisAlert alert) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          CrisisAlertActionSheet(alert: alert, currentAdminId: currentUserId),
    );
  }
}
