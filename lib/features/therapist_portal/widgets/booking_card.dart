import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../therapists/models/therapist.dart';
import '../models/therapist_booking.dart';

/// A card widget for displaying booking information
class BookingCard extends ConsumerWidget {
  final TherapistBooking booking;
  final bool showActions;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onJoin;

  const BookingCard({
    super.key,
    required this.booking,
    this.showActions = false,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onComplete,
    this.onCancel,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey.shade200,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with client info and status
            Row(
              children: [
                // Client avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: booking.clientPhotoUrl != null
                      ? NetworkImage(booking.clientPhotoUrl!)
                      : null,
                  child: booking.clientPhotoUrl == null
                      ? Text(
                          booking.clientName.isNotEmpty
                              ? booking.clientName[0].toUpperCase()
                              : 'C',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Client name and session type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSessionTypeName(booking.sessionType, s),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMuted
                              : Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                _buildStatusBadge(booking.status, s),
              ],
            ),
            const SizedBox(height: 16),

            // Date and time
            Row(
              children: [
                _buildInfoChip(
                  context,
                  icon: Icons.calendar_today,
                  label: DateFormat(
                    'MMM d, yyyy',
                  ).format(booking.scheduledTime),
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  context,
                  icon: Icons.access_time,
                  label: DateFormat('h:mm a').format(booking.scheduledTime),
                ),
              ],
            ),

            // Notes if available
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: isDark
                          ? AppColors.textMuted
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.notes!,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (showActions && booking.status == BookingStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(s.decline),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(s.accept),
                    ),
                  ),
                ],
              ),
            ],

            // Confirmed booking actions
            if (showActions && booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onCancel != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(s.cancel),
                      ),
                    ),
                  if (onCancel != null &&
                      (onComplete != null || onJoin != null))
                    const SizedBox(width: 12),

                  // Show Join button if it's a call session and available
                  if (onJoin != null &&
                      booking.sessionType == SessionType.audio)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onJoin,
                        icon: const Icon(Icons.call, size: 18),
                        label: Text(s.callLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                  else if (onComplete != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors
                              .green, // Different color to distinguish from Join
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(s.complete),
                      ),
                    ),
                ],
              ),
              // If we have both Join AND Complete (e.g. after call), show Complete below or next to it?
              // For simplicity, let's keep Complete available if onJoin is NOT shown (e.g. past time)
              // OR add a separate row if needed. ideally therapists complete after the call.
              // Let's add a "Complete" button below if "Join" is shown, or just rely on the list refresh.
              // Actually, simplest is: If Join is available, show Join. If they want to complete, they can do it from detail or maybe we act dumb and show both?
              // Let's modify logic: Show Join if isToday. Show Complete Always?
              // Space is tight. Let's just match the design in the request.
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppColors.textMuted : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status, S s) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case BookingStatus.awaitingPayment:
        backgroundColor = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        text = s.awaitingPayment;
        break;
      case BookingStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = s.pending;
        break;
      case BookingStatus.confirmed:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        text = s.confirmed;
        break;
      case BookingStatus.completed:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = s.completed;
        break;
      case BookingStatus.cancelled:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        text = s.cancelled;
        break;
      case BookingStatus.rejected:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        text = s.rejected;
        break;
      case BookingStatus.noShow:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        text = s.noShow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getSessionTypeName(SessionType type, S s) {
    switch (type) {
      case SessionType.audio:
        return s.audioSession;
      case SessionType.chat:
        return s.chatSession;
      case SessionType.inPerson:
        return s.inPersonSession;
    }
  }
}

/// A compact booking card for list views
class CompactBookingCard extends ConsumerWidget {
  final TherapistBooking booking;
  final VoidCallback? onTap;

  const CompactBookingCard({super.key, required this.booking, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : Colors.grey.shade200,
            ),
          ),
        ),
        child: Row(
          children: [
            // Time
            SizedBox(
              width: 60,
              child: Text(
                DateFormat('h:mm a').format(booking.scheduledTime),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            // Divider
            Container(
              width: 3,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Client info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.clientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _getSessionTypeName(booking.sessionType, s),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textMuted
                          : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.awaitingPayment:
        return Colors.amber;
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.noShow:
        return Colors.purple;
    }
  }

  String _getSessionTypeName(SessionType type, S s) {
    switch (type) {
      case SessionType.audio:
        return s.audio;
      case SessionType.chat:
        return s.chat;
      case SessionType.inPerson:
        return s.inPerson;
    }
  }
}
