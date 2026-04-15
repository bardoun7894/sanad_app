import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/admin_payments_provider.dart';

class PaymentsOverviewScreen extends ConsumerStatefulWidget {
  const PaymentsOverviewScreen({super.key});

  @override
  ConsumerState<PaymentsOverviewScreen> createState() =>
      _PaymentsOverviewScreenState();
}

class _PaymentsOverviewScreenState extends ConsumerState<PaymentsOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      final notifier = ref.read(adminPaymentsProvider.notifier);
      switch (_tabController.index) {
        case 0:
          notifier.setStatusFilter(null);
          break;
        case 1:
          notifier.setStatusFilter('completed');
          break;
        case 2:
          notifier.setStatusFilter('pending');
          break;
        case 3:
          notifier.setStatusFilter('failed');
          break;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPaymentsProvider);
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final isMobile = AdminResponsive.isMobile(context);
    final hPadding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(hPadding, hPadding, hPadding, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.adminPaymentsOverview,
                    style: AppTypography.headingMedium.copyWith(
                      color: textColor,
                      fontSize: isMobile ? 22 : null,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(adminPaymentsProvider.notifier).refresh(),
                  icon: Icon(Icons.refresh, color: textColor),
                ),
              ],
            ),
          ),

          // Stats Cards
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: _buildStatsRow(state.stats, textColor),
          ),

          const SizedBox(height: 24),

          // Tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: textColor.withValues(alpha: 0.5),
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'All (${state.stats.totalPayments})'),
                  Tab(text: 'Completed (${state.stats.completedPayments})'),
                  Tab(text: 'Pending (${state.stats.pendingPayments})'),
                  Tab(text: 'Failed (${state.stats.failedPayments})'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: state.isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.error}',
                          style: TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(adminPaymentsProvider.notifier)
                              .refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : state.filteredPayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 64,
                          color: textColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.adminNoPaymentsFound,
                          style: AppTypography.bodyLarge.copyWith(
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: hPadding),
                    itemCount: state.filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = state.filteredPayments[index];
                      return _buildPaymentCard(payment, textColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(PaymentStats stats, Color textColor) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final cards = [
          _buildStatCard(
            'Total Revenue',
            currencyFormat.format(stats.totalRevenue),
            Icons.account_balance_wallet,
            Colors.green,
            textColor,
          ),
          _buildStatCard(
            'This Month',
            currencyFormat.format(stats.monthlyRevenue),
            Icons.calendar_month,
            Colors.blue,
            textColor,
          ),
          _buildStatCard(
            'This Week',
            currencyFormat.format(stats.weeklyRevenue),
            Icons.date_range,
            Colors.purple,
            textColor,
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTypography.headingSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentRecord payment, Color textColor) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isMobile = AdminResponsive.isMobile(context);

    Color statusColor;
    IconData statusIcon;
    switch (payment.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'refunded':
        statusColor = Colors.blue;
        statusIcon = Icons.replay;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    IconData methodIcon;
    switch (payment.paymentMethod) {
      case 'card':
        methodIcon = Icons.credit_card;
        break;
      case 'google_pay':
        methodIcon = Icons.g_mobiledata_rounded;
        break;
      case 'bank_transfer':
        methodIcon = Icons.account_balance;
        break;
      default:
        methodIcon = Icons.payments;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(methodIcon, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormat.format(payment.amount),
                          style: AppTypography.labelLarge.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          payment.userEmail ??
                              'User: ${payment.userId.substring(0, 8)}...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                        if (isMobile) ...[
                          const SizedBox(height: 8),
                          _buildStatusChip(
                            statusColor,
                            statusIcon,
                            payment.status,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isMobile)
                    _buildStatusChip(statusColor, statusIcon, payment.status),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: textColor.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              // Details row
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateFormat.format(payment.createdAt),
                            style: AppTypography.caption.copyWith(
                              color: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPaymentMethod(payment.paymentMethod),
                      style: AppTypography.caption.copyWith(
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(payment.createdAt),
                      style: AppTypography.caption.copyWith(
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatPaymentMethod(payment.paymentMethod),
                      style: AppTypography.caption.copyWith(
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              if (payment.referenceCode != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Ref: ${payment.referenceCode}',
                  style: AppTypography.caption.copyWith(
                    color: textColor.withValues(alpha: 0.4),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              // Actions (disabled — coming soon)
              if (payment.status == 'pending' ||
                  payment.status == 'completed') ...[
                const SizedBox(height: 16),
                Divider(color: textColor.withValues(alpha: 0.1)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (payment.status == 'pending') ...[
                      Tooltip(
                        message: AppStrings.adminFeatureComingSoon,
                        child: TextButton(
                          onPressed: null,
                          child: Text(
                            AppStrings.adminReject,
                            style: TextStyle(color: Colors.red.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: AppStrings.adminFeatureComingSoon,
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.green.withValues(alpha: 0.3),
                            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                          ),
                          child: Text(AppStrings.adminApprove),
                        ),
                      ),
                    ],
                    if (payment.status == 'completed')
                      Tooltip(
                        message: AppStrings.adminFeatureComingSoon,
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: Icon(Icons.replay, size: 16, color: textColor.withValues(alpha: 0.3)),
                          label: Text(AppStrings.adminRefund),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStatusChip(
    Color statusColor,
    IconData statusIcon,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'card':
        return 'Credit/Debit Card';
      case 'google_pay':
        return 'Google Pay';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return method;
    }
  }
}
