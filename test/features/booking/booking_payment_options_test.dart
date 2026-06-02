// test/features/booking/booking_payment_options_test.dart
//
// TDD: verifies the payment options on BookingPaymentScreen.
//
// Bank transfer is shown but locked by default (requires admin unlock).
// See bank_transfer_unlock_test.dart for full lock/unlock behaviour tests.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/booking/providers/booking_unlock_provider.dart';
import 'package:sanad_app/features/booking/screens/booking_payment_screen.dart';
import 'package:sanad_app/features/therapists/services/booking_service.dart';

BookingService _fakeBookingService() =>
    BookingService(firestore: FakeFirebaseFirestore());

Widget _buildScreen({AppLanguage language = AppLanguage.english}) {
  return ProviderScope(
    overrides: [
      bookingServiceProvider.overrideWithValue(_fakeBookingService()),
      // Locked by default — admin has not unlocked
      bankTransferUnlockedProvider('booking-test-1').overrideWith(
        (ref) => Stream.value(false),
      ),
      languageProvider.overrideWith(
        (ref) => LanguageNotifier()..setLanguage(language),
      ),
    ],
    child: MaterialApp(
      home: BookingPaymentScreen(
        bookingId: 'booking-test-1',
        amount: 150.0,
        currency: 'USD',
        therapistName: 'Dr. Test',
        paymentDeadline: DateTime.now().add(const Duration(hours: 24)),
      ),
    ),
  );
}

void main() {
  group('BookingPaymentScreen – payment options', () {
    testWidgets('shows bank transfer option in locked state (EN)',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      // Bank transfer is shown (but locked — not removed)
      expect(find.textContaining('Bank Transfer'), findsWidgets);
    });

    testWidgets('shows bank transfer option in Arabic when locked',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookingServiceProvider.overrideWithValue(_fakeBookingService()),
            bankTransferUnlockedProvider('booking-test-2').overrideWith(
              (ref) => Stream.value(false),
            ),
            languageProvider.overrideWith(
              (ref) => LanguageNotifier()..setLanguage(AppLanguage.arabic),
            ),
          ],
          child: MaterialApp(
            home: BookingPaymentScreen(
              bookingId: 'booking-test-2',
              amount: 150.0,
              currency: 'USD',
              therapistName: 'Dr. Test',
              paymentDeadline: DateTime.now().add(const Duration(hours: 24)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('تحويل'), findsWidgets);
    });

    testWidgets('shows lock icon on bank transfer when locked', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('still shows PayPal option', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('PayPal'), findsOneWidget);
    });
  });
}
