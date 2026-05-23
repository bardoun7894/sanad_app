import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/services/zego_call_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapists/models/therapist.dart';
import '../models/therapist_booking.dart';

import 'therapist_bookings_screen.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final TherapistBooking? initialBooking;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.initialBooking,
  });

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  TherapistBooking? _booking;
  bool _isLoading = false;
  final _notesController = TextEditingController();
  Timer? _callWindowTicker;

  @override
  void initState() {
    super.initState();
    _booking = widget.initialBooking;
    if (_booking == null) {
      _loadBooking();
    } else {
      _notesController.text = _booking?.privateNotes ?? '';
    }
    // Tick every 30s so the call-window gate re-evaluates without manual refresh.
    _callWindowTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _callWindowTicker?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(therapistBookingServiceProvider);
      final booking = await service.getBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _notesController.text = booking?.privateNotes ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.bookingDetails)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.bookingDetails)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(strings.bookingNotFound),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(strings.goBack),
              ),
            ],
          ),
        ),
      );
    }

    final booking = _booking!;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(strings.bookingDetails),
        actions: [
          if (booking.status == BookingStatus.confirmed)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'complete':
                    _completeSession(strings);
                    break;
                  case 'no_show':
                    _markNoShow(strings);
                    break;
                  case 'cancel':
                    _showCancelDialog(strings);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(strings.completeSession),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'no_show',
                  child: Row(
                    children: [
                      const Icon(Icons.person_off, color: Colors.purple),
                      const SizedBox(width: 12),
                      Text(strings.markNoShow),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(strings.cancelBooking),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            _buildStatusHeader(booking, strings, isDark),
            const SizedBox(height: 24),

            // Client info
            _buildSectionTitle(strings.clientInfo, isDark),
            const SizedBox(height: 12),
            _buildClientCard(booking, isDark),
            const SizedBox(height: 24),

            // Session details
            _buildSectionTitle(strings.sessionDetails, isDark),
            const SizedBox(height: 12),
            _buildSessionCard(booking, strings, isDark),
            const SizedBox(height: 24),

            // Call client — visible only when confirmed + within call window.
            if (booking.status == BookingStatus.confirmed &&
                booking.sessionType != SessionType.chat) ...[
              _buildCallClientSection(booking, strings, isDark),
              const SizedBox(height: 24),
            ],

            // Notes section
            _buildSectionTitle(strings.sessionNotes, isDark),
            const SizedBox(height: 12),
            _buildNotesSection(booking, strings, isDark),
            const SizedBox(height: 24),

            // Action buttons for pending bookings
            if (booking.status == BookingStatus.pending) ...[
              _buildPendingActions(booking, strings),
              const SizedBox(height: 24),
            ],

            // Cancellation/Rejection info
            if (booking.status == BookingStatus.cancelled &&
                booking.cancellationReason != null) ...[
              _buildInfoCard(
                strings.cancellationReason,
                booking.cancellationReason!,
                Colors.red,
                isDark,
              ),
              const SizedBox(height: 24),
            ],
            if (booking.status == BookingStatus.rejected &&
                booking.rejectionReason != null) ...[
              _buildInfoCard(
                strings.rejectionReason,
                booking.rejectionReason!,
                Colors.orange,
                isDark,
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(TherapistBooking booking, S strings, bool isDark) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (booking.status) {
      case BookingStatus.awaitingPayment:
        statusColor = Colors.amber;
        statusText = strings.awaitingPayment;
        statusIcon = Icons.payment;
        break;
      case BookingStatus.pending:
        statusColor = Colors.orange;
        statusText = strings.pending;
        statusIcon = Icons.pending;
        break;
      case BookingStatus.confirmed:
        statusColor = Colors.blue;
        statusText = strings.confirmed;
        statusIcon = Icons.check_circle;
        break;
      case BookingStatus.completed:
        statusColor = Colors.green;
        statusText = strings.completed;
        statusIcon = Icons.task_alt;
        break;
      case BookingStatus.cancelled:
        statusColor = Colors.grey;
        statusText = strings.cancelled;
        statusIcon = Icons.cancel;
        break;
      case BookingStatus.rejected:
        statusColor = Colors.red;
        statusText = strings.rejected;
        statusIcon = Icons.block;
        break;
      case BookingStatus.noShow:
        statusColor = Colors.purple;
        statusText = strings.noShow;
        statusIcon = Icons.person_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${strings.booked}: ${DateFormat('MMM d, yyyy').format(booking.createdAt)}',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildClientCard(TherapistBooking booking, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
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
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            booking.clientName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (booking.clientAge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${booking.clientAge} ${ref.read(stringsProvider).yearsOld}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (booking.clientEmail != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        booking.clientEmail!,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (booking.primaryComplaint != null &&
              booking.primaryComplaint!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              ref.read(stringsProvider).primaryComplaint,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.primaryComplaint!,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionCard(TherapistBooking booking, S strings, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.calendar_today,
            strings.date,
            DateFormat('EEEE, MMMM d, yyyy').format(booking.scheduledTime),
            isDark,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.access_time,
            strings.time,
            DateFormat('h:mm a').format(booking.scheduledTime),
            isDark,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.timelapse,
            strings.duration,
            '${booking.durationMinutes} ${strings.minutes}',
            isDark,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            _getSessionTypeIcon(booking.sessionType),
            strings.sessionType,
            _getSessionTypeName(booking.sessionType, strings),
            isDark,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.payments,
            strings.amount,
            booking.formattedAmount,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(TherapistBooking booking, S strings, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: strings.addSessionNotes,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _saveNotes(strings),
              icon: const Icon(Icons.save),
              label: Text(strings.saveNotes),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String content,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActions(TherapistBooking booking, S strings) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showRejectDialog(strings),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(strings.reject),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _acceptBooking(strings),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(strings.accept),
          ),
        ),
      ],
    );
  }

  // ── Call client section ─────────────────────────────────────────────────
  //
  // Visible only when the booking is confirmed AND the current time is
  // within [scheduled - 5min, scheduled + duration + 15min].
  // The client never has a call button — this is the only entry point.

  Duration _windowOffsetBefore() => const Duration(minutes: 5);
  Duration _windowOffsetAfter(int durationMinutes) =>
      Duration(minutes: durationMinutes + 15);

  bool _isWithinCallWindow(TherapistBooking booking) {
    final now = DateTime.now();
    final start = booking.scheduledTime.subtract(_windowOffsetBefore());
    final end = booking.scheduledTime.add(
      _windowOffsetAfter(booking.durationMinutes),
    );
    return now.isAfter(start) && now.isBefore(end);
  }

  int _minutesUntilWindowOpens(TherapistBooking booking) {
    final start = booking.scheduledTime.subtract(_windowOffsetBefore());
    return start.difference(DateTime.now()).inMinutes;
  }

  bool _isAfterCallWindow(TherapistBooking booking) {
    final end = booking.scheduledTime.add(
      _windowOffsetAfter(booking.durationMinutes),
    );
    return DateTime.now().isAfter(end);
  }

  Widget _buildCallClientSection(
    TherapistBooking booking,
    S strings,
    bool isDark,
  ) {
    final enabled = _isWithinCallWindow(booking);
    final afterEnd = _isAfterCallWindow(booking);

    String? helper;
    if (!enabled) {
      if (afterEnd) {
        helper = strings.sessionWindowEnded;
      } else {
        final mins = _minutesUntilWindowOpens(booking);
        if (mins > 0) {
          helper = '${strings.callAvailableInMin} $mins min';
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: enabled ? () => _callClient(booking, strings) : null,
          icon: const Icon(Icons.call_rounded, size: 20),
          label: Text(
            strings.callClient,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 8),
          Text(
            helper,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _callClient(TherapistBooking booking, S strings) async {
    final therapistId = ref.read(authProvider).user?.uid ?? 'therapist';
    final therapistName =
        ref.read(authProvider).user?.displayName ?? 'Therapist';

    try {
      final result = await ZegoCallService.instance.sendCallInvitation(
        targetUserId: booking.clientId,
        targetUserName: booking.clientName,
        callID: booking.id,
        callerUserId: therapistId,
        callerName: therapistName,
        chatId: booking.id,
        timeoutSeconds: 60,
      );

      if (!result.ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${strings.errorOccurred}${result.error != null ? '\n${result.error}' : ''}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.errorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getSessionTypeIcon(SessionType type) {
    switch (type) {
      case SessionType.audio:
        return Icons.call;
      case SessionType.chat:
        return Icons.chat;
      case SessionType.inPerson:
        return Icons.person;
    }
  }

  String _getSessionTypeName(SessionType type, S strings) {
    switch (type) {
      case SessionType.audio:
        return strings.audioSession;
      case SessionType.chat:
        return strings.chatSession;
      case SessionType.inPerson:
        return strings.inPersonSession;
    }
  }

  Future<void> _acceptBooking(S strings) async {
    try {
      final service = ref.read(therapistBookingServiceProvider);
      await service.acceptBooking(widget.bookingId);
      await _loadBooking();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.bookingAccepted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRejectDialog(S strings) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.rejectBooking),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: strings.reason,
            hintText: strings.optionalReason,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _rejectBooking(reasonController.text, strings);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(strings.reject),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectBooking(String reason, S strings) async {
    try {
      final service = ref.read(therapistBookingServiceProvider);
      await service.rejectBooking(widget.bookingId, reason);
      await _loadBooking();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.bookingRejected),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveNotes(S strings) async {
    try {
      final service = ref.read(therapistBookingServiceProvider);
      await service.updatePrivateNotes(widget.bookingId, _notesController.text);
      await _loadBooking();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.notesSaved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeSession(S strings) async {
    try {
      final service = ref.read(therapistBookingServiceProvider);
      await service.completeSession(
        widget.bookingId,
        notes: _notesController.text,
      );
      await _loadBooking();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.sessionCompleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markNoShow(S strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.markNoShow),
        content: Text(strings.markNoShowConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(therapistBookingServiceProvider);
        await service.markNoShow(widget.bookingId);
        await _loadBooking();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.markedAsNoShow),
              backgroundColor: Colors.purple,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.errorOccurred),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showCancelDialog(S strings) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.cancelBooking),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: strings.reason,
            hintText: strings.enterCancellationReason,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.back),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context);
              await _cancelBooking(reasonController.text, strings);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(strings.cancelBooking),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String reason, S strings) async {
    try {
      final service = ref.read(therapistBookingServiceProvider);
      await service.cancelBooking(widget.bookingId, reason);
      await _loadBooking();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.bookingCancelled),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
