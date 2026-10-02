import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const appStoreProductIds = <String, String>{
  'weekly': 'com.sanadtherapy.app.weekly',
  'basic': 'com.sanadtherapy.app.basic',
  'premium': 'com.sanadtherapy.app.premium',
  'premium_vip': 'com.sanadtherapy.app.premium_vip',
};

/// App-scoped listener: a delayed StoreKit transaction can arrive after checkout closes.
class AppStorePurchaseController extends ChangeNotifier {
  AppStorePurchaseController({
    required InAppPurchase store,
    required String? Function() currentUserId,
    required Future<String> Function() prepare,
    required Future<bool> Function(String) verify,
    required Future<void> Function() refresh,
  }) : _store = store,
       _currentUserId = currentUserId,
       _prepare = prepare,
       _verify = verify,
       _refresh = refresh;

  final InAppPurchase _store;
  final String? Function() _currentUserId;
  final Future<String> Function() _prepare;
  final Future<bool> Function(String) _verify;
  final Future<void> Function() _refresh;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void> _queue = Future.value();
  final Map<String, PurchaseDetails> _unverified = {};
  final Map<String, ProductDetails> _products = {};
  bool _disposed = false;
  bool isLoading = true;
  bool isBusy = false;
  bool? lastPurchaseActive;
  String? errorCode;
  bool get hasUnverifiedPurchases => _unverified.isNotEmpty;
  ProductDetails? productFor(String plan) =>
      _products[appStoreProductIds[plan]];

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (_disposed) return;
    _subscription ??= _store.purchaseStream.listen(
      (purchases) {
        _queue = _queue.then((_) async {
          for (final purchase in purchases) {
            await _handlePurchase(purchase);
          }
        });
      },
      onError: (Object _) {
        errorCode = 'store_unavailable';
        isBusy = false;
        _notify();
      },
    );
    isLoading = true;
    _products.clear();
    if (_unverified.isEmpty) errorCode = null;
    _notify();
    try {
      final available = await _store.isAvailable();
      if (_disposed) return;
      if (!available) {
        errorCode = 'store_unavailable';
        return;
      }
      final response = await _store.queryProductDetails(
        appStoreProductIds.values.toSet(),
      );
      if (_disposed) return;
      _products.addEntries(
        response.productDetails.map((p) => MapEntry(p.id, p)),
      );
      if (response.error != null || _products.isEmpty)
        errorCode = 'product_unavailable';
    } catch (_) {
      errorCode = 'store_unavailable';
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<void> purchase(String plan) async {
    if (_disposed || isBusy || isLoading) return;
    if (_unverified.isNotEmpty) {
      errorCode = _currentUserId() == null ? 'sign_in' : 'verification_failed';
      _notify();
      return;
    }
    final product = productFor(plan);
    if (product == null) {
      errorCode = 'product_unavailable';
      _notify();
      return;
    }
    final uid = _currentUserId();
    if (uid == null) {
      errorCode = 'sign_in';
      _notify();
      return;
    }
    isBusy = true;
    errorCode = null;
    lastPurchaseActive = null;
    _notify();
    try {
      final accountToken = await _prepare();
      if (_disposed) return;
      if (_currentUserId() != uid) {
        isBusy = false;
        errorCode = 'sign_in';
        _notify();
        return;
      }
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: accountToken,
        ),
      );
      if (!started) {
        isBusy = false;
        errorCode = 'purchase_failed';
        _notify();
      }
    } catch (_) {
      isBusy = false;
      errorCode = 'purchase_failed';
      _notify();
    }
  }

  Future<void> restore() async {
    if (_disposed || isBusy) return;
    final uid = _currentUserId();
    if (uid == null) {
      errorCode = 'sign_in';
      _notify();
      return;
    }
    isBusy = true;
    errorCode = null;
    lastPurchaseActive = null;
    _notify();
    try {
      final accountToken = await _prepare();
      if (_disposed) return;
      if (_currentUserId() != uid) {
        errorCode = 'sign_in';
        return;
      }
      await _store.restorePurchases(applicationUserName: accountToken);
      if (_disposed) return;
      await _queue;
    } catch (_) {
      errorCode = 'restore_failed';
    } finally {
      isBusy = false;
      _notify();
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (_disposed || !appStoreProductIds.containsValue(purchase.productID))
      return;
    if (purchase.status == PurchaseStatus.pending) {
      isBusy = true;
      _notify();
      return;
    }
    if (purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      isBusy = false;
      errorCode = purchase.status == PurchaseStatus.error
          ? 'purchase_failed'
          : null;
      try {
        if (purchase.pendingCompletePurchase)
          await _store.completePurchase(purchase);
      } catch (_) {
        errorCode = 'purchase_failed';
      }
      _notify();
      return;
    }
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored)
      return;
    final key = purchase.purchaseID ?? purchase.productID;
    _unverified[key] = purchase;
    if (_currentUserId() == null) {
      isBusy = false;
      errorCode = 'sign_in';
      _notify();
      return;
    }
    final uid = _currentUserId();
    lastPurchaseActive = null;
    isBusy = true;
    errorCode = null;
    _notify();
    try {
      final active = await _verify(
        purchase.verificationData.serverVerificationData,
      );
      if (_disposed) return;
      if (_currentUserId() != uid) {
        errorCode = 'sign_in';
        return;
      }
      // Finish only after the server persists Apple's entitlement (including an expired restore).
      if (purchase.pendingCompletePurchase)
        await _store.completePurchase(purchase);
      if (_disposed || _currentUserId() != uid) return;
      _unverified.remove(key);
      lastPurchaseActive = active;
      await _refresh();
    } catch (_) {
      errorCode = 'verification_failed';
    } finally {
      isBusy = false;
      _notify();
    }
  }

  Future<void> onAccountChanged() {
    if (_disposed) return Future.value();
    lastPurchaseActive = null;
    final uid = _currentUserId();
    errorCode = uid == null && _unverified.isNotEmpty ? 'sign_in' : null;
    _notify();
    return uid == null ? Future.value() : retryVerification();
  }

  Future<void> retryVerification() {
    if (_disposed) return Future.value();
    _queue = _queue.then((_) async {
      for (final purchase in List<PurchaseDetails>.of(_unverified.values)) {
        await _handlePurchase(purchase);
      }
    });
    return _queue;
  }

  Future<void> waitForUpdates() => _queue;

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
