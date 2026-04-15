import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/services/zego_call_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/therapist_booking.dart';
import '../services/therapist_booking_service.dart';
import '../widgets/booking_card.dart';
import '../widgets/bookings_analytics_header.dart';
import '../../therapists/models/therapist.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

/// Provider for booking service
final therapistBookingServiceProvider = Provider<TherapistBookingService>((
  ref,
) {
  return TherapistBookingService();
});

/// Provider for all bookings with optional status filter
final therapistBookingsProvider =
    StreamProvider.family<List<TherapistBooking>, BookingStatus?>((
      ref,
      status,
    ) {
      final authState = ref.watch(authProvider);
      final service = ref.watch(therapistBookingServiceProvider);

      if (authState.user?.uid == null) {
        return Stream.value([]);
      }

      return service.getBookings(authState.user!.uid, status: status);
    });

class TherapistBookingsScreen extends ConsumerStatefulWidget {
  const TherapistBookingsScreen({super.key});

  @override
  ConsumerState<TherapistBookingsScreen> createState() =>
      _TherapistBookingsScreenState();
}

class _TherapistBookingsScreenState
    extends ConsumerState<TherapistBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BookingStatus? _selectedStatus;

  final List<BookingStatus?> _statusFilters = [
    null, // All
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.completed,
    BookingStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedStatus = _statusFilters[_tabController.index];
        });
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
    final strings = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookingsAsync = ref.watch(therapistBookingsProvider(_selectedStatus));
    final allBookingsAsync = ref.watch(therapistBookingsProvider(null));

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: Text(strings.bookings)),
      body: SafeArea(
        child: Column(
          children: [
            // Analytics Header
            allBookingsAsync.when(
              data: (bookings) => BookingsAnalyticsHeader(
                data: _generateAnalyticsData(bookings),
              ),
              loading: () => BookingsAnalyticsHeader(
                data: _generateAnalyticsData([]), // Show zeros while loading
              ),
              error: (_, __) => BookingsAnalyticsHeader(
                data: _generateAnalyticsData([]), // Show zeros on error
              ),
            ),
            // Tab Bar
            Container(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: strings.all),
                  Tab(text: strings.pending),
                  Tab(text: strings.confirmed),
                  Tab(text: strings.completed),
                  Tab(text: strings.cancelled),
                ],
              ),
            ),

            // Content
            Expanded(
              child: bookingsAsync.when(
                loading: () => LoadingStateWidget(message: strings.loadingData),
                error: (error, stack) => ErrorStateWidget(
                  message: strings.errorLoadingData,
                  retryLabel: strings.retry,
                  onRetry: () => ref.refresh(
                    therapistBookingsProvider(_selectedStatus),
                  ),
                ),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return _buildEmptyState(strings, isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.refresh(therapistBookingsProvider(_selectedStatus));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BookingCard(
                            booking: booking,
                            showActions:
                                booking.status == BookingStatus.pending ||
                                booking.status == BookingStatus.confirmed,
                            onTap: () => _openBookingDetail(booking),
                            onAccept: () => _acceptBooking(booking, strings),
                            onReject: () => _showRejectDialog(booking, strings),
                            onComplete:
                                booking.status == BookingStatus.confirmed
                                ? () => _completeBooking(booking, strings)
                                : null,
                            onCancel: booking.status == BookingStatus.confirmed
                                ? () => _showCancelDialog(booking, strings)
                                : null,
                            onJoin:
                                (booking.status == BookingStatus.confirmed &&
                                    booking.isToday)
                                ? () => _joinSession(booking)
                                : null,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate analytics data from bookings
  BookingsAnalyticsData _generateAnalyticsData(
    List<TherapistBooking>? bookings,
  ) {
    if (bookings == null || bookings.isEmpty) {
      return const BookingsAnalyticsData(
        total: 0,
        pending: 0,
        confirmed: 0,
        completed: 0,
        weeklyVolume: [0, 0, 0, 0],
      );
    }

    final total = bookings.length;
    final pending = bookings
        .where((b) => b.status == BookingStatus.pending)
        .length;
    final confirmed = bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .length;
    final completed = bookings
        .where((b) => b.status == BookingStatus.completed)
        .length;

    // Calculate weekly volume (last 4 weeks)
    final now = DateTime.now();
    final volume = List.filled(4, 0);

    for (var i = 0; i < 4; i++) {
      final weekStart = now.subtract(Duration(days: (3 - i) * 7 + 7));
      final weekEnd = now.subtract(Duration(days: (3 - i) * 7));

      volume[i] = bookings.where((b) {
        return b.scheduledTime.isAfter(weekStart) &&
            b.scheduledTime.isBefore(weekEnd);
      }).length;
    }

    return BookingsAnalyticsData(
      total: total,
      pending: pending,
      confirmed: confirmed,
      completed: completed,
      weeklyVolume: volume,
    );
  }

  Widget _buildEmptyState(S strings, bool isDark) {
    String message;
    IconData icon;

    switch (_selectedStatus) {
      case BookingStatus.pending:
        message = strings.noPendingBookings;
        icon = Icons.pending_actions;
        break;
      case BookingStatus.confirmed:
        message = strings.noConfirmedBookings;
        icon = Icons.event_available;
        break;
      case BookingStatus.completed:
        message = strings.noCompletedBookings;
        icon = Icons.check_circle_outline;
        break;
      case BookingStatus.cancelled:
        message = strings.noCancelledBookings;
        icon = Icons.cancel_outlined;
        break;
      default:
        message = strings.noBookingsYet;
        icon = Icons.calendar_today;
    }

    return EmptyStateWidget(
      icon: icon,
      message: message,
    );
  }

  void _openBookingDetail(TherapistBooking booking) {
    context.push('/therapist/booking/${booking.id}', extra: booking);
  }

  Future<void> _acceptBooking(TherapistBooking booking, S strings) async {
    try {
      final service = ref.read(therapistBookingServiceProvider);
      await service.acceptBooking(booking.id);

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

  void _showRejectDialog(TherapistBooking booking, S strings) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.rejectBooking),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.rejectBookingConfirm),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: strings.reason,
                hintText: strings.optionalReason,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _rejectBooking(booking, reasonController.text, strings);
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

  Future<void> _rejectBooking(
    TherapistBooking booking,
    String reason,
    S strings,
  ) async {
    try {
      final service = ref.read(therapistBookingServiceProvider);
      await service.rejectBooking(booking.id, reason);

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

  Future<void> _completeBooking(TherapistBooking booking, S strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.completeSession),
        content: Text(strings.completeSessionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(strings.complete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(therapistBookingServiceProvider);
        await service.completeSession(booking.id);

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
  }

  void _showCancelDialog(TherapistBooking booking, S strings) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.cancelBooking),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.cancelBookingConfirm),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: strings.reason,
                hintText: strings.enterCancellationReason,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.back),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.pleaseEnterReason)),
                );
                return;
              }
              Navigator.pop(context);
              await _cancelBooking(booking, reasonController.text, strings);
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

  Future<void> _cancelBooking(
    TherapistBooking booking,
    String reason,
    S strings,
  ) async {
    try {
      final service = ref.read(therapistBookingServiceProvider);
      await service.cancelBooking(booking.id, reason);

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

  Future<void> _joinSession(TherapistBooking booking) async {
    if (!mounted) return;

    if (booking.sessionType == SessionType.chat) {
      return;
    }

    // Therapist joins as themselves
    final userId = ref.read(authProvider).user?.uid ?? 'therapist';
    final userName = ref.read(authProvider).user?.displayName ?? 'Therapist';

    try {
      // Use Zego built-in call invitation
      final success = await ZegoCallService.instance.sendCallInvitation(
        targetUserId: booking.clientId,
        targetUserName: booking.clientName,
        callID: booking.id,
        callerUserId: userId,
        callerName: userName,
        chatId: booking.id,
        timeoutSeconds: 60,
      );

      if (!success && mounted) {
        final strings = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.errorOccurred),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
