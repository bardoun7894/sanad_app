import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/auth/models/auth_user.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_booking.dart';
import 'package:sanad_app/features/therapist_portal/screens/therapist_bookings_screen.dart';
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
  final now = DateTime.now();

  final bookingUpcomingConfirmed = TherapistBooking(
    id: 'b1',
    therapistId: 't1',
    clientId: 'c1',
    clientName: 'أحمد',
    scheduledTime: now.add(const Duration(hours: 2)),
    sessionType: SessionType.audio,
    status: BookingStatus.confirmed,
    amount: 15,
    createdAt: DateTime(2026, 10, 1),
    paymentStatus: 'paid',
  );

  final bookingUpcomingTentative = TherapistBooking(
    id: 'b2',
    therapistId: 't1',
    clientId: 'c2',
    clientName: 'منى',
    scheduledTime: now.add(const Duration(hours: 4)),
    sessionType: SessionType.audio,
    status: BookingStatus.awaitingPayment,
    amount: 15,
    createdAt: DateTime(2026, 10, 1),
    paymentStatus: 'bank_transfer_pending',
  );

  final bookingPastCompleted = TherapistBooking(
    id: 'b3',
    therapistId: 't1',
    clientId: 'c3',
    clientName: 'سارة',
    scheduledTime: now.subtract(const Duration(days: 1)),
    sessionType: SessionType.audio,
    status: BookingStatus.completed,
    amount: 15,
    createdAt: DateTime(2026, 10, 1),
    paymentStatus: 'paid',
  );

  testWidgets('shows title جلساتي, two segments القادمة and السابقة', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          stringsProvider.overrideWithValue(S(AppLanguage.arabic)),
          therapistBookingsProvider(null).overrideWith(
            (ref) => Stream.value([
              bookingUpcomingConfirmed,
              bookingUpcomingTentative,
              bookingPastCompleted,
            ]),
          ),
        ],
        child: const MaterialApp(
          home: TherapistBookingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Title is 'جلساتي'
    expect(find.text('جلساتي'), findsWidgets);

    // Two segments: 'القادمة' and 'السابقة'
    expect(find.text('القادمة'), findsOneWidget);
    expect(find.text('السابقة'), findsOneWidget);

    // Upcoming list shows أحمد and منى
    expect(find.text('أحمد'), findsOneWidget);
    expect(find.text('منى'), findsOneWidget);
    expect(find.text('سارة'), findsNothing);

    // Badges in upcoming
    expect(find.text('مدفوع'), findsOneWidget);
    expect(find.text('بانتظار تأكيد الدفع'), findsOneWidget);

    // Call buttons in upcoming: confirmed has enabled call button, tentative is disabled
    final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)).toList();
    // At least 2 call buttons for the 2 cards
    expect(buttons.length, greaterThanOrEqualTo(2));
    final hasEnabled = buttons.any((b) => b.onPressed != null);
    final hasDisabled = buttons.any((b) => b.onPressed == null);
    expect(hasEnabled, isTrue);
    expect(hasDisabled, isTrue);

    // Switch to 'السابقة' tab
    await tester.tap(find.text('السابقة'));
    await tester.pumpAndSettle();

    // Past tab shows سارة
    expect(find.text('سارة'), findsOneWidget);
    expect(find.text('أحمد'), findsNothing);
  });

  testWidgets('shows good empty states when no sessions exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          stringsProvider.overrideWithValue(S(AppLanguage.arabic)),
          therapistBookingsProvider(null).overrideWith(
            (ref) => Stream.value([]),
          ),
        ],
        child: const MaterialApp(
          home: TherapistBookingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('لا توجد جلسات قادمة'), findsOneWidget);

    await tester.tap(find.text('السابقة'));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد جلسات سابقة'), findsOneWidget);
  });
}
