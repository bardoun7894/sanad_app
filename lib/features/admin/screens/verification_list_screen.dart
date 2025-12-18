import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../providers/admin_provider.dart';
import '../models/payment_verification.dart';
import 'receipt_review_screen.dart';

class VerificationListScreen extends ConsumerWidget {
  const VerificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    if (!state.isAdmin) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                s.accessDenied,
                style: AppTypography.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.adminOnlyAccess,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.paymentVerifications),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(adminProvider.notifier).loadVerifications(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          _FilterTabs(
            currentFilter: state.filter,
            onFilterChanged: (filter) {
              ref.read(adminProvider.notifier).setFilter(filter);
            },
            pendingCount: state.pendingVerifications.length,
          ),

          // Error message
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(adminProvider.notifier).clearError(),
                    icon: Icon(Icons.close, size: 18, color: AppColors.error),
                  ),
                ],
              ),
            ),

          // Loading or list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredVerifications.isEmpty
                    ? _EmptyState(filter: state.filter)
                    : RefreshIndicator(
                        onRefresh: () => ref.read(adminProvider.notifier).loadVerifications(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.filteredVerifications.length,
                          itemBuilder: (context, index) {
                            final verification = state.filteredVerifications[index];
                            return _VerificationCard(
                              verification: verification,
                              onTap: () => _openReviewScreen(context, verification),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _openReviewScreen(BuildContext context, PaymentVerification verification) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptReviewScreen(verification: verification),
      ),
    );
  }
}

class _FilterTabs extends ConsumerWidget {
  final VerificationFilter currentFilter;
  final ValueChanged<VerificationFilter> onFilterChanged;
  final int pendingCount;

  const _FilterTabs({
    required this.currentFilter,
    required this.onFilterChanged,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _FilterTab(
            label: s.pending,
            count: pendingCount,
            isSelected: currentFilter == VerificationFilter.pending,
            onTap: () => onFilterChanged(VerificationFilter.pending),
          ),
          _FilterTab(
            label: s.approved,
            isSelected: currentFilter == VerificationFilter.approved,
            onTap: () => onFilterChanged(VerificationFilter.approved),
          ),
          _FilterTab(
            label: s.rejected,
            isSelected: currentFilter == VerificationFilter.rejected,
            onTap: () => onFilterChanged(VerificationFilter.rejected),
          ),
          _FilterTab(
            label: s.all,
            isSelected: currentFilter == VerificationFilter.all,
            onTap: () => onFilterChanged(VerificationFilter.all),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationCard extends ConsumerWidget {
  final PaymentVerification verification;
  final VoidCallback onTap;

  const _VerificationCard({
    required this.verification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(verification.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getStatusIcon(verification.status),
                    color: _getStatusColor(verification.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verification.userName,
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark ? Colors.white : AppColors.textLight,
                        ),
                      ),
                      Text(
                        verification.userEmail,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: verification.status),
              ],
            ),

            const SizedBox(height: 16),

            // Product info
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    verification.productTitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                ),
                Text(
                  '${verification.currency} ${verification.amount.toStringAsFixed(2)}',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Reference code
            Row(
              children: [
                Icon(Icons.tag, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  '${s.referenceCode}: ${verification.referenceCode}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  _formatDate(verification.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return AppColors.warning;
      case VerificationStatus.approved:
        return AppColors.success;
      case VerificationStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Icons.pending_outlined;
      case VerificationStatus.approved:
        return Icons.check_circle_outline;
      case VerificationStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _StatusBadge extends ConsumerWidget {
  final VerificationStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getLabel(s),
        style: TextStyle(
          color: _getColor(),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case VerificationStatus.pending:
        return AppColors.warning;
      case VerificationStatus.approved:
        return AppColors.success;
      case VerificationStatus.rejected:
        return AppColors.error;
    }
  }

  String _getLabel(S s) {
    switch (status) {
      case VerificationStatus.pending:
        return s.pending;
      case VerificationStatus.approved:
        return s.approved;
      case VerificationStatus.rejected:
        return s.rejected;
    }
  }
}

class _EmptyState extends ConsumerWidget {
  final VerificationFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.softBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.noVerifications,
              style: AppTypography.headingSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyMessage(s),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyMessage(S s) {
    switch (filter) {
      case VerificationFilter.pending:
        return s.noPendingVerifications;
      case VerificationFilter.approved:
        return s.noApprovedVerifications;
      case VerificationFilter.rejected:
        return s.noRejectedVerifications;
      case VerificationFilter.all:
        return s.noVerificationsYet;
    }
  }
}
