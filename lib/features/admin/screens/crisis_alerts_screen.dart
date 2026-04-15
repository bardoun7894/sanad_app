import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../crisis/models/crisis_alert.dart';
import '../../crisis/providers/crisis_alerts_provider.dart';
import '../../crisis/widgets/crisis_alert_card.dart';
import '../../crisis/widgets/crisis_alert_action_sheet.dart';

class CrisisAlertsScreen extends ConsumerStatefulWidget {
  const CrisisAlertsScreen({super.key});

  @override
  ConsumerState<CrisisAlertsScreen> createState() => _CrisisAlertsScreenState();
}

class _CrisisAlertsScreenState extends ConsumerState<CrisisAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.crisisAlertsTitle),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.crisisActiveAlerts),
            Tab(text: s.crisisAllAlerts),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AlertsTab(
            alertsProvider: activeCrisisAlertsProvider,
            emptyMessage: s.crisisNoActiveAlerts,
          ),
          _AlertsTab(
            alertsProvider: allCrisisAlertsProvider,
            emptyMessage: s.crisisNoAlerts,
          ),
        ],
      ),
    );
  }
}

class _AlertsTab extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<CrisisAlert>>> alertsProvider;
  final String emptyMessage;

  const _AlertsTab({required this.alertsProvider, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return alertsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Error loading alerts: $error',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ),
      data: (alerts) {
        if (alerts.isEmpty) {
          return Center(
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
                  emptyMessage,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
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
