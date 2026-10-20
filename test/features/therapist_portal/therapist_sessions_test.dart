import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/core/services/notification_routing.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_booking.dart';
import 'package:sanad_app/features/therapist_portal/utils/session_display.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';
import 'package:sanad_app/routes/app_routes.dart';

TherapistBooking booking({
  String id = 'b1',
  BookingStatus status = BookingStatus.confirmed,
  String? paymentStatus,
  required DateTime at,
  String clientName = 'سارة',
}) => TherapistBooking(
  id: id,
  therapistId: 't1',
  clientId: 'c1',
  clientName: clientName,
  scheduledTime: at,
  sessionType: SessionType.audio,
  status: status,
  amount: 10,
  createdAt: DateTime.utc(2026, 10, 1),
  paymentStatus: paymentStatus,
);

void main() {
  final ar = S(AppLanguage.arabic);
  // 2026-10-18 14:00 UTC = 16:00 Sudan
  final now = DateTime.utc(2026, 10, 18, 8);

  group('tentative / labels', () {
    test('awaiting_payment + bank_transfer_pending is tentative', () {
      final b = booking(
        status: BookingStatus.awaitingPayment,
        paymentStatus: 'bank_transfer_pending',
        at: now,
      );
      expect(isTentativeBooking(b), isTrue);
      expect(bookingStatusLabel(b, ar), 'بانتظار تأكيد الدفع');
      expect(bookingStatusLabel(b, ar), isNot('ملغاة'));
    });

    test('plain awaiting_payment is not tentative and not shown', () {
      final b = booking(status: BookingStatus.awaitingPayment, at: now);
      expect(isTentativeBooking(b), isFalse);
      expect(isVisibleToTherapist(b), isFalse);
    });

    test('confirmed, pending and tentative are visible; cancelled is not a session', () {
      expect(isVisibleToTherapist(booking(at: now)), isTrue);
      expect(
        isVisibleToTherapist(booking(status: BookingStatus.pending, at: now)),
        isTrue,
      );
      expect(
        isVisibleToTherapist(booking(
          status: BookingStatus.awaitingPayment,
          paymentStatus: 'bank_transfer_pending',
          at: now,
        )),
        isTrue,
      );
      expect(isActiveSession(booking(status: BookingStatus.cancelled, at: now)), isFalse);
      expect(isActiveSession(booking(status: BookingStatus.rejected, at: now)), isFalse);
    });

    test('confirmed label is not cancelled', () {
      expect(bookingStatusLabel(booking(at: now), ar), ar.confirmed);
    });
  });

  group('upcoming window (Sudan days)', () {
    test('today first, then next 7 days, excludes day 8, past and cancelled', () {
      final today = booking(id: 'today', at: DateTime.utc(2026, 10, 18, 14));
      final d7 = booking(id: 'd7', at: DateTime.utc(2026, 10, 25, 14));
      final d8 = booking(id: 'd8', at: DateTime.utc(2026, 10, 26, 14));
      final past = booking(id: 'past', at: DateTime.utc(2026, 10, 18, 5));
      final cancelled = booking(
        id: 'x',
        status: BookingStatus.cancelled,
        at: DateTime.utc(2026, 10, 19, 14),
      );
      final r = upcomingSessions([d7, cancelled, d8, past, today], now: now);
      expect(r.map((b) => b.id), ['today', 'd7']);
    });

    test('late-evening UTC booking falls on the next Sudan day', () {
      // 23:00 UTC on the 18th = 01:00 Sudan on the 19th -> not "today"
      final b = booking(at: DateTime.utc(2026, 10, 18, 23));
      expect(isSudanToday(b.scheduledTime, now: now), isFalse);
    });
  });

  group('session card text', () {
    test('today (Arabic) states Sudan time', () {
      final b = booking(at: DateTime.utc(2026, 10, 18, 14));
      expect(
        sessionCardPrefix(b, ar, now: now),
        'لديك جلسة اليوم الساعة 4:00 مساءً بتوقيت السودان مع',
      );
    });

    test('later date includes the Sudan date', () {
      final b = booking(at: DateTime.utc(2026, 10, 20, 14));
      expect(
        sessionCardPrefix(b, ar, now: now),
        'لديك جلسة بتاريخ 20 أكتوبر 2026 الساعة 4:00 مساءً بتوقيت السودان مع',
      );
    });

    test('client name never shows the User placeholder', () {
      expect(sessionClientName(booking(at: now, clientName: 'User'), ar), isNot('User'));
      expect(sessionClientName(booking(at: now, clientName: 'سارة'), ar), 'سارة');
    });
  });

  group('therapist bookings segmentation and badges', () {
    test('upcoming includes confirmed, pending, tentative within now - 1h, sorted soonest first', () {
      final bFar = booking(id: 'bFar', at: now.add(const Duration(hours: 5)));
      final bSoon = booking(id: 'bSoon', at: now.add(const Duration(hours: 1)));
      final bTentative = booking(
        id: 'bTentative',
        status: BookingStatus.awaitingPayment,
        paymentStatus: 'bank_transfer_pending',
        at: now.add(const Duration(hours: 2)),
      );
      final bPending = booking(
        id: 'bPending',
        status: BookingStatus.pending,
        at: now.add(const Duration(minutes: 30)),
      );
      final bWithinHourAgo = booking(
        id: 'bWithinHourAgo',
        at: now.subtract(const Duration(minutes: 45)),
      );
      final bTooOld = booking(
        id: 'bTooOld',
        at: now.subtract(const Duration(minutes: 75)),
      );
      final bCompleted = booking(
        id: 'bCompleted',
        status: BookingStatus.completed,
        at: now.add(const Duration(hours: 1)),
      );
      final bCancelled = booking(
        id: 'bCancelled',
        status: BookingStatus.cancelled,
        at: now.add(const Duration(hours: 1)),
      );

      final result = segmentTherapistBookings(
        [bFar, bTooOld, bCompleted, bSoon, bTentative, bCancelled, bPending, bWithinHourAgo],
        now: now,
      );

      expect(
        result.upcoming.map((b) => b.id).toList(),
        ['bWithinHourAgo', 'bPending', 'bSoon', 'bTentative', 'bFar'],
      );

      expect(
        result.past.map((b) => b.id).toList(),
        containsAll(['bTooOld', 'bCompleted', 'bCancelled']),
      );
    });

    test('completed session leaves upcoming and enters past', () {
      final b = booking(id: 'b1', status: BookingStatus.completed, at: now.add(const Duration(hours: 2)));
      final result = segmentTherapistBookings([b], now: now);
      expect(result.upcoming, isEmpty);
      expect(result.past.map((e) => e.id), ['b1']);
    });

    test('payment badges classify correctly', () {
      final paidBooking = booking(status: BookingStatus.confirmed, at: now);
      expect(therapistBookingPaymentBadge(paidBooking), TherapistPaymentBadge.paid);
      expect(therapistBookingPaymentBadgeLabel(paidBooking, ar), 'مدفوع');

      final tentativeBooking = booking(
        status: BookingStatus.awaitingPayment,
        paymentStatus: 'bank_transfer_pending',
        at: now,
      );
      expect(
        therapistBookingPaymentBadge(tentativeBooking),
        TherapistPaymentBadge.awaitingConfirmation,
      );
      expect(
        therapistBookingPaymentBadgeLabel(tentativeBooking, ar),
        'بانتظار تأكيد الدفع',
      );

      final cancelledBooking = booking(status: BookingStatus.cancelled, at: now);
      expect(
        therapistBookingPaymentBadge(cancelledBooking),
        TherapistPaymentBadge.cancelled,
      );
      expect(
        therapistBookingPaymentBadgeLabel(cancelledBooking, ar),
        'ملغاة',
      );
    });
  });

  group('therapist chat id and FCM routing', () {
    test('chat id convention', () {
      expect(therapistChatIdFor('t1', 'c1'), 't1_c1');
    });

    test('therapist recipient + bookingId opens booking detail', () {
      for (final t in [
        'new_booking',
        'booking_confirmed',
        'booking_cancelled',
        'booking_reminder',
      ]) {
        expect(
          therapistNotificationRoute({
            'type': t,
            'recipientRole': 'therapist',
            'bookingId': 'b123',
            'chatId': 't1_c1',
          }),
          '${AppRoutes.therapistBookingDetail}/b123',
        );
      }
    });

    test('therapist recipient without bookingId falls back to therapistBookings', () {
      expect(
        therapistNotificationRoute({
          'type': 'new_booking',
          'recipientRole': 'therapist',
          'chatId': 't1_c1',
        }),
        AppRoutes.therapistBookings,
      );
    });

    test('accepts snake_case keys for booking_id and recipient_role', () {
      expect(
        therapistNotificationRoute({
          'type': 'new_booking',
          'recipient_role': 'therapist',
          'booking_id': 'b456',
        }),
        '${AppRoutes.therapistBookingDetail}/b456',
      );
    });

    test('other roles or non-booking types keep default behaviour (null)', () {
      expect(
        therapistNotificationRoute({'type': 'new_booking', 'bookingId': 'b123'}),
        isNull,
      );
      expect(
        therapistNotificationRoute({
          'type': 'community',
          'recipientRole': 'therapist',
          'bookingId': 'b123',
        }),
        isNull,
      );
    });
  });
}
