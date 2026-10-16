import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_booking.dart';
import 'package:sanad_app/features/therapist_portal/widgets/upcoming_session_card.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';

TherapistBooking _b({BookingStatus status = BookingStatus.confirmed, String? pay}) =>
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

Future<void> _pump(WidgetTester t, TherapistBooking b, VoidCallback onChat) =>
    t.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: UpcomingSessionCard(
            booking: b,
            onOpenChat: onChat,
            now: DateTime.utc(2026, 10, 18, 8),
          ),
        ),
      ),
    ));

void main() {
  testWidgets('shows Sudan-time sentence, tappable client name, no badge when confirmed',
      (t) async {
    var taps = 0;
    await _pump(t, _b(), () => taps++);
    expect(find.textContaining('لديك جلسة اليوم الساعة 4:00 مساءً بتوقيت السودان مع'), findsOneWidget);
    expect(find.text('بانتظار تأكيد الدفع'), findsNothing);
    await t.tap(find.byKey(const Key('session_client_link')));
    expect(taps, 1);
    expect(find.text('سارة'), findsOneWidget);
  });

  testWidgets('tentative booking shows the awaiting-payment badge, never cancelled',
      (t) async {
    await _pump(
      t,
      _b(status: BookingStatus.awaitingPayment, pay: 'bank_transfer_pending'),
      () {},
    );
    expect(find.text('بانتظار تأكيد الدفع'), findsOneWidget);
    expect(find.text('ملغاة'), findsNothing);
  });
}
