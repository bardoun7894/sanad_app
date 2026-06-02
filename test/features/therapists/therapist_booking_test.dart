import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_booking.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';

void main() {
  final now = DateTime(2026, 2, 15, 10, 30);

  group('BookingStatus', () {
    test('has expected values', () {
      expect(BookingStatus.values.length, 7);
      expect(BookingStatus.awaitingPayment.name, 'awaiting_payment');
      expect(BookingStatus.pending.name, 'pending');
      expect(BookingStatus.confirmed.name, 'confirmed');
      expect(BookingStatus.rejected.name, 'rejected');
      expect(BookingStatus.completed.name, 'completed');
      expect(BookingStatus.cancelled.name, 'cancelled');
      expect(BookingStatus.noShow.name, 'no_show');
    });

    test('fromString parses correctly', () {
      expect(BookingStatusX.fromString('pending'), BookingStatus.pending);
      expect(BookingStatusX.fromString('confirmed'), BookingStatus.confirmed);
      expect(BookingStatusX.fromString('rejected'), BookingStatus.rejected);
      expect(BookingStatusX.fromString('completed'), BookingStatus.completed);
      expect(BookingStatusX.fromString('cancelled'), BookingStatus.cancelled);
      expect(BookingStatusX.fromString('no_show'), BookingStatus.noShow);
      expect(BookingStatusX.fromString('unknown'), BookingStatus.pending);
      expect(BookingStatusX.fromString(null), BookingStatus.pending);
    });

    test('isModifiable returns correct state', () {
      expect(BookingStatus.pending.isModifiable, isTrue);
      expect(BookingStatus.confirmed.isModifiable, isTrue);
      expect(BookingStatus.completed.isModifiable, isFalse);
      expect(BookingStatus.cancelled.isModifiable, isFalse);
      expect(BookingStatus.rejected.isModifiable, isFalse);
      expect(BookingStatus.noShow.isModifiable, isFalse);
    });

    test('isTerminal returns correct state', () {
      expect(BookingStatus.completed.isTerminal, isTrue);
      expect(BookingStatus.cancelled.isTerminal, isTrue);
      expect(BookingStatus.noShow.isTerminal, isTrue);
      expect(BookingStatus.rejected.isTerminal, isTrue);
      expect(BookingStatus.pending.isTerminal, isFalse);
      expect(BookingStatus.confirmed.isTerminal, isFalse);
    });
  });
}
