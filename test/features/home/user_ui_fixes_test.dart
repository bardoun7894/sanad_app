import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanad_app/core/theme/app_theme.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/home/widgets/greeting_header.dart';
import 'package:sanad_app/features/home/home_screen.dart';
import 'package:sanad_app/features/home/providers/home_provider.dart';
import 'package:sanad_app/features/home/providers/recommendation_provider.dart';
import 'package:sanad_app/features/subscription/providers/feature_gating_provider.dart';
import 'package:sanad_app/features/subscription/providers/subscription_provider.dart';
import 'package:sanad_app/features/subscription/models/subscription_status.dart';
import 'package:sanad_app/features/mood/models/mood_enums.dart';
import 'package:sanad_app/features/mood/providers/mood_tracker_provider.dart';
import 'package:sanad_app/features/mood/models/mood_entry.dart';
import 'package:sanad_app/features/mood/repositories/mood_repository.dart';
import 'package:sanad_app/features/engagement/models/streak_data.dart';
import 'package:sanad_app/features/engagement/models/challenge.dart';
import 'package:sanad_app/features/engagement/providers/streak_provider.dart';
import 'package:sanad_app/features/engagement/providers/challenge_provider.dart';
import 'package:sanad_app/features/notifications/models/app_notification.dart';
import 'package:sanad_app/features/notifications/providers/notification_provider.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/profile/providers/profile_provider.dart';
import 'package:sanad_app/features/content/providers/content_provider.dart';
import 'package:sanad_app/features/content/providers/youtube_provider.dart';
import 'package:sanad_app/features/therapists/providers/therapist_provider.dart';

