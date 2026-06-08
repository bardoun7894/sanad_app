import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../therapist_portal/models/therapist_booking.dart';
import '../../therapists/models/therapist.dart'; // For SessionType
import '../../therapist_portal/models/therapist_profile.dart';
import '../../therapists/repositories/therapist_repository.dart';
import '../../therapist_chat/models/therapist_chat.dart';
import '../../therapist_chat/providers/therapist_chat_access_provider.dart';
import '../providers/user_booking_provider.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../reviews/providers/review_provider.dart';

// Provider to fetch therapist details for a specific booking
final bookingTherapistProvider =
    FutureProvider.family<TherapistProfile?, String>((ref, therapistId) {
      return ref
          .watch(therapistRepositoryProvider)
          .getTherapistById(therapistId);
    });

class UserBookingsScreen extends ConsumerStatefulWidget {
  final bool embed; // Control if it should show scaffold
  const UserBookingsScreen({super.key, this.embed = false});

  @override
  ConsumerState<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends ConsumerState<UserBookingsScreen>
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
    if (widget.embed) {
      return _UserBookingsContent(tabController: _tabController);
    }

    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          s.myBookings, // "My Sessions" / "حجوزاتي"
          style: AppTypography.headingLarge.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              height: 52,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFF1F5F9), // Slate-100
                borderRadius: BorderRadius.circular(26), // Pill shape
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: isDark ? const Color(0xFF374151) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: isDark ? Colors.white : AppColors.primary,
                unselectedLabelColor: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Tajawal',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Tajawal',
                ),
                tabs: [
                  Tab(text: s.upcoming), // "Upcoming" / "القادمة"
                  Tab(text: s.tabHistory), // "History" / "التاريخ"
                ],
              ),
            ),
          ),
          Expanded(child: _UserBookingsContent(tabController: _tabController)),
        ],
      ),
    );
  }
}

class _UserBookingsContent extends StatelessWidget {
  final TabController tabController;

  const _UserBookingsContent({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: const [_UpcomingBookingsList(), _PastBookingsList()],
    );
  }
}

class _UpcomingBookingsList extends ConsumerWidget {
  const _UpcomingBookingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userUpcomingBookingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S(ref.watch(languageProvider).language);

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.calendar_month_rounded,
            message: s.noUpcomingSessions,
            description: s.scheduledSessionsAppearHere,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ), // More padding
          itemCount: bookings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            return _UserBookingCard(booking: bookings[index]);
          },
        );
      },
      loading: () => LoadingStateWidget(message: s.loadingData),
      error: (error, stack) => ErrorStateWidget(
        message: s.errorLoadingData,
        retryLabel: s.retry,
        onRetry: () => ref.invalidate(userUpcomingBookingsProvider),
      ),
    );
  }
}

class _PastBookingsList extends ConsumerWidget {
  const _PastBookingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userPastBookingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S(ref.watch(languageProvider).language);

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.history_rounded,
            message: s.noSessionHistory,
            description: s.pastSessionsArchivedHere,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: bookings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            return _UserBookingCard(booking: bookings[index], isPast: true);
          },
        );
      },
      loading: () => LoadingStateWidget(message: s.loadingData),
      error: (error, stack) => ErrorStateWidget(
        message: s.errorLoadingData,
        retryLabel: s.retry,
        onRetry: () => ref.invalidate(userPastBookingsProvider),
      ),
    );
  }
}

class _UserBookingCard extends ConsumerWidget {
  final TherapistBooking booking;
  final bool isPast;

  const _UserBookingCard({required this.booking, this.isPast = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S(ref.watch(languageProvider).language);

    // Fetch therapist details
    final therapistAsync = ref.watch(
      bookingTherapistProvider(booking.therapistId),
    );
    // Payment-aware access gate — while loading, treat as full to avoid
    // false-negative flash for paying users.
    final chatAccess = ref
            .watch(therapistChatAccessProvider(booking.therapistId))
            .valueOrNull ??
        TherapistChatAccess.full;

    return Container(
      // Changed from Card to Container for detailed control
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937)
            : Colors.white, // Slate-800/White
        borderRadius: BorderRadius.circular(24), // Softer corners
        border: Border.all(
          color: isDark
              ? const Color(0xFF374151)
              : const Color(0xFFE2E8F0), // Slate-700/200
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? 0.2 : 0.05,
            ), // Very subtle shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (chatAccess == TherapistChatAccess.none) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.chatLockedPayPrompt)),
                );
                return;
              }
              // Navigate to chat
              final chatId = TherapistChatThread.generateChatId(
                booking.therapistId,
                booking.clientId,
              );

              context.pushNamed(
                'userTherapistChat',
                pathParameters: {'chatId': chatId},
                extra: TherapistChatThread(
                  chatId: chatId,
                  therapistId: booking.therapistId,
                  userId: booking.clientId,
                  therapistName: therapistAsync.value?.name ?? s.therapist,
                  therapistPhotoUrl: therapistAsync.value?.photoUrl,
                  userName: booking.clientName,
                  source: ChatSource.booking,
                  bookingId: booking.id,

                  // Required fields for model, using safe defaults
                  bookingIds: [booking.id],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20), // Spacious padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Status Badge + Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(
                          booking.status, isDark, s, booking.paymentStatus),

