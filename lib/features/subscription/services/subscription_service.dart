import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_cache_helper.dart';
import '../models/subscription_product.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore;

  SubscriptionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _productsRef =>
      _firestore.collection('subscription_products');

  /// Fetch all active subscription products from Firestore
  Future<List<SubscriptionProduct>> getProducts() async {
    try {
      final snapshot = await _productsRef
          .where('is_active', isEqualTo: true)
          .orderBy('price')
          .getCacheFirst();

      return snapshot.docs
          .map((doc) => SubscriptionProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream of subscription products for real-time updates
  Stream<List<SubscriptionProduct>> getProductsStream() {
    return _productsRef
        .where('is_active', isEqualTo: true)
        .orderBy('price')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SubscriptionProduct.fromFirestore(doc))
              .toList();
        });
  }

  /// Get a specific product by ID
  Future<SubscriptionProduct?> getProduct(String productId) async {
    try {
      final doc = await _productsRef.doc(productId).getCacheFirst();
      if (!doc.exists) return null;
      return SubscriptionProduct.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Provider for subscription products from Firestore
final subscriptionProductsProvider = FutureProvider<List<SubscriptionProduct>>((
  ref,
) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getProducts();
});

/// Stream provider for real-time product updates
final subscriptionProductsStreamProvider =
    StreamProvider<List<SubscriptionProduct>>((ref) {
      final service = ref.watch(subscriptionServiceProvider);
      return service.getProductsStream();
    });
