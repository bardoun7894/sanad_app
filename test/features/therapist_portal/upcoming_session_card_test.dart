import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_booking.dart';
import 'package:sanad_app/features/therapist_portal/widgets/upcoming_session_card.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';

TherapistBooking _b({
  BookingStatus status = BookingStatus.confirmed,
  String? pay,
}) =>
    TherapistBooking(
      id: 'b1',
      therapistId: 't1',
      clientId: 'c1',
      clientName: 'سارة',
      scheduledTime: DateTime.utc(2026, 10, 18, 14),
      sessionType: SessionType.audio,
      status: status,
      amount: 10,
      createdAt: DateTime.utc(2026, 10, 1),
      paymentStatus: pay,
    );

Future<void> _pump(
  WidgetTester t,
  TherapistBooking b, {
  VoidCallback? onTap,
  VoidCallback? onCall,
}) =>
    t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: UpcomingSessionCard(
              booking: b,
              onTap: onTap,
              onCall: onCall,
              now: DateTime.utc(2026, 10, 18, 8),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets(
    'shows Sudan-time sentence, client name, onTap opens detail, enabled call button when confirmed',
    (t) async {
      var cardTaps = 0;
      var callTaps = 0;
      await _pump(
        t,
        _b(),
        onTap: () => cardTaps++,
        onCall: () => callTaps++,
      );

      expect(
        find.textContaining('لديك جلسة اليوم الساعة 4:00 مساءً بتوقيت السودان مع'),
        findsOneWidget,
      );
      expect(find.text('سارة'), findsOneWidget);
      expect(find.text('بانتظار تأكيد الدفع'), findsNothing);

      // Prominent call button is present and enabled
      final callButtonFinder = find.byKey(
        const Key('upcoming_session_call_button'),
      );
      expect(callButtonFinder, findsOneWidget);
      final buttonWidget = t.widget<ElevatedButton>(callButtonFinder);
      expect(buttonWidget.onPressed, isNotNull);

      await t.tap(callButtonFinder);
      expect(callTaps, 1);
      expect(cardTaps, 0);

      // Tapping card triggers onTap (booking detail)
      await t.tap(find.byType(UpcomingSessionCard));
      expect(cardTaps, 1);
    },
  );

  testWidgets(
    'tentative booking shows the awaiting-payment badge and disabled call button',
    (t) async {
      await _pump(
        t,
        _b(status: BookingStatus.awaitingPayment, pay: 'bank_transfer_pending'),
      );

      expect(find.text('بانتظار تأكيد الدفع'), findsOneWidget);
      expect(find.text('ملغاة'), findsNothing);

      final callButtonFinder = find.byKey(
        const Key('upcoming_session_call_button'),
      );
      expect(callButtonFinder, findsOneWidget);
      final buttonWidget = t.widget<ElevatedButton>(callButtonFinder);
      expect(buttonWidget.onPressed, isNull); // disabled
    },
  );
}
