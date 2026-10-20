import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/services/zego_call_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/sudan_time.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapists/models/therapist.dart';
import '../models/therapist_booking.dart';
import '../services/therapist_booking_service.dart';
import '../utils/session_display.dart';
import '../widgets/bookings_analytics_header.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final allBookingsAsync = ref.watch(therapistBookingsProvider(null));

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: Text(strings.mySessionsTitle)),
      body: SafeArea(
        child: Column(
          children: [
            // Analytics Header
            allBookingsAsync.when(
              data: (bookings) => BookingsAnalyticsHeader(
                data: _generateAnalyticsData(bookings),
              ),
              loading: () => BookingsAnalyticsHeader(
                data: _generateAnalyticsData([]),
              ),
              error: (_, __) => BookingsAnalyticsHeader(
                data: _generateAnalyticsData([]),
              ),
            ),

            // 2 Segments Tab Bar: Upcoming & Past
            Container(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: strings.sessionsUpcoming),
                  Tab(text: strings.sessionsPast),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: allBookingsAsync.when(
                loading: () => LoadingStateWidget(message: strings.loadingData),
                error: (error, stack) => ErrorStateWidget(
                  message: strings.errorLoadingData,
                  retryLabel: strings.retry,
                  onRetry: () => ref.refresh(therapistBookingsProvider(null)),
                ),
                data: (bookings) {
                  final segmented = segmentTherapistBookings(bookings);
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Upcoming segment
                      _buildSessionList(
                        bookings: segmented.upcoming,
                        strings: strings,
                        isDark: isDark,
                        emptyMessage: strings.noUpcomingSessions,
                        emptyIcon: Icons.event_available,
                        isUpcoming: true,
                      ),
                      // Past segment
                      _buildSessionList(
                        bookings: segmented.past,
                        strings: strings,
                        isDark: isDark,
                        emptyMessage: strings.noPastSessions,
                        emptyIcon: Icons.history,
                        isUpcoming: false,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList({
    required List<TherapistBooking> bookings,
    required S strings,
    required bool isDark,
    required String emptyMessage,
    required IconData emptyIcon,
    required bool isUpcoming,
  }) {
    if (bookings.isEmpty) {
      return EmptyStateWidget(
        icon: emptyIcon,
        message: emptyMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(therapistBookingsProvider(null));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSessionCard(
              booking: booking,
              strings: strings,
              isDark: isDark,
              isUpcoming: isUpcoming,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard({
    required TherapistBooking booking,
    required S strings,
    required bool isDark,
    required bool isUpcoming,
  }) {
    final isToday = isSudanToday(booking.scheduledTime);
    final isConfirmed = booking.status == BookingStatus.confirmed;

    return InkWell(
      onTap: () => _openBookingDetail(booking),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : Colors.grey.shade200),
            width: isToday ? 1.5 : 1.0,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client row with avatar, name, and payment badge
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: booking.clientPhotoUrl != null
                      ? NetworkImage(booking.clientPhotoUrl!)
                      : null,
                  child: booking.clientPhotoUrl == null
                      ? Text(
                          booking.clientName.isNotEmpty
                              ? booking.clientName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessionClientName(booking, strings),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(height: 2),
                        Text(
                          strings.today,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildPaymentBadge(booking, strings),
              ],
            ),
            const SizedBox(height: 12),

            // Sudan date & time with label
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 15,
                  color: isDark ? AppColors.textMuted : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  formatSudanDate(booking.scheduledTime, strings.language.code),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.access_time,
                  size: 15,
                  color: isDark ? AppColors.textMuted : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${formatSudanTime(booking.scheduledTime, strings.language.code)} (${strings.sudanTimeLabel})',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Call button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isConfirmed ? () => _joinSession(booking) : null,
                icon: const Icon(Icons.call, size: 18),
                label: Text(strings.callLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? Colors.white12 : Colors.grey.shade200,
                  disabledForegroundColor:
                      isDark ? Colors.white38 : Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(TherapistBooking booking, S strings) {
    final badge = therapistBookingPaymentBadge(booking);
    Color bg;
    Color text;

    switch (badge) {
      case TherapistPaymentBadge.paid:
        bg = Colors.green.shade50;
        text = Colors.green.shade800;
        break;
      case TherapistPaymentBadge.awaitingConfirmation:
        bg = Colors.amber.shade100;
        text = Colors.amber.shade900;
        break;
      case TherapistPaymentBadge.cancelled:
        bg = Colors.grey.shade200;
        text = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        therapistBookingPaymentBadgeLabel(booking, strings),
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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

  void _openBookingDetail(TherapistBooking booking) {
    context.push(
      '${AppRoutes.therapistBookingDetail}/${booking.id}',
      extra: booking,
    );
  }

  Future<void> _joinSession(TherapistBooking booking) async {
    if (!mounted) return;

    if (booking.sessionType == SessionType.chat) {
      return;
    }

    final userId = ref.read(authProvider).user?.uid ?? 'therapist';
    final userName = ref.read(authProvider).user?.displayName ?? 'Therapist';

    try {
      final result = await ZegoCallService.instance.sendCallInvitation(
        targetUserId: booking.clientId,
        targetUserName: booking.clientName,
        callID: booking.id,
        callerUserId: userId,
        callerName: userName,
        chatId: booking.id,
        timeoutSeconds: 60,
      );

      if (!mounted) return;
      final strings = ref.read(stringsProvider);
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${strings.errorOccurred}${result.error != null ? '\n${result.error}' : ''}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      } else if (result.warning != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.warning!),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 6),
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
