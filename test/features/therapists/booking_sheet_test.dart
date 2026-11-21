import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/auth/models/auth_user.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';
import 'package:sanad_app/features/therapists/services/booking_service.dart';
import 'package:sanad_app/features/therapists/widgets/booking_sheet.dart';

class _FakeBookingService implements BookingService {
  String? lastClientName;
  String? lastClientEmail;
  String? lastTherapistId;
  DateTime? lastScheduledTime;
  int createCalls = 0;

  @override
  Future<String> createBooking({
    required String therapistId,
    required String therapistName,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required DateTime scheduledTime,
    required int durationMinutes,
    required String sessionType,
    required double amount,
    String currency = 'USD',
    String? notes,
  }) async {
    createCalls++;
    lastTherapistId = therapistId;
    lastClientName = clientName;
    lastClientEmail = clientEmail;
    lastScheduledTime = scheduledTime;
    return 'booking-123';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Therapist _stubTherapist() => const Therapist(
  id: 'therapist-1',
  name: 'Dr. Fatima',
  nameAr: 'د. فاطمة',
  title: 'Psychologist',
  bio: 'Bio',
  specialties: [],
  sessionTypes: [SessionType.audio, SessionType.chat],
  rating: 4.9,
  reviewCount: 20,
  yearsExperience: 6,
  sessionPrice: 20.0,
  languages: ['Arabic'],
  qualifications: [],
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BookingSheet', () {
    testWidgets(
      'tapping Confirm Booking without selecting a time slot shows inline Arabic prompt',
      (tester) async {
        final therapist = _stubTherapist();
        final fakeService = _FakeBookingService();
        final sampleSlots = [
          AvailableSlot(
            id: 'slot-19',
            startTime: DateTime.utc(2026, 11, 25, 17, 0),
            endTime: DateTime.utc(2026, 11, 25, 18, 0),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bookingServiceProvider.overrideWithValue(fakeService),
              availableSlotsProvider.overrideWith((ref, params) async {
                return sampleSlots;
              }),
              currentUserProvider.overrideWithValue(
                AuthUser(
                  uid: 'abu-bakr-uid',
                  email: '',
                  displayName: 'abubakr osman',
                  phoneNumber: '+249912345678',
                  createdAt: DateTime(2026, 1, 1),
                  provider: AuthProvider.phone,
                ),
              ),
              languageProvider.overrideWith(
                (ref) => LanguageNotifier()..setLanguage(AppLanguage.arabic),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BookingSheet(therapist: therapist),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final s = S(AppLanguage.arabic);
        // Tap Confirm Booking without selecting a time slot first
        await tester.tap(find.text(s.confirmBooking));
        await tester.pumpAndSettle();

        // Inline error message appears inside the sheet instead of a dead button
        expect(find.text(s.pleaseSelectTimeSlot), findsOneWidget);
        expect(fakeService.createCalls, 0);

        // Selecting a slot clears the inline error
        await tester.tap(find.textContaining('7:00'));
        await tester.pumpAndSettle();
        expect(find.text(s.pleaseSelectTimeSlot), findsNothing);
      },
    );

    testWidgets(
      'slot load error displays Retry button and re-fetches on tap',
      (tester) async {
        final therapist = _stubTherapist();
        int fetchCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              availableSlotsProvider.overrideWith((ref, params) async {
                fetchCount++;
                if (fetchCount == 1) {
                  throw Exception('transient network error');
                }
                return [
                  AvailableSlot(
                    id: 'slot-20',
                    startTime: DateTime.utc(2026, 11, 25, 18, 0),
                    endTime: DateTime.utc(2026, 11, 25, 19, 0),
                  ),
                ];
              }),
              languageProvider.overrideWith(
                (ref) => LanguageNotifier()..setLanguage(AppLanguage.english),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BookingSheet(therapist: therapist),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final s = S(AppLanguage.english);
        expect(find.text(s.failedToLoadAvailableTimes), findsOneWidget);
        expect(find.text(s.retry), findsOneWidget);

        await tester.tap(find.text(s.retry));
        await tester.pumpAndSettle();

        expect(fetchCount, greaterThanOrEqualTo(2));
        expect(find.text(s.failedToLoadAvailableTimes), findsNothing);
        expect(find.textContaining('8:00'), findsOneWidget);
      },
    );
  });
}
