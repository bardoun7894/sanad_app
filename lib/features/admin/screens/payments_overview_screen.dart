import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/glass_card.dart';
import '../providers/admin_payments_provider.dart';
import '../providers/admin_invoices_provider.dart';

/// Top-level view toggle for the billing screen.
enum _BillingView { subscriptions, invoices }

class PaymentsOverviewScreen extends ConsumerStatefulWidget {
  const PaymentsOverviewScreen({super.key});

  @override
  ConsumerState<PaymentsOverviewScreen> createState() =>
      _PaymentsOverviewScreenState();
}

class _PaymentsOverviewScreenState extends ConsumerState<PaymentsOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Client marked the invoices/therapist-dues view as the primary one (✓) and
  // crossed out subscriptions (✗) — land on invoices by default.
  _BillingView _view = _BillingView.invoices;

  // Client-requested invoice search fields (client name / therapist name).
  final TextEditingController _clientSearchCtrl = TextEditingController();
  final TextEditingController _therapistSearchCtrl = TextEditingController();

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
    _clientSearchCtrl.dispose();
    _therapistSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () {
                    if (_view == _BillingView.subscriptions) {
                      ref.read(adminPaymentsProvider.notifier).refresh();
                    } else {
                      ref.read(adminInvoicesProvider.notifier).refresh();
                    }
                  },
                  icon: Icon(Icons.refresh, color: textColor),
                ),
              ],
            ),
          ),

          // View toggle (Subscriptions / Therapist Invoices & Payouts)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: _buildViewToggle(textColor),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _view == _BillingView.subscriptions
                ? _buildSubscriptionsView(textColor, hPadding)
                : _buildInvoicesView(textColor, hPadding),
          ),
        ],
      ),
    );
  }

  // ── View toggle ─────────────────────────────────────────────────────────
  Widget _buildViewToggle(Color textColor) {
    Widget segment(_BillingView v, String label, IconData icon) {
      final selected = _view == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _view = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : textColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? AppColors.primary
                      : textColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      color: selected
                          ? AppColors.primary
                          : textColor.withValues(alpha: 0.6),
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        segment(_BillingView.subscriptions, AppStrings.adminSubscriptions,
            Icons.subscriptions_outlined),
        const SizedBox(width: 12),
        segment(_BillingView.invoices, AppStrings.adminTherapistInvoices,
            Icons.receipt_long_outlined),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTIONS VIEW (from the `payments` collection)
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildSubscriptionsView(Color textColor, double hPadding) {
    final state = ref.watch(adminPaymentsProvider);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          child: _buildStatsRow(state.stats, textColor),
        ),
        const SizedBox(height: 24),
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
        Expanded(
          child: state.isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : state.error != null
                  ? _errorBox(state.error!, textColor,
                      () => ref.read(adminPaymentsProvider.notifier).refresh())
                  : state.filteredPayments.isEmpty
                      ? _emptyBox(Icons.payments_outlined,
                          AppStrings.adminNoPaymentsFound, textColor)
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
    );
  }

  Widget _buildStatsRow(PaymentStats stats, Color textColor) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final cards = [
          _buildStatCard(AppStrings.adminTotalRevenue,
              currencyFormat.format(stats.totalRevenue),
              Icons.account_balance_wallet, Colors.green, textColor),
          _buildStatCard(AppStrings.adminThisMonth,
              currencyFormat.format(stats.monthlyRevenue),
              Icons.calendar_month, Colors.blue, textColor),
          _buildStatCard(AppStrings.adminThisWeek,
              currencyFormat.format(stats.weeklyRevenue),
              Icons.date_range, Colors.purple, textColor),
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
                    child: Icon(_methodIcon(payment.paymentMethod),
                        color: AppColors.primary, size: 24),
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
                              'User: ${payment.userId.length >= 8 ? payment.userId.substring(0, 8) : payment.userId}...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                        if (isMobile) ...[
                          const SizedBox(height: 8),
                          _buildStatusChip(
                              statusColor, statusIcon, payment.status),
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
                        Icon(Icons.schedule,
                            size: 14, color: textColor.withValues(alpha: 0.5)),
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
                    Icon(Icons.schedule,
                        size: 14, color: textColor.withValues(alpha: 0.5)),
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
              // Actions — wired to Firestore status transitions.
              // NOTE: Firestore status only — real PayPal/Freemius gateway
              // refund/capture is a follow-up task.
              if (payment.status == 'pending' ||
                  payment.status == 'completed') ...[
                const SizedBox(height: 16),
                Divider(color: textColor.withValues(alpha: 0.1)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (payment.status == 'pending') ...[
                      TextButton(
                        onPressed: () => _confirmAndUpdate(
                          payment.id,
                          'failed',
                          AppStrings.adminConfirmReject,
                        ),
                        child: Text(
                          AppStrings.adminReject,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _confirmAndUpdate(
                          payment.id,
                          'completed',
                          AppStrings.adminConfirmApprove,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(AppStrings.adminApprove),
                      ),
                    ],
                    if (payment.status == 'completed')
                      OutlinedButton.icon(
                        onPressed: () => _confirmAndUpdate(
                          payment.id,
                          'refunded',
                          AppStrings.adminConfirmRefund,
                        ),
                        icon: Icon(Icons.replay,
                            size: 16, color: textColor.withValues(alpha: 0.7)),
                        label: Text(AppStrings.adminRefund),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor.withValues(alpha: 0.7),
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

  Future<void> _confirmAndUpdate(
    String paymentId,
    String newStatus,
    String message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(adminPaymentsProvider.notifier)
          .updatePaymentStatus(paymentId, newStatus);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // THERAPIST INVOICES & PAYOUTS VIEW (from the `bookings` collection)
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildInvoicesView(Color textColor, double hPadding) {
    final state = ref.watch(adminInvoicesProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Column(
      children: [
        // Date-range controls
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          child: _buildRangeControls(state, textColor),
        ),
        const SizedBox(height: 12),
        // Search by client name / therapist name
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          child: _buildInvoiceSearch(textColor),
        ),
        const SizedBox(height: 16),
        // Range summary cards
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          child: _buildInvoiceSummary(state, currencyFormat, textColor),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: state.isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : state.error != null
                  ? _errorBox(state.error!, textColor,
                      () => ref.read(adminInvoicesProvider.notifier).refresh())
                  : state.invoices.isEmpty
                      ? _emptyBox(
                          Icons.receipt_long_outlined,
                          (state.clientQuery.isNotEmpty ||
                                  state.therapistQuery.isNotEmpty)
                              ? AppStrings.adminNoMatchingInvoices
                              : AppStrings.adminNoInvoicesFound,
                          textColor)
                      : ListView(
                          padding: EdgeInsets.symmetric(horizontal: hPadding),
                          children: [
                            // Per-therapist payout summary
                            if (state.payouts.isNotEmpty) ...[
                              Text(
                                AppStrings.adminPayoutSummary,
                                style: AppTypography.labelLarge.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              for (final p in state.payouts)
                                _buildPayoutCard(p, currencyFormat, textColor),
                              const SizedBox(height: 20),
                              Divider(color: textColor.withValues(alpha: 0.1)),
                              const SizedBox(height: 12),
                            ],
                            // Invoice list
                            Text(
                              AppStrings.adminTherapistInvoices,
                              style: AppTypography.labelLarge.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInvoiceList(state, currencyFormat, textColor),
                          ],
                        ),
        ),
      ],
    );
  }

  Widget _buildRangeControls(AdminInvoicesState state, Color textColor) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final notifier = ref.read(adminInvoicesProvider.notifier);
    final hasRange = state.from != null || state.to != null;
    final rangeLabel = hasRange
        ? '${state.from != null ? dateFormat.format(state.from!) : '…'}  —  ${state.to != null ? dateFormat.format(state.to!) : '…'}'
        : AppStrings.adminPickDateRange;

    Widget chip(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : textColor.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: selected ? AppColors.primary : textColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip(AppStrings.adminAll, !hasRange, notifier.clearRange),
            chip(AppStrings.adminThisWeek, false, notifier.setThisWeek),
            chip(AppStrings.adminThisMonth, false, notifier.setThisMonth),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2023),
              lastDate: DateTime(now.year + 1, 12, 31),
              initialDateRange: state.from != null && state.to != null
                  ? DateTimeRange(start: state.from!, end: state.to!)
                  : null,
            );
            if (picked != null) {
              // Make the end-date inclusive through end of day.
              notifier.setRange(
                picked.start,
                DateTime(picked.end.year, picked.end.month, picked.end.day,
                    23, 59, 59),
              );
            }
          },
          icon: const Icon(Icons.date_range, size: 18),
          label: Text(rangeLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor,
            side: BorderSide(color: textColor.withValues(alpha: 0.2)),
          ),
        ),
      ],
    );
  }

  // ── Invoice search (client name / therapist name) ─────────────────────────
  Widget _buildInvoiceSearch(Color textColor) {
    Widget field(
      TextEditingController ctrl,
      String hint,
      ValueChanged<String> onChanged,
    ) {
      OutlineInputBorder border(Color c) => OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c),
          );
      return TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: AppTypography.bodyMedium.copyWith(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMedium
              .copyWith(color: textColor.withValues(alpha: 0.4)),
          prefixIcon: Icon(Icons.search,
              size: 18, color: textColor.withValues(alpha: 0.5)),
          suffixIcon: ctrl.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.clear,
                      size: 16, color: textColor.withValues(alpha: 0.5)),
                  onPressed: () {
                    ctrl.clear();
                    onChanged('');
                  },
                ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: textColor.withValues(alpha: 0.04),
          border: border(textColor.withValues(alpha: 0.15)),
          enabledBorder: border(textColor.withValues(alpha: 0.15)),
          focusedBorder: border(AppColors.primary),
        ),
      );
    }

    final notifier = ref.read(adminInvoicesProvider.notifier);
    final clientField = field(_clientSearchCtrl,
        AppStrings.adminSearchByClientName, notifier.setClientQuery);
    final therapistField = field(_therapistSearchCtrl,
        AppStrings.adminSearchByTherapistName, notifier.setTherapistQuery);

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 768;
      if (isMobile) {
        return Column(
          children: [
            clientField,
            const SizedBox(height: 8),
            therapistField,
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: clientField),
          const SizedBox(width: 12),
          Expanded(child: therapistField),
        ],
      );
    });
  }

  // ── Invoice list: spreadsheet-style table on desktop, cards on mobile ──────
  Widget _buildInvoiceList(
    AdminInvoicesState state,
    NumberFormat fmt,
    Color textColor,
  ) {
    if (AdminResponsive.isMobile(context)) {
      return Column(
        children: [
          for (final inv in state.invoices)
            _buildInvoiceCard(inv, fmt, textColor),
        ],
      );
    }
    return _buildInvoiceTable(state.invoices, fmt, textColor);
  }

  Widget _buildInvoiceTable(
    List<InvoiceRecord> invoices,
    NumberFormat fmt,
    Color textColor,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final headerStyle = AppTypography.caption
        .copyWith(color: textColor, fontWeight: FontWeight.bold);
    final cellStyle = AppTypography.caption.copyWith(color: textColor);

    DataColumn col(String label, {Color? color}) => DataColumn(
          label: Text(
            label,
            style: color == null ? headerStyle : headerStyle.copyWith(color: color),
          ),
        );

    DataCell moneyCell(double v, Color color) => DataCell(
          Text(
            fmt.format(v),
            style: cellStyle.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        );

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 52,
            columnSpacing: 28,
            columns: [
              col(AppStrings.adminClientLabel),
              col(AppStrings.adminColSubscriptionDate),
              col(AppStrings.adminColAssignedTherapist),
              col(AppStrings.adminColTotalValue),
              col(AppStrings.adminTherapistShare, color: Colors.green),
              col(AppStrings.adminMaintenanceShare, color: Colors.orange),
              col(AppStrings.adminAppCut, color: Colors.blue),
            ],
            rows: [
              for (final inv in invoices)
                DataRow(cells: [
                  DataCell(Text(
                    inv.clientName.isEmpty ? '—' : inv.clientName,
                    style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                  )),
                  DataCell(Text(dateFormat.format(inv.date), style: cellStyle)),
                  DataCell(Text(
                    inv.therapistName.isEmpty ? '—' : inv.therapistName,
                    style: cellStyle,
                  )),
                  moneyCell(inv.amount, textColor),
                  moneyCell(inv.shares.therapist, Colors.green),
                  moneyCell(inv.shares.maintenance, Colors.orange),
                  moneyCell(inv.shares.app, Colors.blue),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceSummary(
    AdminInvoicesState state,
    NumberFormat fmt,
    Color textColor,
  ) {
    final cards = [
      _buildStatCard(AppStrings.adminTotalRevenue,
          fmt.format(state.totalGross), Icons.account_balance_wallet,
          Colors.green, textColor),
      _buildStatCard(AppStrings.adminTherapistDues,
          fmt.format(state.totalTherapist), Icons.medical_services_outlined,
          AppColors.primary, textColor),
      _buildStatCard(AppStrings.adminAppCut, fmt.format(state.totalApp),
          Icons.apps, Colors.blue, textColor),
      _buildStatCard(AppStrings.adminMaintenanceShare,
          fmt.format(state.totalMaintenance), Icons.build_outlined,
          Colors.orange, textColor),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 768;
      if (isMobile) {
        return Column(
          children: [
            Row(children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ]),
          ],
        );
      }
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i != cards.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    });
  }

  Widget _buildPayoutCard(
    TherapistPayout p,
    NumberFormat fmt,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_services_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.therapistName.isEmpty ? '—' : p.therapistName,
                      style: AppTypography.labelLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${p.sessions} ${AppStrings.adminSessionsCount}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _kv(AppStrings.adminGross, fmt.format(p.gross), textColor,
                  bold: true),
              _kv(AppStrings.adminTherapistShare, fmt.format(p.therapistDue),
                  textColor,
                  valueColor: Colors.green),
              _kv(AppStrings.adminAppCut, fmt.format(p.appCut), textColor),
              _kv(AppStrings.adminMaintenanceShare, fmt.format(p.maintenance),
                  textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(
    InvoiceRecord inv,
    NumberFormat fmt,
    Color textColor,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.adminClientLabel}: ${inv.clientName.isEmpty ? '—' : inv.clientName}',
                          style: AppTypography.labelLarge.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppStrings.adminTherapistLabel}: ${inv.therapistName.isEmpty ? '—' : inv.therapistName}',
                          style: AppTypography.caption.copyWith(
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    fmt.format(inv.amount),
                    style: AppTypography.labelLarge.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule,
                      size: 13, color: textColor.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(inv.date),
                    style: AppTypography.caption.copyWith(
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatPaymentMethod(inv.paymentMethod),
                    style: AppTypography.caption.copyWith(
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: textColor.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              // Split breakdown
              Row(
                children: [
                  Expanded(
                    child: _splitChip(AppStrings.adminTherapistShare,
                        fmt.format(inv.shares.therapist), Colors.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _splitChip(AppStrings.adminAppCut,
                        fmt.format(inv.shares.app), Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _splitChip(AppStrings.adminMaintenanceShare,
                        fmt.format(inv.shares.maintenance), Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _splitChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value, Color textColor,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: AppTypography.caption.copyWith(
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: valueColor ?? textColor,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _errorBox(String error, Color textColor, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Error: $error', style: TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: onRetry, child: Text(AppStrings.confirm)),
        ],
      ),
    );
  }

  Widget _emptyBox(IconData icon, String message, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: textColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.bodyLarge.copyWith(
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
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

  IconData _methodIcon(String method) {
    switch (method) {
      case 'card':
        return Icons.credit_card;
      case 'google_pay':
        return Icons.g_mobiledata_rounded;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'paypal':
        return Icons.account_balance_wallet;
      default:
        return Icons.payments;
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'card':
        return 'Credit/Debit Card';
      case 'google_pay':
        return 'Google Pay';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'paypal':
        return 'PayPal';
      case 'admin_grant':
        return 'Admin Grant';
      default:
        return method.isEmpty ? '—' : method;
    }
  }
}
