import 'package:flutter/foundation.dart';
import '../models/subscription_product.dart';
import '../models/subscription_status.dart';
import '../models/payment_record.dart';
import '../services/firestore_payment_service.dart';
import '../services/subscription_storage_service.dart';
import '../services/subscription_service.dart';

/// Repository for subscription operations
class SubscriptionRepository {
  final FirestorePaymentService _firestoreService;
  final SubscriptionStorageService _storageService;
  final SubscriptionService _subscriptionService;

  SubscriptionRepository({
    required FirestorePaymentService firestoreService,
    required SubscriptionStorageService storageService,
    SubscriptionService? subscriptionService,
  }) : _firestoreService = firestoreService,
       _storageService = storageService,
       _subscriptionService = subscriptionService ?? SubscriptionService();

  /// Initialize subscription for user
  Future<void> initializeSubscription({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    try {
      // Initialize Firestore user document ONLY if it doesn't exist
      // This uses SetOptions(merge: true), so it won't overwrite existing premium status
      await _firestoreService.initializeUserDocument(
        userId,
        email: email,
        displayName: displayName,
      );

      // DO NOT initialize local storage here!
      // The Firestore stream listener will update local cache with correct status
      // Previously this was always saving free() which broke admin-granted premium
      debugPrint(
        '📂 Repository: User document initialized, waiting for stream to update cache',
      );
    } catch (e) {
      throw Exception('Failed to initialize subscription: $e');
    }
  }

  /// Get subscription status from cache first, then Firestore
  Future<SubscriptionStatus> getSubscriptionStatus(String userId) async {
    debugPrint('📂 Repository: Getting subscription status for: $userId');

    // Try to get from local storage first
    SubscriptionStatus? cachedStatus;
    try {
      cachedStatus = await _storageService.getStatus();
      debugPrint('📂 Repository: Cached status state=${cachedStatus.state}');
    } catch (e) {
      debugPrint('📂 Repository: Cache read failed: $e');
    }

    // If we have a non-free cached status, use it for faster response
    if (cachedStatus != null && cachedStatus.state != SubscriptionState.free) {
      debugPrint('📂 Repository: Using cached status (not free)');
      // Refresh from Firestore in background (don't await)
      _refreshSubscriptionStatus(userId);
      return cachedStatus;
    }

    // If no cache or cache is free, fetch from Firestore
    try {
      debugPrint(
        '📂 Repository: Cache is free/missing, fetching from Firestore',
      );
      final status = await _firestoreService.getSubscriptionStatus(userId);
      debugPrint(
        '📂 Repository: Firestore returned state=${status.state}, productId=${status.productId}',
      );

      // Save to local cache (best effort)
      if (status.state != SubscriptionState.error) {
        try {
          await _storageService.saveStatus(status);
        } catch (e) {
          debugPrint('📂 Repository: Cache save failed: $e');
        }
      }

      return status;
    } catch (e) {
      debugPrint('📂 Repository: Firestore fetch failed: $e');
      // Return cached status if available, otherwise free
      return cachedStatus ?? SubscriptionStatus.free();
    }
  }

  /// Stream subscription status for real-time updates
  Stream<SubscriptionStatus> subscriptionStatusStream(String userId) {
    return _firestoreService.subscriptionStatusStream(userId);
  }

  /// Refresh subscription status from Firestore
  Future<void> _refreshSubscriptionStatus(String userId) async {
    try {
      final status = await _firestoreService.getSubscriptionStatus(userId);
      if (status.state != SubscriptionState.error) {
        await _storageService.saveStatus(status);
      }
    } catch (e) {
      // Silently fail - keep cached status
    }
  }

  /// Get subscription products available for purchase from Firestore
  Future<List<SubscriptionProduct>> getAvailableProducts() async {
    return await _subscriptionService.getProducts();
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
      autoRenew: paymentGateway == 'google_pay',
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

  /// Check if an active subscription has expired and update Firestore if so
  Future<bool> checkAndHandleExpiration(
    String userId,
    SubscriptionStatus currentStatus,
  ) async {
    if (currentStatus.state == SubscriptionState.active &&
        currentStatus.isExpired) {
      debugPrint(
        '📂 Repository: Subscription expired for user $userId. Updating Firestore.',
      );
      await _firestoreService.setSubscriptionExpired(userId);

      // Update local storage to match
      final expiredStatus = SubscriptionStatus(
        state: SubscriptionState.expired,
        productId: currentStatus.productId,
        expiryDate: currentStatus.expiryDate,
        autoRenew: false,
        paymentGateway: currentStatus.paymentGateway,
      );
      await _storageService.saveStatus(expiredStatus);
      return true; // Indicates it was changed to expired
    }
    return false; // Not expired or wasn't active
  }

  /// Fetch the payment history for the user
  Future<List<PaymentRecord>> getPaymentHistory(String userId) async {
    return await _firestoreService.getUserPayments(userId);
  }

  /// Clear all subscription data (on logout)
  Future<void> clear() async {
    await _storageService.clearStatus();
  }
}
