import '../../../core/l10n/language_provider.dart';
import '../../../core/utils/user_display_name.dart';
import '../../../core/utils/sudan_time.dart';
import '../models/therapist_booking.dart';

/// Patient chose bank transfer (Bankak); admin has not confirmed it yet.
bool isTentativeBooking(TherapistBooking b) =>
    b.status == BookingStatus.awaitingPayment &&
    b.paymentStatus == 'bank_transfer_pending';

/// Statuses the therapist should see in lists and on home.
bool isVisibleToTherapist(TherapistBooking b) =>
    b.status != BookingStatus.awaitingPayment || isTentativeBooking(b);

/// A session that is (or may become) real: confirmed, pending or tentative.
bool isActiveSession(TherapistBooking b) =>
    b.status == BookingStatus.confirmed ||
    b.status == BookingStatus.pending ||
    isTentativeBooking(b);

String bookingStatusLabel(TherapistBooking b, S s) {
  if (isTentativeBooking(b)) return s.awaitingPaymentConfirmation;
  switch (b.status) {
    case BookingStatus.awaitingPayment:
      return s.awaitingPayment;
    case BookingStatus.pending:
      return s.pending;
    case BookingStatus.confirmed:
      return s.confirmed;
    case BookingStatus.completed:
      return s.completed;
    case BookingStatus.cancelled:
      return s.cancelled;
    case BookingStatus.rejected:
      return s.rejected;
    case BookingStatus.noShow:
      return s.noShow;
  }
}

bool isSudanToday(DateTime instant, {DateTime? now}) {
  final w = toSudanWallClock(instant);
  final t = sudanToday(now: now);
  return w.year == t.year && w.month == t.month && w.day == t.day;
}

/// Active sessions that have not ended, from today through the next 7 Sudan
/// days, soonest first.
List<TherapistBooking> upcomingSessions(
  List<TherapistBooking> bookings, {
  DateTime? now,
}) {
  final n = (now ?? DateTime.now()).toUtc();
  final today = sudanToday(now: n);
  final lastDay = DateTime(today.year, today.month, today.day + 7);
  final result = bookings.where((b) {
    if (!isActiveSession(b) || !b.endTime.isAfter(n)) return false;
    final w = toSudanWallClock(b.scheduledTime);
    final day = DateTime(w.year, w.month, w.day);
    return !day.isBefore(today) && !day.isAfter(lastDay);
  }).toList()..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  return result;
}

String sessionCardPrefix(TherapistBooking b, S s, {DateTime? now}) {
  final code = s.language.code;
  final time = formatSudanTime(b.scheduledTime, code);
  if (isSudanToday(b.scheduledTime, now: now)) {
    return s.sessionTodayAt.replaceAll('{time}', time);
  }
  return s.sessionOnDateAt
      .replaceAll('{date}', formatSudanDate(b.scheduledTime, code))
      .replaceAll('{time}', time);
}

/// `{chatId}` convention: therapistId_clientId.
String therapistChatIdFor(String therapistId, String clientId) =>
    '${therapistId}_$clientId';

/// Client name for the session card; never the legacy 'User' placeholder.
String sessionClientName(TherapistBooking b, S s) =>
    resolveDisplayName(displayName: b.clientName) ?? s.sessionClientFallback;

/// Segments a list of therapist bookings into upcoming and past.
/// Upcoming:
/// - Active (confirmed + pending + tentative [isTentativeBooking])
/// - scheduledTime >= now - 1 hour
/// - Sorted soonest first (ascending by scheduledTime)
///
/// Past:
/// - Completed, cancelled, rejected, noShow OR scheduledTime < now - 1 hour
/// - Excludes non-tentative awaitingPayment (ghost bookings)
/// - Sorted most recent first (descending by scheduledTime)
({List<TherapistBooking> upcoming, List<TherapistBooking> past})
    segmentTherapistBookings(
  List<TherapistBooking> bookings, {
  DateTime? now,
}) {
  final n = (now ?? DateTime.now()).toUtc();
  final threshold = n.subtract(const Duration(hours: 1));

  final upcoming = <TherapistBooking>[];
  final past = <TherapistBooking>[];

  for (final b in bookings) {
    if (!isVisibleToTherapist(b)) continue;

    final isUpcomingStatus = b.status == BookingStatus.confirmed ||
        b.status == BookingStatus.pending ||
        isTentativeBooking(b);

    if (isUpcomingStatus && !b.scheduledTime.toUtc().isBefore(threshold)) {
      upcoming.add(b);
    } else {
      past.add(b);
    }
  }

  upcoming.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  past.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

  return (upcoming: upcoming, past: past);
}

enum TherapistPaymentBadge {
  paid,
  awaitingConfirmation,
  cancelled,
}

TherapistPaymentBadge therapistBookingPaymentBadge(TherapistBooking b) {
  if (b.status == BookingStatus.cancelled ||
      b.status == BookingStatus.rejected) {
    return TherapistPaymentBadge.cancelled;
  }
  if (isTentativeBooking(b) || b.paymentStatus == 'bank_transfer_pending') {
    return TherapistPaymentBadge.awaitingConfirmation;
  }
  return TherapistPaymentBadge.paid;
}

String therapistBookingPaymentBadgeLabel(TherapistBooking b, S s) {
  switch (therapistBookingPaymentBadge(b)) {
    case TherapistPaymentBadge.paid:
      return s.paidStatus;
    case TherapistPaymentBadge.awaitingConfirmation:
      return s.awaitingPaymentConfirmation;
    case TherapistPaymentBadge.cancelled:
      return s.cancelled;
  }
}

