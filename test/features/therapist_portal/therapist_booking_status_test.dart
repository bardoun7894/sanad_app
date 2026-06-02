import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_booking.dart';

void main() {
  group('BookingStatus.awaitingPayment', () {
    test('fromString returns awaitingPayment for "awaiting_payment"', () {
      expect(
        BookingStatusX.fromString('awaiting_payment'),
        BookingStatus.awaitingPayment,
      );
    });

    test('name getter returns "awaiting_payment"', () {
      expect(BookingStatus.awaitingPayment.name, 'awaiting_payment');
    });

    test('isModifiable is false — therapist cannot act on unpaid bookings', () {
      expect(BookingStatus.awaitingPayment.isModifiable, false);
    });

    test('isTerminal is false — awaiting payment is not a terminal state', () {
      expect(BookingStatus.awaitingPayment.isTerminal, false);
    });

    test('legacy default still maps unknown strings to pending', () {
      expect(BookingStatusX.fromString('unknown_value'), BookingStatus.pending);
      expect(BookingStatusX.fromString(null), BookingStatus.pending);
    });
  });
}
