import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/risk_alerts_provider.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/subscription/models/subscription_product.dart';
import 'package:sanad_app/features/subscription/models/subscription_status.dart';
import 'package:sanad_app/features/subscription/providers/subscription_provider.dart';
import 'package:sanad_app/features/subscription/repositories/subscription_repository.dart';

class _GuestAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _GuestAuthNotifier()
    : super(const AuthState(status: AuthStatus.unauthenticated));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  int getProductsCalls = 0;

  @override
  Future<List<SubscriptionProduct>> getAvailableProducts() async {
    getProductsCalls++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('calculateNewestFirstMoodTrend', () {
    test('returns negative trend when mood is declining (newest worse than oldest)', () {
      // Ordered newest-first: recent scores [1, 1], older scores [5, 5]
      final trend = calculateNewestFirstMoodTrend([1, 1, 5, 5]);
      expect(trend, lessThan(-1.0));
      expect(trend, closeTo(-4.0, 0.001));
    });

    test('returns positive trend when mood is improving (newest better than oldest)', () {
      // Ordered newest-first: recent scores [5, 5], older scores [1, 1]
      final trend = calculateNewestFirstMoodTrend([5, 5, 1, 1]);
      expect(trend, greaterThan(1.0));
      expect(trend, closeTo(4.0, 0.001));
    });

    test('returns zero when mood is stable or fewer than 2 entries', () {
      expect(calculateNewestFirstMoodTrend([3, 3, 3, 3]), 0.0);
      expect(calculateNewestFirstMoodTrend([5]), 0.0);
      expect(calculateNewestFirstMoodTrend([]), 0.0);
    });
  });

  group('SubscriptionUIState.copyWith', () {
    test('clears errorMessage only when clearError is true', () {
      const initial = SubscriptionUIState(
        status: SubscriptionStatus(state: SubscriptionState.free),
        products: [],
        isLoading: false,
        isInitialized: true,
        errorMessage: 'Some error',
      );

      final preserved = initial.copyWith(isLoading: true);
      expect(preserved.errorMessage, 'Some error');

      final cleared = initial.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });
  });

  group('SubscriptionNotifier guest initialization', () {
    test('initializes public products and finishes loading for unauthenticated guests', () async {
      final fakeRepo = _FakeSubscriptionRepository();
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => _GuestAuthNotifier()),
          subscriptionRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Trigger provider creation
      container.read(subscriptionProvider);
      // Allow async _initialize() microtasks to finish
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(subscriptionProvider);
      expect(fakeRepo.getProductsCalls, 1);
      expect(state.isInitialized, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.status.state, SubscriptionState.free);
    });
  });
}
