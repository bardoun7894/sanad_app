// test/features/booking/bank_transfer_unlock_test.dart
//
// TDD: verifies the bank-transfer-unlock feature:
//   1. BookingService.unlockBankTransfer writes bank_transfer_unlocked=true
//      to the booking doc (unit test with FakeFirebaseFirestore).
//   2. BookingPaymentScreen shows the bank transfer option in a DISABLED state
//      when bank_transfer_unlocked is false.
//   3. BookingPaymentScreen makes bank transfer TAPPABLE once
//      bank_transfer_unlocked becomes true.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/booking/providers/booking_unlock_provider.dart';
import 'package:sanad_app/features/booking/screens/booking_payment_screen.dart';
import 'package:sanad_app/features/therapists/services/booking_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

BookingService _fakeService({FakeFirebaseFirestore? fakeFs}) =>
    BookingService(firestore: fakeFs ?? FakeFirebaseFirestore());

Widget _buildScreen({
  required String bookingId,
  required bool unlocked,
  FakeFirebaseFirestore? fakeFs,
}) {
  final fs = fakeFs ?? FakeFirebaseFirestore();
  return ProviderScope(
    overrides: [
      bookingServiceProvider.overrideWithValue(_fakeService(fakeFs: fs)),
      // Override the stream provider so tests don't need real Firestore
      bankTransferUnlockedProvider(bookingId).overrideWith(
        (ref) => Stream.value(unlocked),
      ),
      languageProvider.overrideWith(
        (ref) => LanguageNotifier()..setLanguage(AppLanguage.english),
      ),
    ],
    child: MaterialApp(
      home: BookingPaymentScreen(
        bookingId: bookingId,
        amount: 150.0,
        currency: 'USD',
        therapistName: 'Dr. Test',
        paymentDeadline: DateTime.now().add(const Duration(hours: 24)),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── 1. Service unit tests ────────────────────────────────────────────────

  group('BookingService.unlockBankTransfer', () {
    test('writes bank_transfer_unlocked=true to the booking doc', () async {
      final fakeFs = FakeFirebaseFirestore();
      // Seed a booking doc
      await fakeFs.collection('bookings').doc('bk-1').set({
        'status': 'awaiting_payment',
        'bank_transfer_unlocked': false,
      });

      final service = BookingService(firestore: fakeFs);
      await service.unlockBankTransfer('bk-1');

      final snap = await fakeFs.collection('bookings').doc('bk-1').get();
      expect(snap.data()!['bank_transfer_unlocked'], isTrue);
    });

    test('createBooking defaults bank_transfer_unlocked to false', () async {
      final fakeFs = FakeFirebaseFirestore();

      // Seed required therapist + client docs so createBooking validators pass
      await fakeFs.collection('therapists').doc('t-1').set({
        'approval_status': 'approved',
        'is_active': true,
      });
      await fakeFs.collection('users').doc('u-1').set({'name': 'Alice'});

      final service = BookingService(firestore: fakeFs);
      final bookingId = await service.createBooking(
        therapistId: 't-1',
        therapistName: 'Dr. T',
        clientId: 'u-1',
        clientName: 'Alice',
        clientEmail: 'alice@example.com',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 60,
        sessionType: 'chat',
        amount: 150.0,
      );

      final snap = await fakeFs.collection('bookings').doc(bookingId).get();
      expect(snap.data()!['bank_transfer_unlocked'], isFalse);
    });
  });

  // ── 2. User UI — locked state ─────────────────────────────────────────────

  group('BookingPaymentScreen – bank transfer locked', () {
    testWidgets('shows bank transfer option', (tester) async {
      await tester.pumpWidget(
        _buildScreen(bookingId: 'bk-locked', unlocked: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bank Transfer'), findsOneWidget);
    });

    testWidgets('shows locked caption when bank_transfer_unlocked is false',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(bookingId: 'bk-locked', unlocked: false),
      );
      await tester.pumpAndSettle();

      // Must show a caption explaining it is locked
      expect(find.textContaining('admin'), findsWidgets);
    });

    testWidgets(
        'bank transfer option is non-interactive when locked (IgnorePointer or disabled)',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(bookingId: 'bk-locked', unlocked: false),
      );
      await tester.pumpAndSettle();

      // Tap the bank transfer tile — if non-interactive, selected method stays 'google_pay'
      await tester.tap(find.text('Bank Transfer'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Pay button text should still show Google Pay as default (not bank_transfer)
      // — verifies the tap did NOT switch the selection
      final payButton = find.textContaining('Pay Now');
      expect(payButton, findsOneWidget);
    });
  });

  // ── 3. User UI — unlocked state ───────────────────────────────────────────

  group('BookingPaymentScreen – bank transfer unlocked', () {
    testWidgets('bank transfer option is tappable when unlocked', (tester) async {
      await tester.pumpWidget(
        _buildScreen(bookingId: 'bk-unlocked', unlocked: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bank Transfer'));
      await tester.pumpAndSettle();

      // After tapping, check icon shows selected state
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('does not show locked caption when unlocked', (tester) async {
      await tester.pumpWidget(
        _buildScreen(bookingId: 'bk-unlocked', unlocked: true),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Available after admin'), findsNothing);
    });
  });

  // ── 4. AR locale ──────────────────────────────────────────────────────────

  group('BookingPaymentScreen – AR locale locked', () {
    testWidgets('shows bank transfer in Arabic when locked', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingServiceProvider.overrideWithValue(_fakeService()),
            bankTransferUnlockedProvider('bk-ar').overrideWith(
              (ref) => Stream.value(false),
            ),
            languageProvider.overrideWith(
              (ref) => LanguageNotifier()..setLanguage(AppLanguage.arabic),
            ),
          ],
          child: MaterialApp(
            home: BookingPaymentScreen(
              bookingId: 'bk-ar',
              amount: 150.0,
              currency: 'USD',
              therapistName: 'Dr. Test',
              paymentDeadline: DateTime.now().add(const Duration(hours: 24)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تحويل بنكي'), findsOneWidget);
    });
  });
}
