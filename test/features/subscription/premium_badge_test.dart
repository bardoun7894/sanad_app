import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/core/theme/app_theme.dart';
import 'package:sanad_app/features/subscription/models/subscription_status.dart';
import 'package:sanad_app/features/subscription/providers/feature_gating_provider.dart';
import 'package:sanad_app/features/subscription/providers/subscription_provider.dart';
import 'package:sanad_app/features/subscription/widgets/premium_badge.dart';

// ---------------------------------------------------------------------------
// Fake notifiers — avoid Firebase dependencies in tests
// ---------------------------------------------------------------------------

class _FakeSubscriptionNotifier
    extends StateNotifier<SubscriptionUIState>
    implements SubscriptionNotifier {
  _FakeSubscriptionNotifier(super.state);

  // All abstract/overridden SubscriptionNotifier methods we might touch in
  // tests are not called here; we only need the state value surfaced.
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLanguageNotifier
    extends StateNotifier<LanguageState>
    implements LanguageNotifier {
  _FakeLanguageNotifier(super.state);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SubscriptionUIState _activeState(String productId) => SubscriptionUIState(
  status: SubscriptionStatus(
    state: SubscriptionState.active,
    productId: productId,
    expiryDate: DateTime.now().add(const Duration(days: 30)),
    autoRenew: true,
  ),
  products: const [],
  isLoading: false,
  isInitialized: true,
);

SubscriptionUIState _cancelledActiveState(String productId) => SubscriptionUIState(
  status: SubscriptionStatus(
    state: SubscriptionState.cancelled,
    productId: productId,
    expiryDate: DateTime.now().add(const Duration(days: 5)),
    autoRenew: false,
  ),
  products: const [],
  isLoading: false,
  isInitialized: true,
);

SubscriptionUIState _freeState() => const SubscriptionUIState(
  status: SubscriptionStatus(state: SubscriptionState.free),
  products: [],
  isLoading: false,
  isInitialized: true,
);

Future<void> _pumpBadge(
  WidgetTester tester, {
  required SubscriptionUIState subState,
  required SubscriptionTier tier,
  required String languageCode,
  double constraintWidth = 800,
}) async {
  final langState = languageCode == 'ar'
      ? LanguageState.arabic()
      : languageCode == 'fr'
      ? LanguageState.french()
      : LanguageState.english();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionProvider.overrideWith(
          (ref) => _FakeSubscriptionNotifier(subState),
        ),
        subscriptionTierProvider.overrideWithValue(tier),
        languageProvider.overrideWith(
          (ref) => _FakeLanguageNotifier(langState),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraintWidth),
              child: const PremiumBadge(showText: true),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // --------------------------------------------------------------------------
  // 1. Locale rendering
  // --------------------------------------------------------------------------
  group('PremiumBadge locale labels', () {
    testWidgets('renders "بريميوم" in AR locale for premium tier', (tester) async {
      await _pumpBadge(
        tester,
        subState: _activeState('premium'),
        tier: SubscriptionTier.premium,
        languageCode: 'ar',
      );
      expect(find.text('بريميوم'), findsOneWidget);
    });

    testWidgets('renders "Premium" in EN locale for premium tier', (tester) async {
      await _pumpBadge(
        tester,
        subState: _activeState('premium'),
        tier: SubscriptionTier.premium,
        languageCode: 'en',
      );
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('renders "Premium" in FR locale for premium tier', (tester) async {
      await _pumpBadge(
        tester,
        subState: _activeState('premium'),
        tier: SubscriptionTier.premium,
        languageCode: 'fr',
      );
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('renders "Premium VIP" in EN locale for premiumVip tier', (tester) async {
      await _pumpBadge(
        tester,
        subState: _activeState('premium_vip'),
        tier: SubscriptionTier.premiumVip,
        languageCode: 'en',
      );
      expect(find.text('Premium VIP'), findsOneWidget);
    });
  });

  // --------------------------------------------------------------------------
  // 2. Overflow guard at 320pt
  // --------------------------------------------------------------------------
  group('PremiumBadge overflow guard', () {
    testWidgets('Premium VIP label does not overflow at 320pt', (tester) async {
      final overflowErrors = <FlutterErrorDetails>[];
      final origHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('OVERFLOWED')) {
          overflowErrors.add(details);
        } else {
          origHandler?.call(details);
        }
      };

      await _pumpBadge(
        tester,
        subState: _activeState('premium_vip'),
        tier: SubscriptionTier.premiumVip,
        languageCode: 'en',
        constraintWidth: 320,
      );
      await tester.pump();

      FlutterError.onError = origHandler;
      expect(overflowErrors, isEmpty, reason: 'Text overflowed at 320pt width');
    });

    testWidgets('Premium VIP label does not overflow at 80pt (mini-badge size)', (tester) async {
      final overflowErrors = <FlutterErrorDetails>[];
      final origHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('OVERFLOWED')) {
          overflowErrors.add(details);
        } else {
          origHandler?.call(details);
        }
      };

      await _pumpBadge(
        tester,
        subState: _activeState('premium_vip'),
        tier: SubscriptionTier.premiumVip,
        languageCode: 'en',
        constraintWidth: 80,
      );
      await tester.pump();

      FlutterError.onError = origHandler;
      expect(overflowErrors, isEmpty, reason: 'Profile badge overflowed at 80pt');
    });
  });

  // --------------------------------------------------------------------------
  // 3. Semantics
  // --------------------------------------------------------------------------
  group('PremiumBadge semantics', () {
    testWidgets('Semantics wrapper has label matching AR tier name', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpBadge(
        tester,
        subState: _activeState('premium'),
        tier: SubscriptionTier.premium,
        languageCode: 'ar',
      );
      // Find Semantics node with the Arabic label
      expect(
        find.bySemanticsLabel('بريميوم'),
        findsWidgets,
        reason: 'Semantics label should contain the localized tier name',
      );
      handle.dispose();
    });

    testWidgets('Semantics wrapper has label matching EN tier name', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpBadge(
        tester,
        subState: _activeState('premium'),
        tier: SubscriptionTier.premium,
        languageCode: 'en',
      );
      expect(
        find.bySemanticsLabel('Premium'),
        findsWidgets,
        reason: 'Semantics label should contain the localized tier name',
      );
      handle.dispose();
    });
  });

  // --------------------------------------------------------------------------
  // 4. Cancelled-but-active badge still renders
  // --------------------------------------------------------------------------
  group('PremiumBadge cancelled subscription state', () {
    testWidgets('badge renders when subscription is cancelled but not yet expired', (tester) async {
      await _pumpBadge(
        tester,
        subState: _cancelledActiveState('premium'),
        tier: SubscriptionTier.premium,
        languageCode: 'en',
      );
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('free user sees no badge text', (tester) async {
      await _pumpBadge(
        tester,
        subState: _freeState(),
        tier: SubscriptionTier.free,
        languageCode: 'en',
      );
      // PremiumBadge returns SizedBox.shrink for free tier
      expect(find.text('Free'), findsNothing);
      expect(find.text('Premium'), findsNothing);
    });
  });

  // --------------------------------------------------------------------------
  // 5. SubscriptionTierX visual token smoke tests
  // --------------------------------------------------------------------------
  group('SubscriptionTierX visual tokens', () {
    test('premium.tierPrimaryColor is #F59E0B', () {
      expect(
        SubscriptionTier.premium.tierPrimaryColor.value,
        equals(const Color(0xFFF59E0B).value),
      );
    });

    test('premium.tierGradientStart is #F59E0B', () {
      expect(
        SubscriptionTier.premium.tierGradientStart.value,
        equals(const Color(0xFFF59E0B).value),
      );
    });

    test('premium.tierGradientEnd is #B45309', () {
      expect(
        SubscriptionTier.premium.tierGradientEnd.value,
        equals(const Color(0xFFB45309).value),
      );
    });

    test('premium.tierTextOnColor is dark slate #1F2937 (WCAG AA pass)', () {
      expect(
        SubscriptionTier.premium.tierTextOnColor.value,
        equals(const Color(0xFF1F2937).value),
      );
    });

    test('premium.tierRingColor is #FBBF24', () {
      expect(
        SubscriptionTier.premium.tierRingColor.value,
        equals(const Color(0xFFFBBF24).value),
      );
    });

    test('all tiers expose visual tokens without throwing', () {
      for (final tier in SubscriptionTier.values) {
        expect(() => tier.tierPrimaryColor, returnsNormally);
        expect(() => tier.tierGradientStart, returnsNormally);
        expect(() => tier.tierGradientEnd, returnsNormally);
        expect(() => tier.tierTextOnColor, returnsNormally);
        expect(() => tier.tierRingColor, returnsNormally);
        expect(() => tier.tierIconBg, returnsNormally);
        expect(() => tier.tierIcon, returnsNormally);
      }
    });
  });
}
