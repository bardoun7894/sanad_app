import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_app/features/subscription/services/app_store_purchase_controller.dart';

class MockStore extends Mock implements InAppPurchase {}

class TestPurchaseParam extends Fake implements PurchaseParam {}

void main() {
  late MockStore store;
  late StreamController<List<PurchaseDetails>> updates;
  late AppStorePurchaseController controller;
  String? uid;
  bool valid = true;
  int verifications = 0;
  int refreshes = 0;
  const storeId = 'com.sanadtherapy.app.premium';
  final product = ProductDetails(
    id: storeId,
    title: 'Premium',
    description: 'Monthly',
    price: '€34,99',
    rawPrice: 34.99,
    currencyCode: 'EUR',
  );

  PurchaseDetails purchase(PurchaseStatus status) {
    return PurchaseDetails(
      productID: storeId,
      purchaseID: '2001',
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: 'signed-jws',
        source: 'app_store',
      ),
      transactionDate: '1800000000000',
      status: status,
    )..pendingCompletePurchase = true;
  }

  Future<void> emit(PurchaseDetails p) async {
    updates.add([p]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await controller.waitForUpdates();
  }

  setUpAll(() {
    registerFallbackValue(TestPurchaseParam());
    registerFallbackValue(
      PurchaseDetails(
        productID: storeId,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'app_store',
        ),
        transactionDate: '',
        status: PurchaseStatus.purchased,
      ),
    );
  });
  setUp(() async {
    uid = 'patient';
    valid = true;
    verifications = 0;
    refreshes = 0;
    store = MockStore();
    updates = StreamController<List<PurchaseDetails>>.broadcast();
    when(() => store.purchaseStream).thenAnswer((_) => updates.stream);
    when(() => store.isAvailable()).thenAnswer((_) async => true);
    when(() => store.queryProductDetails(any())).thenAnswer(
      (_) async =>
          ProductDetailsResponse(productDetails: [product], notFoundIDs: []),
    );
    when(
      () => store.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')),
    ).thenAnswer((_) async => true);
    when(() => store.completePurchase(any())).thenAnswer((_) async {});
    when(
      () => store.restorePurchases(
        applicationUserName: any(named: 'applicationUserName'),
      ),
    ).thenAnswer((_) async {});
    controller = AppStorePurchaseController(
      store: store,
      currentUserId: () => uid,
      prepare: () async => '00000000-0000-5000-8000-000000000001',
      verify: (jws) async {
        verifications++;
        if (!valid) throw StateError('verification unavailable');
        return true;
      },
      refresh: () async {
        refreshes++;
      },
    );
    await controller.initialize();
  });
  tearDown(() async {
    controller.dispose();
    await updates.close();
  });

  test('shows store prices and attaches account token to purchase', () async {
    expect(controller.productFor('premium')!.price, '€34,99');
    await controller.purchase('premium');
    final param =
        verify(
              () => store.buyNonConsumable(
                purchaseParam: captureAny(named: 'purchaseParam'),
              ),
            ).captured.single
            as PurchaseParam;
    expect(param.applicationUserName, '00000000-0000-5000-8000-000000000001');
  });
  test(
    'does not complete purchase until server verification succeeds',
    () async {
      valid = false;
      final p = purchase(PurchaseStatus.purchased);
      await emit(p);
      verifyNever(() => store.completePurchase(any()));
      expect(controller.errorCode, 'verification_failed');
      valid = true;
      await controller.retryVerification();
      verify(() => store.completePurchase(p)).called(1);
      expect(refreshes, 1);
      expect(controller.lastPurchaseActive, true);
    },
  );
  test(
    'restored transactions are verified through the same server path',
    () async {
      await controller.restore();
      await emit(purchase(PurchaseStatus.restored));
      expect(verifications, 1);
      expect(refreshes, 1);
    },
  );
  test('pending and canceled purchases never grant access', () async {
    await emit(purchase(PurchaseStatus.pending));
    expect(controller.isBusy, true);
    await emit(purchase(PurchaseStatus.canceled));
    expect(controller.isBusy, false);
    expect(verifications, 0);
    expect(refreshes, 0);
  });
  test('logged-out purchase remains unfinished until sign-in', () async {
    uid = null;
    await emit(purchase(PurchaseStatus.purchased));
    expect(verifications, 0);
    verifyNever(() => store.completePurchase(any()));
    uid = 'patient';
    await controller.retryVerification();
    expect(verifications, 1);
  });
  test(
    'missing store products cannot fall back to an external checkout',
    () async {
      await controller.purchase('basic');
      expect(controller.errorCode, 'product_unavailable');
      verifyNever(
        () =>
            store.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')),
      );
    },
  );
  test(
    'expired restore is completed but does not claim active access',
    () async {
      controller.dispose();
      controller = AppStorePurchaseController(
        store: store,
        currentUserId: () => uid,
        prepare: () async => 'token',
        verify: (_) async => false,
        refresh: () async {},
      );
      await controller.initialize();
      await emit(purchase(PurchaseStatus.restored));
      expect(controller.lastPurchaseActive, false);
      verify(() => store.completePurchase(any())).called(1);
    },
  );
  test(
    'failed verification survives product reload and blocks another payment',
    () async {
      valid = false;
      await emit(purchase(PurchaseStatus.purchased));
      await controller.initialize();
      expect(controller.errorCode, 'verification_failed');
      await controller.purchase('premium');
      verifyNever(
        () =>
            store.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')),
      );
    },
  );

  test('unavailable reload removes stale purchasable products', () async {
    when(() => store.isAvailable()).thenAnswer((_) async => false);
    await controller.initialize();
    expect(controller.productFor('premium'), isNull);
    await controller.purchase('premium');
    verifyNever(
      () => store.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')),
    );
  });

  test('disposing during preparation prevents purchase and restore', () async {
    for (final restore in [false, true]) {
      controller.dispose();
      final prepared = Completer<String>();
      controller = AppStorePurchaseController(
        store: store,
        currentUserId: () => uid,
        prepare: () => prepared.future,
        verify: (_) async => true,
        refresh: () async {},
      );
      await controller.initialize();
      final operation = restore
          ? controller.restore()
          : controller.purchase('premium');
      controller.dispose();
      prepared.complete('token');
      await operation;
      verifyNever(
        () =>
            store.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')),
      );
      verifyNever(
        () => store.restorePurchases(
          applicationUserName: any(named: 'applicationUserName'),
        ),
      );
      // Replace disposed controller so the next iteration/tearDown owns a live instance.
      controller = AppStorePurchaseController(
        store: store,
        currentUserId: () => uid,
        prepare: () async => 'token',
        verify: (_) async => true,
        refresh: () async {},
      );
    }
  });

  test(
    'account change during restore preparation prevents native restore',
    () async {
      controller.dispose();
      controller = AppStorePurchaseController(
        store: store,
        currentUserId: () => uid,
        prepare: () async {
          uid = 'other-patient';
          return 'token';
        },
        verify: (_) async => true,
        refresh: () async {},
      );
      await controller.initialize();
      await controller.restore();
      verifyNever(
        () => store.restorePurchases(
          applicationUserName: any(named: 'applicationUserName'),
        ),
      );
      expect(controller.errorCode, 'sign_in');
    },
  );

  test('disposing during verification leaves transaction unfinished', () async {
    controller.dispose();
    final verified = Completer<bool>();
    controller = AppStorePurchaseController(
      store: store,
      currentUserId: () => uid,
      prepare: () async => 'token',
      verify: (_) => verified.future,
      refresh: () async {
        refreshes++;
      },
    );
    await controller.initialize();
    updates.add([purchase(PurchaseStatus.purchased)]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    controller.dispose();
    verified.complete(true);
    await controller.waitForUpdates();
    verifyNever(() => store.completePurchase(any()));
    expect(refreshes, 0);
    controller = AppStorePurchaseController(
      store: store,
      currentUserId: () => uid,
      prepare: () async => 'token',
      verify: (_) async => true,
      refresh: () async {},
    );
  });
  test('account changes clear the previous account success state', () async {
    await emit(purchase(PurchaseStatus.purchased));
    expect(controller.lastPurchaseActive, true);
    uid = null;
    await controller.onAccountChanged();
    expect(controller.lastPurchaseActive, isNull);
  });

  test(
    'verification across an account change does not finalize for the new user',
    () async {
      controller.dispose();
      controller = AppStorePurchaseController(
        store: store,
        currentUserId: () => uid,
        prepare: () async => 'token',
        verify: (_) async {
          uid = 'other-patient';
          return true;
        },
        refresh: () async {
          refreshes++;
        },
      );
      await controller.initialize();
      await emit(purchase(PurchaseStatus.purchased));
      verifyNever(() => store.completePurchase(any()));
      expect(controller.errorCode, 'sign_in');
      expect(controller.lastPurchaseActive, isNull);
      expect(refreshes, 0);
    },
  );
}
