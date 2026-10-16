import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapists/services/booking_service.dart';

void main() {
  final date = DateTime(2026, 10, 18);

  test('generates 3 fixed slots 19,20,21 Sudan', () {
    final slots = generateSudanSlots(date, {});
    expect(slots.length, 3);
    expect(slots.map((s) => s.startTime), [
      DateTime.utc(2026, 10, 18, 17),
      DateTime.utc(2026, 10, 18, 18),
      DateTime.utc(2026, 10, 18, 19),
    ]);
    expect(slots.first.endTime.difference(slots.first.startTime).inMinutes, 60);
    expect(slots.map((s) => s.formattedTime), ['7:00 PM', '8:00 PM', '9:00 PM']);
  });

  test('removes taken instants', () {
    final slots = generateSudanSlots(date, {DateTime.utc(2026, 10, 18, 18)});
    expect(slots.length, 2);
    expect(slots.any((s) => s.startTime == DateTime.utc(2026, 10, 18, 18)), isFalse);
  });

  group('isBookingTaken', () {
    final now = DateTime.utc(2026, 10, 16, 12);
    test('pending/confirmed taken', () {
      expect(isBookingTaken(status: 'pending', paymentStatus: 'paid', paymentDeadline: null, now: now), isTrue);
      expect(isBookingTaken(status: 'confirmed', paymentStatus: 'paid', paymentDeadline: null, now: now), isTrue);
    });
    test('awaiting_payment bank_transfer_pending taken', () {
      expect(isBookingTaken(status: 'awaiting_payment', paymentStatus: 'bank_transfer_pending', paymentDeadline: DateTime.utc(2026, 10, 1), now: now), isTrue);
    });
    test('awaiting_payment taken only before deadline', () {
      expect(isBookingTaken(status: 'awaiting_payment', paymentStatus: 'awaiting_payment', paymentDeadline: DateTime.utc(2026, 10, 17), now: now), isTrue);
      expect(isBookingTaken(status: 'awaiting_payment', paymentStatus: 'awaiting_payment', paymentDeadline: DateTime.utc(2026, 10, 15), now: now), isFalse);
      expect(isBookingTaken(status: 'awaiting_payment', paymentStatus: 'awaiting_payment', paymentDeadline: null, now: now), isFalse);
    });
    test('cancelled/completed not taken', () {
      expect(isBookingTaken(status: 'cancelled', paymentStatus: 'paid', paymentDeadline: null, now: now), isFalse);
      expect(isBookingTaken(status: 'rejected', paymentStatus: null, paymentDeadline: null, now: now), isFalse);
    });
  });

  test('earliest bookable instant is Sudan today+2 at 19:00', () {
    final e = earliestBookableInstant(now: DateTime.utc(2026, 10, 16, 12));
    expect(e, DateTime.utc(2026, 10, 18, 17));
  });
}
