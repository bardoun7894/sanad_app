import '../models/subscription_product.dart';
import '../models/subscription_status.dart';
import '../services/firestore_payment_service.dart';
import '../services/subscription_storage_service.dart';

/// Repository for subscription operations
class SubscriptionRepository {
  final FirestorePaymentService _firestoreService;
  final SubscriptionStorageService _storageService;

  SubscriptionRepository({
    required FirestorePaymentService firestoreService,
    required SubscriptionStorageService storageService,
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  /// Initialize subscription for user
  Future<void> initializeSubscription({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    try {
      // Initialize Firestore user document
      await _firestoreService.initializeUserDocument(
        userId,
        email: email,
        displayName: displayName,
      );

      // Initialize local storage with free status
      await _storageService.saveStatus(SubscriptionStatus.free());
    } catch (e) {
      throw Exception('Failed to initialize subscription: $e');
    }
  }

  /// Get subscription status from cache first, then Firestore
  Future<SubscriptionStatus> getSubscriptionStatus(String userId) async {
    try {
      // Try to get from local storage first
      final cachedStatus = await _storageService.getStatus();

      // If we have a cached status, use it for faster response
      if (cachedStatus.state != SubscriptionState.free) {
        // Refresh from Firestore in background (don't await)
        _refreshSubscriptionStatus(userId);
        return cachedStatus;
      }

      // If no cache, fetch from Firestore
      final status = await _firestoreService.getSubscriptionStatus(userId);

      // Save to local cache
      if (status.state != SubscriptionState.error) {
        await _storageService.saveStatus(status);
      }

      return status;
    } catch (e) {
      // Return cached status if available, otherwise free
      try {
        return await _storageService.getStatus();
      } catch (_) {
        return SubscriptionStatus.free();
      }
    }
  }

  /// Stream subscription status for real-time updates
  Stream<SubscriptionStatus> subscriptionStatusStream(String userId) {
    return _firestoreService.subscriptionStatusStream(userId);
  }

  /// Refresh subscription status from Firestore
  Future<void> _refreshSubscriptionStatus(String userId) async {
    try {
      final status =
          await _firestoreService.getSubscriptionStatus(userId);
      if (status.state != SubscriptionState.error) {
        await _storageService.saveStatus(status);
      }
    } catch (e) {
      // Silently fail - keep cached status
    }
  }

  /// Get subscription products available for purchase
  List<SubscriptionProduct> getAvailableProducts() {
    return SubscriptionProduct.allProducts;
  }

  /// Create payment record for tracking
  Future<String> createPaymentRecord({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? referenceCode,
    String? gatewayTransactionId,
  }) async {
    return await _firestoreService.createPaymentRecord(
      userId: userId,
      amount: amount,
      paymentMethod: paymentMethod,
      referenceCode: referenceCode,
      gatewayTransactionId: gatewayTransactionId,
    );
  }

  /// Create payment verification for bank transfers
  Future<String> createPaymentVerification({
    required String userId,
    required String paymentId,
    required String receiptUrl,
  }) async {
    return await _firestoreService.createPaymentVerification(
      userId: userId,
      paymentId: paymentId,
      receiptUrl: receiptUrl,
    );
  }

  /// Get payment verification status
  Future<Map<String, dynamic>?> getPaymentVerification(
    String verificationId,
  ) async {
    return await _firestoreService.getPaymentVerification(verificationId);
  }

  /// Update subscription status (typically called from webhook)
  Future<void> updateSubscriptionStatus({
    required String userId,
    required SubscriptionState state,
    required String paymentGateway,
    String? productId,
    int? daysValid,
  }) async {
    await _firestoreService.updateSubscriptionStatus(
      userId: userId,
      state: state,
      paymentGateway: paymentGateway,
      productId: productId,
      daysValid: daysValid,
    );

    // Update local cache
    final status = SubscriptionStatus(
      state: state,
      productId: productId,
      expiryDate: daysValid != null
          ? DateTime.now().add(Duration(days: daysValid))
          : null,
      autoRenew: paymentGateway == 'paypal' || paymentGateway == '2checkout',
      paymentGateway: paymentGateway,
    );
    await _storageService.saveStatus(status);
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    await _firestoreService.cancelSubscription(userId);
    await _storageService.saveStatus(SubscriptionStatus.free());
  }

  /// Check if subscription is currently valid
  bool isSubscriptionValid(SubscriptionStatus status) {
    return _firestoreService.isSubscriptionValid(status);
  }

  /// Clear all subscription data (on logout)
  Future<void> clear() async {
    await _storageService.clearStatus();
  }
}