class _FakeLanguageNotifier extends StateNotifier<LanguageState>
    implements LanguageNotifier {
  _FakeLanguageNotifier(super.state);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakNotifier extends StateNotifier<StreakData>
    implements StreakNotifier {
  _FakeStreakNotifier() : super(const StreakData());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileNotifier extends StateNotifier<ProfileState>
    implements ProfileNotifier {
  _FakeProfileNotifier() : super(const ProfileState());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDailyChallengeNotifier extends StateNotifier<DailyChallengeState>
    implements DailyChallengeNotifier {
  _FakeDailyChallengeNotifier() : super(const DailyChallengeState());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTherapistNotifier extends StateNotifier<TherapistState>
    implements TherapistNotifier {
  _FakeTherapistNotifier() : super(const TherapistState());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMoodRepository implements MoodRepository {
  List<MoodEntry> _entries;

  _FakeMoodRepository([List<MoodEntry>? initial]) : _entries = initial ?? [];

  @override
  Stream<List<MoodEntry>> getMoodEntries(String userId) => Stream.value(_entries);

  @override
  Future<void> addMoodEntry(MoodEntry entry, String? userId) async {
    _entries.add(entry);
  }

  @override
  Future<void> updateMoodEntry(MoodEntry entry, String? userId) async {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      _entries[idx] = entry;
    } else {
      _entries.add(entry);
    }
  }

  @override
  Future<void> deleteMoodEntry(String id, String? userId) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('U1: GreetingHeader plan badge text', () {
    testWidgets('shows "الباقة المجانية" for free tier in Arabic', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith(
              (ref) => _FakeLanguageNotifier(LanguageState.arabic()),
            ),
            subscriptionTierProvider.overrideWithValue(SubscriptionTier.free),
            streakProvider.overrideWith((ref) => _FakeStreakNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: GreetingHeader(
                userName: 'محمد',
                subscriptionTier: SubscriptionTier.free,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('الباقة المجانية'), findsOneWidget);
    });

    testWidgets('shows "الباقة المميزة" for premium tier in Arabic', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith(
              (ref) => _FakeLanguageNotifier(LanguageState.arabic()),
            ),
            subscriptionTierProvider.overrideWithValue(SubscriptionTier.premium),
            streakProvider.overrideWith((ref) => _FakeStreakNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: GreetingHeader(
                userName: 'محمد',
                subscriptionTier: SubscriptionTier.premium,
                isPremium: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('الباقة المميزة'), findsOneWidget);
    });

    testWidgets('shows "Free plan" for free tier in English', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith(
              (ref) => _FakeLanguageNotifier(LanguageState.english()),
            ),
            subscriptionTierProvider.overrideWithValue(SubscriptionTier.free),
            streakProvider.overrideWith((ref) => _FakeStreakNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: GreetingHeader(
                userName: 'Mohamed',
                subscriptionTier: SubscriptionTier.free,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Free plan'), findsOneWidget);
    });

    testWidgets('shows "Offre gratuite" for free tier in French', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith(
              (ref) => _FakeLanguageNotifier(LanguageState.french()),
            ),
            subscriptionTierProvider.overrideWithValue(SubscriptionTier.free),
            streakProvider.overrideWith((ref) => _FakeStreakNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: GreetingHeader(
                userName: 'Mohamed',
                subscriptionTier: SubscriptionTier.free,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Offre gratuite'), findsOneWidget);
    });
  });

  group('U2: Notification localized display and route', () {
    test('notification maps "Payment was rejected" to Arabic', () {
      final notif = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'تم رفض الدفع',
        body: 'Payment was rejected',
        type: NotificationType.payment,
        createdAt: DateTime.now(),
      );

      expect(notif.displayTitle('ar'), 'تم رفض الدفع');
      expect(notif.displayBody('ar'), 'تم رفض عملية الدفع');
      expect(notif.displayBody('en'), 'Payment was rejected');
      expect(notif.resolvedRoute, '/subscription');
    });

    test('payment notification with booking_id routes to /bookings', () {
      final notif = AppNotification(
        id: 'n2',
        userId: 'u1',
        title: 'تم رفض الدفع',
        body: 'Payment was rejected',
        type: NotificationType.payment,
        data: {'booking_id': 'b123'},
        createdAt: DateTime.now(),
      );

      expect(notif.resolvedRoute, '/bookings');
    });
  });

  group('U3: Primary card presence on HomeScreen', () {
    testWidgets('displays prominent card to book session with specialist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languageProvider.overrideWith(
              (ref) => _FakeLanguageNotifier(LanguageState.arabic()),
            ),
            subscriptionTierProvider.overrideWithValue(SubscriptionTier.free),
            streakProvider.overrideWith((ref) => _FakeStreakNotifier()),
            moodRepositoryProvider.overrideWithValue(_FakeMoodRepository()),
            currentUserProvider.overrideWithValue(null),
            profileProvider.overrideWith((ref) => _FakeProfileNotifier()),
            unreadNotificationCountProvider.overrideWithValue(0),
            isPremiumProvider.overrideWithValue(false),
            subscriptionStatusProvider.overrideWithValue(
              const SubscriptionStatus(state: SubscriptionState.free),
            ),
            dailyQuoteProvider.overrideWith((ref) => Future.value(null)),
            nextUpcomingSessionProvider.overrideWith((ref) => Future.value(null)),
            dailyChallengeProvider.overrideWith((ref) => _FakeDailyChallengeNotifier()),
            moodBasedRecommendationsProvider.overrideWith((ref) => Future.value([])),
            blogProvider.overrideWith((ref) => Future.value([])),
            sanadPodcastProvider.overrideWith((ref) => Future.value([])),
            therapistProvider.overrideWith((ref) => _FakeTherapistNotifier()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('احجز جلسة مع أخصائي'), findsOneWidget);
      expect(find.text('7، 8، 9 مساءً بتوقيت السودان'), findsOneWidget);
    });
  });

  group('U8: Mood check-in update today entry', () {
    test('updating today mood replaces existing entry in notifier state', () async {
      final today = DateTime.now();
      final initialEntry = MoodEntry(
        id: 'today-1',
        mood: MoodType.happy,
        date: today,
        note: 'Initial mood',
      );
      final fakeRepo = _FakeMoodRepository([initialEntry]);
      final container = ProviderContainer(
        overrides: [
          moodRepositoryProvider.overrideWithValue(fakeRepo),
          moodTrackerProvider.overrideWith(
            (ref) => MoodTrackerNotifier(fakeRepo, null, ref),
          ),
        ],
      );
      final notifier = container.read(moodTrackerProvider.notifier);

      notifier.state = MoodTrackerState(
        todayEntry: initialEntry,
        entries: [initialEntry],
      );

      expect(notifier.state.todayEntry?.mood, MoodType.happy);

      // Log a new mood for today -> updates today's entry
      await notifier.logMood(MoodType.calm, note: 'Updated mood');

      expect(notifier.state.todayEntry?.mood, MoodType.calm);
      expect(notifier.state.todayEntry?.id, 'today-1');
      expect(notifier.state.todayEntry?.note, 'Updated mood');
      expect(notifier.state.entries.length, 1);
      expect(notifier.state.entries.first.mood, MoodType.calm);

      container.dispose();
    });
  });
}
