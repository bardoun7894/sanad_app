// lib/features/admin/widgets/booking_detail_sheet.dart
//
// Admin booking detail bottom sheet — extracted from bookings_list_screen.dart.
// Includes "Unlock Bank Transfer" admin action that gates the bank-transfer
// payment option on the user-facing BookingPaymentScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../booking/providers/booking_unlock_provider.dart';
import '../../therapist_portal/models/therapist_booking.dart';
import '../../therapists/models/therapist.dart';
import '../../therapists/services/booking_service.dart';

class BookingDetailSheet extends ConsumerStatefulWidget {
  final TherapistBooking booking;
  final bool isDark;

  const BookingDetailSheet({
    super.key,
    required this.booking,
    required this.isDark,
  });

  @override
  ConsumerState<BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends ConsumerState<BookingDetailSheet> {
  bool _isUnlocking = false;

  Future<void> _handleUnlockBankTransfer() async {
    // Use English strings for admin screen (admin panel is EN-only)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlock Bank Transfer'),
        content: const Text(
          'Unlock bank transfer for this booking? The user will be able to pay via bank transfer once unlocked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUnlocking = true);
    try {
      await ref
          .read(bookingServiceProvider)
          .unlockBankTransfer(widget.booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank transfer unlocked for this booking.'),
            backgroundColor: AppColors.statusSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unlock: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUnlocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final booking = widget.booking;
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Stream the unlock flag so the button updates live
    final unlockedAsync = ref.watch(
      bankTransferUnlockedProvider(booking.id),
    );
    final isUnlocked = unlockedAsync.valueOrNull ?? false;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSessionTypeIcon(booking.sessionType),
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.clientName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${booking.sessionType.name.toUpperCase()} Session',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: dateFormat.format(booking.scheduledTime),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: timeFormat.format(booking.scheduledTime),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.attach_money_rounded,
                  label: 'Amount',
                  value: '${booking.amount} ${booking.currency}',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Status',
                  value: booking.status.name.toUpperCase(),
                  valueColor: _getStatusColor(booking.status),
                  isDark: isDark,
                ),
                if (booking.notes != null) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.note_alt_outlined,
                    label: 'Notes',
                    value: booking.notes!,
                    isDark: isDark,
                  ),
                ],
                if (booking.cancellationReason != null) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.cancel_outlined,
                    label: 'Cancellation Reason',
                    value: booking.cancellationReason!,
                    valueColor: AppColors.statusDanger,
                    isDark: isDark,
                  ),
                ],

                // ── Bank Transfer Unlock ────────────────────────────────────
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                if (isUnlocked)
                  // Already unlocked — show read-only badge
                  Row(
                    children: [
                      Icon(
                        Icons.lock_open_rounded,
                        size: 18,
                        color: AppColors.statusSuccess,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bank Transfer Unlocked',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                    ],
                  )
                else
                  // Locked — show action button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUnlocking ? null : _handleUnlockBankTransfer,
                      icon: _isUnlocking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_open_rounded, size: 18),
                      label: Text(
                        _isUnlocking
                            ? 'Unlocking…'
                            : 'Unlock Bank Transfer',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

IconData _getSessionTypeIcon(SessionType type) {
  switch (type) {
    case SessionType.chat:
      return Icons.chat_bubble_outline_rounded;
    case SessionType.audio:
      return Icons.phone_rounded;
    case SessionType.inPerson:
      return Icons.person_outline_rounded;
  }
}

Color _getStatusColor(BookingStatus status) {
  switch (status) {
    case BookingStatus.confirmed:
      return AppColors.statusSuccess;
    case BookingStatus.pending:
      return AppColors.statusWarning;
    case BookingStatus.completed:
      return AppColors.statusInfo;
    case BookingStatus.cancelled:
    case BookingStatus.rejected:
    case BookingStatus.noShow:
      return AppColors.statusDanger;
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? AppColors.adminTextSecondary
              : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      valueColor ??
                      (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
