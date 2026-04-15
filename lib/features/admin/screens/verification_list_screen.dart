import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../models/payment_verification.dart';
import 'receipt_review_screen.dart';

class VerificationListScreen extends ConsumerWidget {
  const VerificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);
    // isDark unused
    final s = ref.watch(stringsProvider);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final isMobile = AdminResponsive.isMobile(context);
    final pagePadding = AdminResponsive.pagePadding(context);

    if (!ref.watch(authProvider).isAdmin) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    s.accessDenied,
                    style: AppTypography.headingMedium.copyWith(
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.adminOnlyAccess,
                    style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Padding(
            padding: pagePadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.paymentVerifications,
                    style: AppTypography.headingMedium.copyWith(
                      color: textColor,
                      fontSize: isMobile ? 22 : null,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(adminProvider.notifier).loadVerifications(),
                  icon: Icon(Icons.refresh_rounded, color: textColor),
                ),
              ],
            ),
          ),

          // Filter tabs
          _FilterTabs(
            currentFilter: state.filter,
            onFilterChanged: (filter) {
              ref.read(adminProvider.notifier).setFilter(filter);
            },
            pendingCount: state.pendingVerifications.length,
            textColor: textColor,
          ),

          const SizedBox(height: 16),

          // Error message
          if (state.error != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          ref.read(adminProvider.notifier).clearError(),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content
          Expanded(
            child: state.isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.filteredVerifications.isEmpty
                ? _EmptyState(filter: state.filter, textColor: textColor)
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(adminProvider.notifier).loadVerifications(),
                    child: ListView.builder(
                      padding: pagePadding,
                      itemCount: state.filteredVerifications.length,
                      itemBuilder: (context, index) {
                        final verification = state.filteredVerifications[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _VerificationCard(
                            verification: verification,
                            onTap: () =>
                                _openReviewScreen(context, verification),
                            textColor: textColor,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openReviewScreen(
    BuildContext context,
    PaymentVerification verification,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptReviewScreen(verification: verification),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final VerificationFilter currentFilter;
  final ValueChanged<VerificationFilter> onFilterChanged;
  final int pendingCount;
  final Color textColor;

  const _FilterTabs({
    required this.currentFilter,
    required this.onFilterChanged,
    required this.pendingCount,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AdminResponsive.isMobile(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: VerificationFilter.values.map((filter) {
              final isSelected = currentFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _FilterTab(
                  label: _getFilterLabel(filter, context),
                  count: filter == VerificationFilter.pending
                      ? pendingCount
                      : null,
                  isSelected: isSelected,
                  onTap: () => onFilterChanged(filter),
                  textColor: textColor,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _getFilterLabel(VerificationFilter filter, BuildContext context) {
    switch (filter) {
      case VerificationFilter.pending:
        return AppStrings.adminVerificationPending;
      case VerificationFilter.approved:
        return AppStrings.adminVerificationApproved;
      case VerificationFilter.rejected:
        return AppStrings.adminVerificationRejected;
      case VerificationFilter.all:
        return AppStrings.adminVerificationAll;
    }
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textColor;

  const _FilterTab({
    required this.label,
    this.count,
    required this.isSelected,
    required this.onTap,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : textColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : textColor.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final PaymentVerification verification;
  final VoidCallback onTap;
  final Color textColor;

  const _VerificationCard({
    required this.verification,
    required this.onTap,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        verification.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(verification.status),
                      color: _getStatusColor(verification.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verification.userName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          verification.userEmail,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(verification.status),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          verification.productTitle,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${verification.currency} ${verification.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: textColor.withValues(alpha: 0.05)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.tag,
                    size: 14,
                    color: textColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    verification.referenceCode,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: textColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(verification.createdAt),
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(VerificationStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.approved:
        return AppColors.success;
      case VerificationStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Icons.hourglass_empty_rounded;
      case VerificationStatus.approved:
        return Icons.check_circle_outline_rounded;
      case VerificationStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final VerificationFilter filter;
  final Color textColor;

  const _EmptyState({required this.filter, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: textColor.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No verifications found.',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.3),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
