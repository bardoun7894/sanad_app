// lib/features/admin/widgets/booking_detail_sheet.dart
//
// Admin booking detail bottom sheet — extracted from bookings_list_screen.dart.
// Includes "Unlock Bank Transfer" admin action that gates the bank-transfer
// payment option on the user-facing BookingPaymentScreen.

import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isConfirming = false;

  Future<void> _handleConfirmBankTransfer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Bank Transfer Received'),
        content: const Text(
          'Have you verified that the bank transfer arrived for this booking? '
          'Confirming will mark the booking as paid and notify the therapist '
          'to accept or reject the request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusSuccess,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isConfirming = true);
    try {
      final adminUid =
          FirebaseAuth.instance.currentUser?.uid ?? 'unknown_admin';
      await ref.read(bookingServiceProvider).markBankTransferPaid(
            bookingId: widget.booking.id,
            adminUid: adminUid,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Payment confirmed. Therapist has been notified.'),
            backgroundColor: AppColors.statusSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm payment: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

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
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.payment_rounded,
                  label: 'Payment Method',
                  value: _formatPaymentMethod(
                    booking.paymentMethod,
                    booking.paymentStatus,
                  ),
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

                // ── Confirm bank-transfer payment ──────────────────────────
                // Only relevant while the booking is awaiting payment. After
                // confirming, status flips to `pending` and the therapist is
                // notified to accept/reject.
                if (booking.status == BookingStatus.awaitingPayment) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Bank-transfer payment',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use after you have verified that the money has arrived '
                    'in the bank account.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isConfirming ? null : _handleConfirmBankTransfer,
                      icon: _isConfirming
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_rounded, size: 18),
                      label: Text(
                        _isConfirming
                            ? 'Confirming…'
                            : 'Confirm bank transfer received',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusSuccess,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],

                // ── Bank Transfer Unlock (fallback) ─────────────────────────
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // This control is a FALLBACK that lets the admin make the
                // bank-transfer payment option visible to the user on the
                // payment screen. It is NOT a payment method indicator —
                // see the "Payment Method" row above for the actual gateway.
                Text(
                  'Bank-transfer fallback',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use only if the user cannot complete card or wallet payment.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
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
                        'Bank transfer enabled for this booking',
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
                            ? 'Enabling…'
                            : 'Enable bank-transfer fallback',
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

String _formatPaymentMethod(String? method, String? paymentStatus) {
  if (method == null || method.isEmpty) {
    if (paymentStatus == 'paid') return 'Unknown (paid)';
    return 'Not paid yet';
  }
  switch (method) {
    case 'google_pay':
      return 'Google Pay';
    case 'apple_pay':
      return 'Apple Pay';
    case 'paypal':
      return 'PayPal';
    case 'bank_transfer':
      return 'Bank Transfer';
    case 'freemius_card':
      return 'Card (Visa/Mastercard)';
    default:
      return method;
  }
}

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
    case BookingStatus.awaitingPayment:
      return AppColors.statusWarning;
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