                      // Date Display
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                DateFormat(
                                  'EEE, MMM d',
                                ).format(booking.scheduledTime),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(
                                          0xFF475569,
                                        ), // Slate-300/600
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'h:mm a',
                              ).format(booking.scheduledTime),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Middle: Therapist Info & Session Type
                  Row(
                    children: [
                      // Avatar with Status Ring
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFF1F5F9),
                            width: 2,
                          ),
                        ),
                        child: Builder(
                          builder: (context) {
                            final photoUrl = therapistAsync.value?.photoUrl;
                            return Container(
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Colors.grey[300]
                                    : AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                image: photoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(photoUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: photoUrl == null
                                  ? Center(
                                      child: Text(
                                        therapistAsync.value?.name.isNotEmpty ==
                                                true
                                            ? therapistAsync.value!.name[0]
                                                  .toUpperCase()
                                            : 'T',
                                        style: TextStyle(
                                          color: isPast
                                              ? Colors.grey
                                              : AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            therapistAsync.when(
                              data: (therapist) => Text(
                                therapist?.name ?? s.therapist,
                                style: AppTypography.headingSmall.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              loading: () => Container(
                                width: 100,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              error: (error, stack) => Text(s.therapist),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _getSessionIcon(booking.sessionType),
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getSessionTypeLabel(booking.sessionType, s),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      if (!isPast)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),

                  // Rating row — only for completed sessions
                  if (booking.status == BookingStatus.completed) ...[
                    const SizedBox(height: 16),
                    _BookingRatingRow(
                      booking: booking,
                      therapistName: therapistAsync.value?.name ?? s.therapist,
                      therapistPhoto: therapistAsync.value?.photoUrl,
                      therapistReviewCount: therapistAsync.value?.reviewCount,
                      isDark: isDark,
                    ),
                  ],

                  // Read-only hint — therapist initiates the call at session time.
                  if (!isPast &&
                      booking.status == BookingStatus.confirmed &&
                      booking.sessionType != SessionType.chat) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.therapistWillCallYou,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status, bool isDark, S s,
      [String? paymentStatus]) {
    Color color;
    Color bgColor;
    String label = _getStatusLabel(status, s);

    // A bank-transfer request that's been sent and is awaiting admin
    // confirmation — distinct from a not-yet-paid booking.
    final isBankTransferPending = status == BookingStatus.awaitingPayment &&
        paymentStatus == 'bank_transfer_pending';
    if (isBankTransferPending) {
      label = s.awaitingPaymentConfirmation;
    }

    switch (status) {
      case BookingStatus.awaitingPayment:
        color = isBankTransferPending ? Colors.blue : Colors.amber;
        bgColor = color.withValues(alpha: 0.1);
        break;
      case BookingStatus.pending:
        color = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case BookingStatus.confirmed:
        color = const Color(0xFF22C55E); // Green-500
        bgColor = const Color(0xFF22C55E).withValues(alpha: 0.1);
        break;
      case BookingStatus.completed:
        color = Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.1);
        break;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
        color = const Color(0xFFEF4444); // Red-500
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        break;
      case BookingStatus.noShow:
        color = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color, // Uses the solid color
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(BookingStatus status, S s) {
    switch (status) {
      case BookingStatus.awaitingPayment:
        return s.awaitingPayment;
      case BookingStatus.pending:
        return s.pending;
      case BookingStatus.confirmed:
        return s.confirmed;
      case BookingStatus.rejected:
        return s.rejected;
      case BookingStatus.completed:
        return s.completed;
      case BookingStatus.cancelled:
        return s.cancelled;
      case BookingStatus.noShow:
        return s.noShow;
    }
  }

  String _getSessionTypeLabel(SessionType type, S s) {
    switch (type) {
      case SessionType.audio:
        return s.sessionAudio;
      case SessionType.chat:
        return s.sessionChat;
      case SessionType.inPerson:
        return s.sessionInPerson;
    }
  }

  IconData _getSessionIcon(SessionType type) {
    switch (type) {
      case SessionType.audio:
        return Icons.phone_rounded;
      case SessionType.chat:
        return Icons.chat_bubble_rounded;
      case SessionType.inPerson:
        return Icons.person_rounded;
    }
  }
}

/// Stars-only rating row shown on completed bookings.
/// Tapping a star opens the leave-review screen.
class _BookingRatingRow extends ConsumerWidget {
  final TherapistBooking booking;
  final String therapistName;
  final String? therapistPhoto;
  final int? therapistReviewCount;
  final bool isDark;

  const _BookingRatingRow({
    required this.booking,
    required this.therapistName,
    required this.therapistPhoto,
    required this.therapistReviewCount,
    required this.isDark,
  });

  void _openReview(BuildContext context) {
    context.pushNamed(
      'leaveReview',
      extra: {
        'bookingId': booking.id,
        'therapistId': booking.therapistId,
        'therapistName': therapistName,
        'therapistPhoto': therapistPhoto,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(bookingReviewProvider(booking.id));

    return reviewAsync.when(
      loading: () => const SizedBox(
        height: 24,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (review) {
        final hasReview = review != null;
        final displayRating = review?.rating ?? 0.0;

        final stars = Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isFull = displayRating >= starNumber;
            final isHalf =
                displayRating >= starNumber - 0.5 && displayRating < starNumber;
            IconData icon;
            if (isFull) {
              icon = Icons.star_rounded;
            } else if (isHalf) {
              icon = Icons.star_half_rounded;
            } else {
              icon = Icons.star_border_rounded;
            }
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 2),
              child: Icon(
                icon,
                size: 22,
                color: (isFull || isHalf)
                    ? Colors.amber
                    : (isDark ? Colors.white24 : Colors.grey.shade400),
              ),
            );
          }),
        );

        final countLabel = (therapistReviewCount != null &&
                therapistReviewCount! > 0)
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Text(
                  '($therapistReviewCount)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : const SizedBox.shrink();

        return InkWell(
          onTap: hasReview ? null : () => _openReview(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                stars,
                countLabel,
              ],
            ),
          ),
        );
      },
    );
  }
}
