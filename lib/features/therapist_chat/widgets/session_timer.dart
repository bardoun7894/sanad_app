import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../therapist_portal/models/therapist_booking.dart';
import '../../therapist_portal/providers/therapist_dashboard_provider.dart';

class SessionTimer extends ConsumerStatefulWidget {
  final String bookingId;

  const SessionTimer({super.key, required this.bookingId});

  @override
  ConsumerState<SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends ConsumerState<SessionTimer> {
  TherapistBooking? _booking;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    try {
      final service = ref.read(therapistBookingServiceProvider);
      final booking = await service.getBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    if (_booking == null) return;

    // Update immediately
    _updateTime();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (_booking == null) return;

    final now = DateTime.now();
    final endTime = _booking!.endTime;
    // or use scheduledTime + duration if endTime getter depends on it

    if (now.isAfter(endTime)) {
      if (_remaining != Duration.zero) {
        setState(() => _remaining = Duration.zero);
      }
      _timer?.cancel();
      return;
    }

    if (now.isBefore(_booking!.scheduledTime)) {
      // Future session
      final startDiff = _booking!.scheduledTime.difference(now);
      if (mounted) setState(() => _remaining = startDiff);
      return;
    }

    final diff = endTime.difference(now);
    if (mounted) {
      setState(() => _remaining = diff);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_booking == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final isFuture = now.isBefore(_booking!.scheduledTime);
    final isPast = now.isAfter(_booking!.endTime);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isPast) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.red.withOpacity(0.2) : Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off_outlined, size: 14, color: Colors.red),
            const SizedBox(width: 6),
            Text(
              'Ended',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    Color color = AppColors.primary;
    if (!isFuture && _remaining.inMinutes < 5) {
      color = Colors.red;
    } else if (isFuture) {
      color = Colors.orange;
    }

    String label = isFuture ? 'Starts in' : 'Remaining';
    String timeText = _formatDuration(_remaining);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label $timeText',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
