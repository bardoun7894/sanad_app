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
import '../utils/invoices_csv.dart';
// ignore: uri_does_not_exist
import '../utils/csv_download_web.dart'
    // ignore: avoid_web_libraries_in_flutter
    if (dart.library.io) '../utils/csv_download_stub.dart';

/// Set to [true] to show both the Subscriptions tab and the Invoices tab.
/// Set to [false] to hide the Subscriptions toggle and show only Invoices.
const bool _showSubscriptionsTab = true;

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
  // When _showSubscriptionsTab is false, the toggle is hidden and we always
  // show the invoices view.
  _BillingView _view = _BillingView.invoices;

  // Client-requested invoice search fields (client name / therapist name).
  final TextEditingController _clientSearchCtrl = TextEditingController();
  final TextEditingController _therapistSearchCtrl = TextEditingController();

  // Subscriptions view search (user name / email).
  final TextEditingController _subsSearchCtrl = TextEditingController();

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
    _subsSearchCtrl.dispose();
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
                  tooltip: 'تحديث',
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

          // View toggle — hidden when _showSubscriptionsTab == false.
          // The underlying code for the subscriptions view is preserved;
          // flip _showSubscriptionsTab to true to restore the toggle.
          if (_showSubscriptionsTab) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: _buildViewToggle(textColor),
            ),
            const SizedBox(height: 16),
          ],

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
    final isMobile = AdminResponsive.isMobile(context);

    // Mobile: keep the original ListView-based scrolling approach.
    if (isMobile) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: _buildStatsRow(state.stats, textColor),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: _buildSubsSearchBox(textColor),
          ),
          const SizedBox(height: 12),
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
                  Tab(text: '${AppStrings.adminTabAll} (${state.stats.totalPayments})'),
                  Tab(text: '${AppStrings.adminTabCompleted} (${state.stats.completedPayments})'),
                  Tab(text: '${AppStrings.adminTabPending} (${state.stats.pendingPayments})'),
                  Tab(text: '${AppStrings.adminTabFailed} (${state.stats.failedPayments})'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
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

    // Desktop: single vertical-scrollable page so the full DataTable is
    // reachable. The DataTable renders at natural height inside the scroll
    // view, and each individual table already has a horizontal
    // SingleChildScrollView for wide columns.
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: hPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: _buildStatsRow(state.stats, textColor),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: _buildSubsSearchBox(textColor),
          ),
          const SizedBox(height: 10),
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
                  Tab(text: '${AppStrings.adminTabAll} (${state.stats.totalPayments})'),
                  Tab(text: '${AppStrings.adminTabCompleted} (${state.stats.completedPayments})'),
                  Tab(text: '${AppStrings.adminTabPending} (${state.stats.pendingPayments})'),
                  Tab(text: '${AppStrings.adminTabFailed} (${state.stats.failedPayments})'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: _errorBox(state.error!, textColor,
                  () => ref.read(adminPaymentsProvider.notifier).refresh()),
            )
          else if (state.filteredPayments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: _emptyBox(Icons.payments_outlined,
                  AppStrings.adminNoPaymentsFound, textColor),
            )
          else
            _buildSubscriptionsTable(
                state.filteredPayments, textColor, hPadding),
        ],
      ),
    );
  }

  /// Search box for the subscriptions view (by name or email).
  Widget _buildSubsSearchBox(Color textColor) {
    OutlineInputBorder border(Color c, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: width),
        );
    return TextField(
      controller: _subsSearchCtrl,
      onChanged: (q) {
        ref.read(adminPaymentsProvider.notifier).setNameQuery(q);
        setState(() {});
      },
      style: AppTypography.bodyMedium.copyWith(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: AppStrings.adminSearchSubscriptions,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: textColor.withValues(alpha: 0.35),
          fontSize: 14,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.person_search_outlined,
              size: 17, color: textColor.withValues(alpha: 0.45)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIcon: _subsSearchCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.cancel_rounded,
                    size: 16, color: textColor.withValues(alpha: 0.4)),
                onPressed: () {
                  _subsSearchCtrl.clear();
                  ref.read(adminPaymentsProvider.notifier).setNameQuery('');
                  setState(() {});
                },
              ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        filled: true,
        fillColor: textColor.withValues(alpha: 0.04),
        border: border(textColor.withValues(alpha: 0.15)),
        enabledBorder: border(textColor.withValues(alpha: 0.15)),
        focusedBorder: border(AppColors.primary, width: 1.5),
      ),
    );
  }

  /// Desktop DataTable for the subscriptions view.
  Widget _buildSubscriptionsTable(
    List<PaymentRecord> payments,
    Color textColor,
    double hPadding,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final headerStyle = AppTypography.caption.copyWith(
      color: textColor.withValues(alpha: 0.55),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      fontSize: 11,
    );
    final cellStyle = AppTypography.caption.copyWith(
      color: textColor,
      fontSize: 13,
    );

    DataColumn col(String label, {Color? color}) => DataColumn(
          label: Text(
            label,
            style: color == null
                ? headerStyle
                : headerStyle.copyWith(color: color.withValues(alpha: 0.8)),
          ),
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      child: GlassCard(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // LayoutBuilder outside the horizontal scroll view so that
          // constraints.maxWidth is the GlassCard's bounded width (not ∞).
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowHeight: 42,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  columnSpacing: 28,
                  dividerThickness: 0.5,
                  headingRowColor: WidgetStateProperty.all(
                    textColor.withValues(alpha: 0.04),
                  ),
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return AppColors.primary.withValues(alpha: 0.06);
                    }
                    return Colors.transparent;
                  }),
                  columns: [
                    col(AppStrings.adminColUser),   // العميل
                    col(AppStrings.adminColMethod), // طريقة الدفع
                    col(AppStrings.adminColAmount), // المبلغ
                    col(AppStrings.adminColStatus), // الحالة
                    col(AppStrings.adminColDate),   // التاريخ
                  ],
                  rows: [
                    for (int i = 0; i < payments.length; i++)
                      DataRow(
                        color: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return AppColors.primary.withValues(alpha: 0.06);
                          }
                          return i.isOdd
                              ? textColor.withValues(alpha: 0.025)
                              : Colors.transparent;
                        }),
                        cells: [
                          DataCell(_subsUserCell(payments[i], cellStyle, textColor)),
                          DataCell(Text(
                            _formatPaymentMethod(payments[i].paymentMethod),
                            style: cellStyle,
                          )),
                          DataCell(Text(
                            currencyFormat.format(payments[i].amount),
                            style: cellStyle.copyWith(fontWeight: FontWeight.w700),
                          )),
                          DataCell(_buildStatusChip(
                            _statusColor(payments[i].status),
                            _statusIcon(payments[i].status),
                            _statusLabel(payments[i].status),
                          )),
                          DataCell(Text(
                            dateFormat.format(payments[i].createdAt),
                            style: cellStyle.copyWith(
                              color: textColor.withValues(alpha: 0.75),
                            ),
                          )),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _subsUserCell(PaymentRecord p, TextStyle cellStyle, Color textColor) {
    final name = p.userName?.trim();
    final hasName = name != null && name.isNotEmpty;
    final email = p.userEmail?.trim();
    final hasEmail = email != null && email.isNotEmpty;
    final primary = hasName
        ? name
        : (hasEmail ? email : _shortId(p.userId));
    final secondary = hasName ? (hasEmail ? email : null) : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(primary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: cellStyle.copyWith(fontWeight: FontWeight.w600)),
        if (secondary != null)
          Text(secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle.copyWith(
                color: textColor.withValues(alpha: 0.55),
                fontSize: 11,
              )),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.cancel;
      case 'refunded':
        return Icons.replay;
      default:
        return Icons.help;
    }
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
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            // Colored left/start accent strip (RTL-aware would be right, but
            // left looks correct visually in the admin shell).
            left: BorderSide(color: color, width: 3),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            bottomLeft: Radius.circular(3),
          ),
        ),
        child: Padding(
          // Compact vertical padding on desktop so the stat row takes
          // less height, leaving more room for the data tables below.
          padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.caption.copyWith(
                        color: textColor.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTypography.headingSmall.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentRecord payment, Color textColor) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final statusColor = _statusColor(payment.status);
    final statusIcon = _statusIcon(payment.status);

    // Identity: real name (joined from users) → email → short uid.
    final name = payment.userName?.trim();
    final hasName = name != null && name.isNotEmpty;
    final email = payment.userEmail?.trim();
    final hasEmail = email != null && email.isNotEmpty;
    final primary = hasName
        ? name
        : (hasEmail
            ? email
            : '${AppStrings.adminPaymentUserIdLabel}: ${_shortId(payment.userId)}');
    final secondary = hasName
        ? (hasEmail ? email : _shortId(payment.userId))
        : (hasEmail ? _shortId(payment.userId) : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: method icon · name + secondary · amount + status
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
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 13,
                                color: textColor.withValues(alpha: 0.45)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                primary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelLarge.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (secondary != null) ...[
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(right: 17),
                            child: Text(
                              secondary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: textColor.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(payment.amount),
                        style: AppTypography.headingSmall.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildStatusChip(statusColor, statusIcon,
                          _statusLabel(payment.status)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: textColor.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              // Detail rows — only show fields that carry a value.
              _paymentDetailRow(
                  Icons.account_balance_wallet_outlined,
                  AppStrings.adminPaymentMethodLabel,
                  _formatPaymentMethod(payment.paymentMethod),
                  textColor),
              _paymentDetailRow(Icons.schedule, AppStrings.adminPaymentDateLabel,
                  dateFormat.format(payment.createdAt), textColor),
              _paymentDetailRow(Icons.tag, AppStrings.adminPaymentUserIdLabel,
                  _shortId(payment.userId), textColor,
                  mono: true),
              if (payment.referenceCode != null &&
                  payment.referenceCode!.isNotEmpty)
                _paymentDetailRow(
                    Icons.confirmation_number_outlined,
                    AppStrings.adminPaymentReferenceLabel,
                    payment.referenceCode!,
                    textColor,
                    mono: true),
              if (payment.gatewayTransactionId != null &&
                  payment.gatewayTransactionId!.isNotEmpty)
                _paymentDetailRow(
                    Icons.receipt_outlined,
                    AppStrings.adminPaymentTxnLabel,
                    payment.gatewayTransactionId!,
                    textColor,
                    mono: true),
              // Actions — wired to Firestore status transitions.
              // NOTE: Firestore status only — real PayPal/Freemius gateway
              // refund/capture is a follow-up task.
              if (payment.status == 'pending' ||
                  payment.status == 'completed') ...[
                const SizedBox(height: 12),
                Divider(color: textColor.withValues(alpha: 0.1)),
                const SizedBox(height: 4),
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

  String _shortId(String id) =>
      id.length <= 10 ? id : '${id.substring(0, 10)}…';

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return AppStrings.adminStatusCompleted;
      case 'pending':
        return AppStrings.adminStatusPending;
      case 'failed':
        return AppStrings.adminStatusFailed;
      case 'refunded':
        return AppStrings.adminStatusRefunded;
      default:
        return status;
    }
  }

  Widget _paymentDetailRow(
    IconData icon,
    String label,
    String value,
    Color textColor, {
    bool mono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor.withValues(alpha: 0.4)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: textColor.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
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
    final isMobile = AdminResponsive.isMobile(context);

    // Shared header widgets (controls + search + summary cards) — same on all
    // viewports; only the table area changes between mobile/desktop.
    Widget header() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date-range controls + export button row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: _buildRangeControlsWithExport(state, textColor),
            ),
            const SizedBox(height: 10),
            // Search by client name / therapist name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: _buildInvoiceSearch(textColor),
            ),
            const SizedBox(height: 12),
            // Range summary cards — reduced vertical gap vs old 16px
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              child: _buildInvoiceSummary(state, currencyFormat, textColor),
            ),
            const SizedBox(height: 14),
          ],
        );

    if (state.isLoading) {
      return Column(
        children: [
          header(),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (state.error != null) {
      return Column(
        children: [
          header(),
          Expanded(
            child: _errorBox(state.error!, textColor,
                () => ref.read(adminInvoicesProvider.notifier).refresh()),
          ),
        ],
      );
    }

    if (state.invoices.isEmpty) {
      return Column(
        children: [
          header(),
          Expanded(
            child: _emptyBox(
              Icons.receipt_long_outlined,
              (state.clientQuery.isNotEmpty || state.therapistQuery.isNotEmpty)
                  ? AppStrings.adminNoMatchingInvoices
                  : AppStrings.adminNoInvoicesFound,
              textColor,
            ),
          ),
        ],
      );
    }

    // Mobile: keep the original ListView-based scrolling so cards scroll
    // correctly on narrow screens.
    if (isMobile) {
      return ListView(
        padding: EdgeInsets.only(
          left: hPadding,
          right: hPadding,
          bottom: hPadding,
        ),
        children: [
          // Controls + search + summary (inlined so they scroll with the list)
          _buildRangeControlsWithExport(state, textColor),
          const SizedBox(height: 10),
          _buildInvoiceSearch(textColor),
          const SizedBox(height: 12),
          _buildInvoiceSummary(state, currencyFormat, textColor),
          const SizedBox(height: 14),
          // Per-therapist payout cards
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
          Text(
            AppStrings.adminTherapistInvoices,
            style: AppTypography.labelLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Invoice cards (mobile)
          for (final inv in state.invoices)
            _buildInvoiceCard(inv, currencyFormat, textColor),
        ],
      );
    }

    // Desktop: single vertical-scrollable page so both DataTables
    // (payouts summary + invoices) are reachable by scrolling down.
    // Each DataTable retains its own horizontal SingleChildScrollView for
    // wide columns — nested horizontal-inside-vertical is the standard
    // Flutter DataTable pattern.
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: hPadding,
        right: hPadding,
        bottom: hPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Controls + search + summary cards
          _buildRangeControlsWithExport(state, textColor),
          const SizedBox(height: 10),
          _buildInvoiceSearch(textColor),
          const SizedBox(height: 12),
          _buildInvoiceSummary(state, currencyFormat, textColor),
          const SizedBox(height: 14),
          // Per-therapist payout summary DataTable
          if (state.payouts.isNotEmpty) ...[
            Text(
              AppStrings.adminPayoutSummary,
              style: AppTypography.labelLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPayoutsTable(state.payouts, currencyFormat, textColor),
            const SizedBox(height: 20),
            Divider(color: textColor.withValues(alpha: 0.1)),
            const SizedBox(height: 12),
          ],
          // Individual invoice rows DataTable
          Text(
            AppStrings.adminTherapistInvoices,
            style: AppTypography.labelLarge.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInvoiceTable(state.invoices, currencyFormat, textColor),
        ],
      ),
    );
  }

  /// Combined date-range controls + export CSV button row.
  Widget _buildRangeControlsWithExport(
      AdminInvoicesState state, Color textColor) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final notifier = ref.read(adminInvoicesProvider.notifier);
    final hasRange = state.from != null || state.to != null;
    final rangeLabel = hasRange
        ? '${state.from != null ? dateFormat.format(state.from!) : '…'}  —  ${state.to != null ? dateFormat.format(state.to!) : '…'}'
        : AppStrings.adminPickDateRange;

    Widget quickChip(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: selected ? 1.5 : 1,
              color: selected
                  ? AppColors.primary
                  : textColor.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: selected ? AppColors.primary : textColor.withValues(alpha: 0.75),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final datePickerBtn = OutlinedButton.icon(
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: DateTime(now.year + 1, 12, 31),
          initialDateRange: state.from != null && state.to != null
              ? DateTimeRange(start: state.from!, end: state.to!)
              : null,
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          notifier.setRange(
            picked.start,
            DateTime(picked.end.year, picked.end.month, picked.end.day,
                23, 59, 59),
          );
        }
      },
      icon: Icon(
        hasRange ? Icons.event_available : Icons.date_range,
        size: 17,
        color: hasRange ? AppColors.primary : textColor.withValues(alpha: 0.6),
      ),
      label: Text(
        rangeLabel,
        style: AppTypography.caption.copyWith(
          color: hasRange ? AppColors.primary : textColor.withValues(alpha: 0.75),
          fontWeight: hasRange ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(
          width: hasRange ? 1.5 : 1,
          color: hasRange ? AppColors.primary : textColor.withValues(alpha: 0.2),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );

    final exportBtn = _buildExportCsvButton(state, textColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Quick-filter chips
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  quickChip(AppStrings.adminAll, !hasRange, notifier.clearRange),
                  quickChip(AppStrings.adminThisWeek, _isThisWeek(state), notifier.setThisWeek),
                  quickChip(AppStrings.adminThisMonth, _isThisMonth(state), notifier.setThisMonth),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Export button — right-aligned, visually distinct
            exportBtn,
          ],
        ),
        const SizedBox(height: 10),
        // Date picker button — full-width row beneath chips
        datePickerBtn,
      ],
    );
  }

  /// Checks if the current range matches "this week" exactly (Mon–Sun).
  bool _isThisWeek(AdminInvoicesState state) {
    if (state.from == null) return false;
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = DateTime(now.year, now.month, now.day - (weekday - 1));
    return state.from!.year == monday.year &&
        state.from!.month == monday.month &&
        state.from!.day == monday.day;
  }

  /// Checks if the current range matches "this month" exactly (1st–last day).
  bool _isThisMonth(AdminInvoicesState state) {
    if (state.from == null) return false;
    final now = DateTime.now();
    return state.from!.year == now.year &&
        state.from!.month == now.month &&
        state.from!.day == 1;
  }

  /// Export CSV button — exports the CURRENTLY DISPLAYED (filtered) invoices.
  Widget _buildExportCsvButton(AdminInvoicesState state, Color textColor) {
    return ElevatedButton.icon(
      onPressed: state.invoices.isEmpty
          ? null
          : () {
              final csv = buildInvoicesCsv(state.invoices);
              final now = DateTime.now();
              final stamp =
                  '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
              downloadCsvOnWeb(csv, 'sanad-invoices-$stamp.csv');
            },
      icon: const Icon(Icons.download_rounded, size: 17),
      label: Text(AppStrings.adminExportCsv),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        textStyle: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  // Keep the original method as an alias for internal use.
  // ignore: unused_element
  Widget _buildRangeControls(AdminInvoicesState state, Color textColor) =>
      _buildRangeControlsWithExport(state, textColor);

  // ── Invoice search (client name / therapist name) ─────────────────────────
  Widget _buildInvoiceSearch(Color textColor) {
    Widget field(
      TextEditingController ctrl,
      String hint,
      IconData prefixIcon,
      ValueChanged<String> onChanged,
    ) {
      OutlineInputBorder border(Color c, {double width = 1}) =>
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c, width: width),
          );
      return TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: AppTypography.bodyMedium.copyWith(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: textColor.withValues(alpha: 0.35),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(prefixIcon, size: 17,
                color: textColor.withValues(alpha: 0.45)),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: ctrl.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.cancel_rounded,
                      size: 16, color: textColor.withValues(alpha: 0.4)),
                  onPressed: () {
                    ctrl.clear();
                    onChanged('');
                  },
                ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          filled: true,
          fillColor: textColor.withValues(alpha: 0.04),
          border: border(textColor.withValues(alpha: 0.15)),
          enabledBorder: border(textColor.withValues(alpha: 0.15)),
          focusedBorder: border(AppColors.primary, width: 1.5),
        ),
      );
    }

    final notifier = ref.read(adminInvoicesProvider.notifier);
    final clientField = field(
      _clientSearchCtrl,
      AppStrings.adminSearchByClientName,
      Icons.person_search_outlined,
      notifier.setClientQuery,
    );
    final therapistField = field(
      _therapistSearchCtrl,
      AppStrings.adminSearchByTherapistName,
      Icons.medical_services_outlined,
      notifier.setTherapistQuery,
    );

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

  Widget _buildInvoiceTable(
    List<InvoiceRecord> invoices,
    NumberFormat fmt,
    Color textColor,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final headerStyle = AppTypography.caption.copyWith(
      color: textColor.withValues(alpha: 0.55),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      fontSize: 11,
    );
    final cellStyle = AppTypography.caption.copyWith(
      color: textColor,
      fontSize: 13,
    );

    DataColumn col(String label, {Color? color}) => DataColumn(
          label: Text(
            label,
            style: color == null
                ? headerStyle
                : headerStyle.copyWith(color: color.withValues(alpha: 0.8)),
          ),
        );

    return GlassCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        // LayoutBuilder outside the horizontal scroll so constraints.maxWidth
        // is the GlassCard's bounded width, not ∞.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 42,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columnSpacing: 32,
                dividerThickness: 0.5,
                headingRowColor: WidgetStateProperty.all(
                  textColor.withValues(alpha: 0.04),
                ),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppColors.primary.withValues(alpha: 0.06);
                  }
                  return Colors.transparent;
                }),
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
                  for (int i = 0; i < invoices.length; i++)
                    DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return AppColors.primary.withValues(alpha: 0.06);
                        }
                        // Zebra striping — subtle alternating shade.
                        return i.isOdd
                            ? textColor.withValues(alpha: 0.025)
                            : Colors.transparent;
                      }),
                      cells: [
                        DataCell(Text(
                          invoices[i].clientName.isEmpty ? '—' : invoices[i].clientName,
                          style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                        )),
                        DataCell(Text(
                          dateFormat.format(invoices[i].date),
                          style: cellStyle.copyWith(
                            color: textColor.withValues(alpha: 0.75),
                          ),
                        )),
                        DataCell(Text(
                          invoices[i].therapistName.isEmpty ? '—' : invoices[i].therapistName,
                          style: cellStyle,
                        )),
                        DataCell(Text(
                          fmt.format(invoices[i].amount),
                          style: cellStyle.copyWith(fontWeight: FontWeight.w700),
                        )),
                        DataCell(Text(
                          fmt.format(invoices[i].shares.therapist),
                          style: cellStyle.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        DataCell(Text(
                          fmt.format(invoices[i].shares.maintenance),
                          style: cellStyle.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        DataCell(Text(
                          fmt.format(invoices[i].shares.app),
                          style: cellStyle.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                      ],
                    ),
                ],
              ),
            ),
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

  /// Desktop DataTable for the per-therapist payout summary.
  Widget _buildPayoutsTable(
    List<TherapistPayout> payouts,
    NumberFormat fmt,
    Color textColor,
  ) {
    final headerStyle = AppTypography.caption.copyWith(
      color: textColor.withValues(alpha: 0.55),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      fontSize: 11,
    );
    final cellStyle = AppTypography.caption.copyWith(
      color: textColor,
      fontSize: 13,
    );

    DataColumn col(String label, {Color? color}) => DataColumn(
          label: Text(
            label,
            style: color == null
                ? headerStyle
                : headerStyle.copyWith(color: color.withValues(alpha: 0.8)),
          ),
        );

    return GlassCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        // LayoutBuilder outside the horizontal scroll so constraints.maxWidth
        // is the GlassCard's bounded width, not ∞.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 42,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                columnSpacing: 28,
                dividerThickness: 0.5,
                headingRowColor: WidgetStateProperty.all(
                  textColor.withValues(alpha: 0.04),
                ),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppColors.primary.withValues(alpha: 0.06);
                  }
                  return Colors.transparent;
                }),
                columns: [
                  col(AppStrings.adminColTherapistName),           // المعالج
                  col(AppStrings.adminColSessions),                 // الجلسات
                  col(AppStrings.adminColGross),                    // الإجمالي
                  col(AppStrings.adminColTherapistDue, color: Colors.green),  // حصة المعالج
                  col(AppStrings.adminColAppShare, color: Colors.blue),       // حصة التطبيق
                  col(AppStrings.adminColMaintenance, color: Colors.orange),  // الصيانة
                ],
                rows: [
                  for (int i = 0; i < payouts.length; i++)
                    DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return AppColors.primary.withValues(alpha: 0.06);
                        }
                        return i.isOdd
                            ? textColor.withValues(alpha: 0.025)
                            : Colors.transparent;
                      }),
                      cells: [
                        DataCell(Text(
                          payouts[i].therapistName.isEmpty
                              ? '—'
                              : payouts[i].therapistName,
                          style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                        )),
                        DataCell(Text(
                          '${payouts[i].sessions}',
                          style: cellStyle,
                        )),
                        DataCell(Text(
                          fmt.format(payouts[i].gross),
                          style: cellStyle.copyWith(fontWeight: FontWeight.w700),
                        )),
                        DataCell(Text(
                          fmt.format(payouts[i].therapistDue),
                          style: cellStyle.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        DataCell(Text(
                          fmt.format(payouts[i].appCut),
                          style: cellStyle.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        DataCell(Text(
                          fmt.format(payouts[i].maintenance),
                          style: cellStyle.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                      ],
                    ),
                ],
              ),
            ),
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
    String label,
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
            label,
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
