import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_app/features/subscription/models/subscription_product.dart';
import 'package:sanad_app/features/subscription/models/subscription_status.dart';
import 'package:sanad_app/features/subscription/providers/app_store_provider.dart';
import 'package:sanad_app/features/subscription/providers/subscription_provider.dart';
import 'package:sanad_app/features/subscription/screens/app_store_subscription_screen.dart';
import 'package:sanad_app/features/subscription/services/app_store_purchase_controller.dart';
import 'app_store_purchase_controller_test.dart' show MockStore;

void main() {
  late MockStore store;
  late StreamController<List<PurchaseDetails>> updates;
  late AppStorePurchaseController controller;
  Future<void> render(
    WidgetTester tester, {
    String locale = 'en',
    bool available = true,
  }) async {
    when(() => store.isAvailable()).thenAnswer((_) async => available);
    await controller.initialize();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appStoreProvider.overrideWith((ref) => controller),
          availableProductsProvider.overrideWithValue([
            SubscriptionProduct.premium,
          ]),
          subscriptionStatusProvider.overrideWithValue(
            SubscriptionStatus.free(),
          ),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const AppStoreSubscriptionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    store = MockStore();
    updates = StreamController<List<PurchaseDetails>>.broadcast();
    when(() => store.purchaseStream).thenAnswer((_) => updates.stream);
    when(() => store.queryProductDetails(any())).thenAnswer(
      (_) async => ProductDetailsResponse(
        productDetails: [
          ProductDetails(
            id: 'com.sanadtherapy.app.premium',
            title: 'Premium',
            description: 'Monthly',
            price: '€34,99',
            rawPrice: 34.99,
            currencyCode: 'EUR',
          ),
        ],
        notFoundIDs: [],
      ),
    );
    controller = AppStorePurchaseController(
      store: store,
      currentUserId: () => 'patient',
      prepare: () async => 'account-token',
      verify: (_) async => true,
      refresh: () async {},
    );
  });
  tearDown(() async => updates.close());

  testWidgets(
    'paywall uses native price and provides restore, management and legal links',
    (tester) async {
      await render(tester);
      expect(find.text('€34,99 / month'), findsOneWidget);
      expect(find.textContaining('34.90'), findsNothing);
      expect(find.text('Subscribe with App Store'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Restore Purchases'), 200);
      expect(find.text('Manage or cancel subscriptions'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Privacy Policy'), 100);
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.textContaining('Freemius'), findsNothing);
      expect(find.textContaining('PayPal'), findsNothing);
    },
  );
  testWidgets(
    'unavailable native product disables purchase without displaying fallback price',
    (tester) async {
      await render(tester, available: false);
      expect(find.text('Currently unavailable'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.textContaining('34.90'), findsNothing);
    },
  );
  for (final locale in ['ar', 'fr']) {
    testWidgets('$locale shows localized billing and restore labels', (
      tester,
    ) async {
      await render(tester, locale: locale);
      final copy = AppStoreCopy(locale);
      expect(find.text('€34,99 / ${copy.month}'), findsOneWidget);
      expect(find.text(copy.subscribe), findsOneWidget);
      await tester.scrollUntilVisible(find.text(copy.restore), 200);
      expect(find.text(copy.restore), findsOneWidget);
    });
  }
}
