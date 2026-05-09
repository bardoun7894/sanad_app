// test/features/therapists/therapist_profile_booking_bar_test.dart
//
// TDD: verifies that the booking bar on TherapistProfileScreen no longer
// renders "choose as therapist" / "switch therapist" UI, and that the
// Book Session button is accessible without a subscription gate.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/booking/providers/user_booking_provider.dart';
import 'package:sanad_app/features/subscription/models/subscription_status.dart';
import 'package:sanad_app/features/subscription/providers/subscription_provider.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';
import 'package:sanad_app/features/therapists/providers/therapist_provider.dart';
import 'package:sanad_app/features/therapists/therapist_profile_screen.dart';

// ---------------------------------------------------------------------------
// Fake notifiers — implements + noSuchMethod pattern avoids Firebase
// ---------------------------------------------------------------------------

class _FreeSubNotifier extends StateNotifier<SubscriptionUIState>
    implements SubscriptionNotifier {
  _FreeSubNotifier()
    : super(
        const SubscriptionUIState(
          status: SubscriptionStatus(state: SubscriptionState.free),
          products: [],
          isLoading: false,
          isInitialized: true,
        ),
      );

  @override
  Future<void> cancelSubscription() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
    : super(const AuthState(status: AuthStatus.unauthenticated));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ---------------------------------------------------------------------------
// Stub therapist
// ---------------------------------------------------------------------------

Therapist _stubTherapist() => const Therapist(
  id: 'therapist-99',
  name: 'Dr. Test',
  nameAr: 'د. اختبار',
  title: 'Psychologist',
  bio: 'Test bio',
  specialties: [],
  sessionTypes: [SessionType.audio, SessionType.chat],
  rating: 4.8,
  reviewCount: 42,
  yearsExperience: 5,
  sessionPrice: 150.0,
  languages: ['Arabic'],
  qualifications: [],
);

// ---------------------------------------------------------------------------
// Build helper
// ---------------------------------------------------------------------------

Widget _buildScreen() {
  final therapist = _stubTherapist();

  return ProviderScope(
    overrides: [
      // Inject therapist into selectedTherapistProvider (StateProvider)
      selectedTherapistProvider.overrideWith((ref) => therapist),

      // Free-tier subscription
      subscriptionProvider.overrideWith((ref) => _FreeSubNotifier()),

      // Unauthenticated user — fake avoids Firebase constructor call
      authProvider.overrideWith((ref) => _FakeAuthNotifier()),

      // No previous bookings
      hasBookedTherapistProvider(therapist.id).overrideWithValue(false),

      // English locale
      languageProvider.overrideWith(
        (ref) => LanguageNotifier()..setLanguage(AppLanguage.english),
      ),
    ],
    child: MaterialApp(
      home: const TherapistProfileScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('_BookingBar – no choose/switch assignment UI', () {
    testWidgets(
      'does not show "Choose as my therapist" text',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Choose as'), findsNothing);
        expect(find.textContaining('اختر كمعالج'), findsNothing);
      },
    );

    testWidgets(
      'does not show "Switch to this therapist" text',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Switch to this'), findsNothing);
        expect(find.textContaining('غيّر إلى'), findsNothing);
      },
    );

    testWidgets(
      'does not show "Your therapist" badge',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Your therapist'), findsNothing);
        expect(find.textContaining('معالجك'), findsNothing);
      },
    );

    testWidgets(
      'shows "Book Session" button',
      (tester) async {
        await tester.pumpWidget(_buildScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Book'), findsOneWidget);
      },
    );
  });
}
