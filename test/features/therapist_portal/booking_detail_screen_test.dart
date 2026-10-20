import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/auth/models/auth_user.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_booking.dart';
import 'package:sanad_app/features/therapist_portal/screens/booking_detail_screen.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
      : super(
          AuthState(
            status: AuthStatus.authenticated,
            user: AuthUser(
              uid: 't1',
              email: 'therapist@sanad.app',
              displayName: 'Dr. Therapist',
              role: UserRole.therapist,
              createdAt: DateTime(2026),
              provider: AuthProvider.email,
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final scheduled = DateTime.utc(2026, 10, 25, 14);

  final confirmedBooking = TherapistBooking(
    id: 'b_conf',
    therapistId: 't1',
    clientId: 'c1',
    clientName: 'خالد محمد',
    clientEmail: 'khaled@example.com',
    scheduledTime: scheduled,
    sessionType: SessionType.audio,
    status: BookingStatus.confirmed,
    amount: 20,
    createdAt: DateTime.utc(2026, 10, 20),
    paymentStatus: 'paid',
  );

  testWidgets(
    'BookingDetailScreen displays clean header, big Sudan date/time, badges, notes, large call button, no accept/reject for confirmed',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _FakeAuthNotifier()),
            stringsProvider.overrideWithValue(S(AppLanguage.arabic)),
          ],
          child: MaterialApp(
            home: BookingDetailScreen(
              bookingId: 'b_conf',
              initialBooking: confirmedBooking,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Client name
      expect(find.text('خالد محمد'), findsWidgets);

      // Status badge and payment badge
      expect(find.text('مؤكد'), findsWidgets);
      expect(find.text('مدفوع'), findsWidgets);

      // Sudan date and time
      expect(find.textContaining('25 أكتوبر 2026'), findsWidgets);
      expect(find.textContaining('بتوقيت السودان'), findsWidgets);

      // Large call button for confirmed
      final callButton = find.widgetWithText(ElevatedButton, 'اتصل بالمستخدم');
      expect(callButton, findsOneWidget);
      final elevated = tester.widget<ElevatedButton>(callButton);
      expect(elevated.onPressed, isNotNull);

      // No accept or reject buttons for confirmed booking
      expect(find.text('قبول'), findsNothing);
      expect(find.text('رفض'), findsNothing);

      // Notes section and mark completed button
      expect(find.text('ملاحظات الجلسة'), findsOneWidget);
      expect(find.text('حفظ الملاحظات'), findsOneWidget);
      expect(find.text('إكمال الجلسة'), findsWidgets);
    },
  );
}
