// test/features/admin/booking_detail_sheet_test.dart
//
// TDD: verifies the "Unlock Bank Transfer" admin action in BookingDetailSheet.
//   1. Button is visible when bank_transfer_unlocked == false.
//   2. A "locked" badge replaces the button when already unlocked.
//   3. Tapping the button → confirm dialog → calls unlockBankTransfer.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/widgets/booking_detail_sheet.dart';
import 'package:sanad_app/features/booking/providers/booking_unlock_provider.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_booking.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';
import 'package:sanad_app/features/therapists/services/booking_service.dart';

// ---------------------------------------------------------------------------
// Stub booking
// ---------------------------------------------------------------------------

TherapistBooking _stubBooking({String id = 'bk-admin-1'}) => TherapistBooking(
  id: id,
  therapistId: 't-1',
  clientId: 'u-1',
  clientName: 'Alice',
  scheduledTime: DateTime.now().add(const Duration(days: 1)),
  sessionType: SessionType.chat,
  amount: 150.0,
  createdAt: DateTime.now(),
);

// ---------------------------------------------------------------------------
// Build helper — wraps sheet in Material + ProviderScope
// ---------------------------------------------------------------------------

Widget _buildSheet({
  required bool unlocked,
  required BookingService bookingService,
  String bookingId = 'bk-admin-1',
}) {
  return ProviderScope(
    overrides: [
      bookingServiceProvider.overrideWithValue(bookingService),
      bankTransferUnlockedProvider(bookingId).overrideWith(
        (ref) => Stream.value(unlocked),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: BookingDetailSheet(
          booking: _stubBooking(id: bookingId),
          isDark: false,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Fake BookingService that records calls to unlockBankTransfer
// ---------------------------------------------------------------------------

class _SpyBookingService extends BookingService {
  _SpyBookingService() : super(firestore: FakeFirebaseFirestore());

  bool unlockCalled = false;
  String? unlockedBookingId;

  @override
  Future<void> unlockBankTransfer(String bookingId) async {
    unlockCalled = true;
    unlockedBookingId = bookingId;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BookingDetailSheet – Unlock Bank Transfer', () {
    testWidgets('shows "Unlock Bank Transfer" button when locked',
        (tester) async {
      await tester.pumpWidget(
        _buildSheet(
          unlocked: false,
          bookingService: _SpyBookingService(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Unlock Bank Transfer'), findsOneWidget);
    });

    testWidgets('shows unlocked state badge when already unlocked',
        (tester) async {
      await tester.pumpWidget(
        _buildSheet(
          unlocked: true,
          bookingService: _SpyBookingService(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Bank Transfer Unlocked'), findsOneWidget);
      expect(find.textContaining('Unlock Bank Transfer'), findsNothing);
    });

    testWidgets('tapping button then confirming calls unlockBankTransfer',
        (tester) async {
      final spy = _SpyBookingService();

      await tester.pumpWidget(
        _buildSheet(unlocked: false, bookingService: spy),
      );
      await tester.pumpAndSettle();

      // Tap the unlock button
      await tester.tap(find.textContaining('Unlock Bank Transfer'));
      await tester.pumpAndSettle();

      // Confirm dialog appears — tap the confirm action
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(spy.unlockCalled, isTrue);
      expect(spy.unlockedBookingId, equals('bk-admin-1'));
    });

    testWidgets('tapping button then cancelling does NOT call unlockBankTransfer',
        (tester) async {
      final spy = _SpyBookingService();

      await tester.pumpWidget(
        _buildSheet(unlocked: false, bookingService: spy),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Unlock Bank Transfer'));
      await tester.pumpAndSettle();

      // Cancel in the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(spy.unlockCalled, isFalse);
    });
  });
}
