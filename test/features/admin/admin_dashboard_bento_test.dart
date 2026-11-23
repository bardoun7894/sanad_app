import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/core/theme/app_theme.dart';
import 'package:sanad_app/features/admin/models/activity_log.dart';
import 'package:sanad_app/features/admin/models/signup_failure.dart';
import 'package:sanad_app/features/admin/providers/activity_log_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_booking_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_provider.dart';
import 'package:sanad_app/features/admin/providers/risk_alerts_provider.dart';
import 'package:sanad_app/features/admin/providers/signup_failures_provider.dart';
import 'package:sanad_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:sanad_app/features/admin/widgets/dashboard/clinic_pulse_card.dart';
import 'package:sanad_app/features/admin/widgets/dashboard/risk_alerts_panel.dart';
import 'package:sanad_app/features/chat/models/chat_handoff.dart';
import 'package:sanad_app/features/chat/providers/handoff_provider.dart';
import 'package:sanad_app/features/crisis/models/crisis_alert.dart';
import 'package:sanad_app/features/crisis/providers/crisis_alerts_provider.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_booking.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';

class _FakeLanguageNotifier extends LanguageNotifier {
  _FakeLanguageNotifier(LanguageState initial) {
    state = initial;
  }
}

class _FakeAdminBookingNotifier extends StateNotifier<AdminBookingState>
    implements AdminBookingNotifier {
  _FakeAdminBookingNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const sampleStats = DashboardStats(
    totalUsers: 420,
    activeUsers: 185,
    criticalFlags: 2,
    sessionsToday: 14,
    pendingSessions: 3,
    totalRevenue: 48500,
    newUsersThisMonth: 42,
    premiumUsers: 96,
    articlesCount: 24,
    exercisesCount: 12,
    videosCount: 8,
    publishedContentCount: 40,
    draftContentCount: 4,
    dailyQuotesCount: 30,
    dailyChallengesCount: 15,
    psychTestsCount: 6,
    faqsCount: 18,
    therapistsCount: 9,
  );

  final sampleBookings = [
    TherapistBooking(
      id: 'b1',
      therapistId: 't1',
      clientId: 'c1',
      clientName: 'سارة أحمد',
      scheduledTime: DateTime(2026, 11, 23, 14, 30),
      durationMinutes: 50,
      sessionType: SessionType.audio,
      status: BookingStatus.confirmed,
      amount: 250,
      currency: 'SAR',
      createdAt: DateTime(2026, 11, 22),
    ),
  ];

  List<Override> buildOverrides(LanguageState langState) => [
    languageProvider.overrideWith((_) => _FakeLanguageNotifier(langState)),
    dashboardStatsProvider.overrideWith((_) async => sampleStats),
    activeCrisisAlertsProvider.overrideWith(
      (_) => Stream<List<CrisisAlert>>.value(const []),
    ),
    pendingHandoffsProvider.overrideWith(
      (_) => Stream<List<ChatHandoff>>.value(const []),
    ),
    adminBookingProvider.overrideWith(
      (_) => _FakeAdminBookingNotifier(
        AdminBookingState(bookings: sampleBookings),
      ),
    ),
    riskAlertsProvider.overrideWith(
      (_) => Stream<List<RiskAlert>>.value(const []),
    ),
    incompleteProfilesProvider.overrideWith(
      (_) async => const <SignupFailure>[],
    ),
    recentActivityProvider.overrideWith(
      (_) => Stream<List<ActivityLog>>.value(const []),
    ),
  ];

  testWidgets(
    'AdminDashboardScreen renders cleanly on Desktop in Arabic RTL (Light)',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(LanguageState.arabic()),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: AdminDashboardScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('185'), findsOneWidget);
      expect(find.text('SAR 48.5k'), findsOneWidget);
      expect(find.byType(ClinicPulseCard), findsOneWidget);
      expect(find.text('سارة أحمد'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AdminDashboardScreen renders cleanly on Mobile in English LTR (Dark)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(LanguageState.english()),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(body: AdminDashboardScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('185'), findsOneWidget);
      expect(find.byType(ClinicPulseCard), findsOneWidget);
      expect(find.text('Incomplete Profiles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
