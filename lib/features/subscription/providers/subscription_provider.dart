import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../models/subscription_product.dart';
import '../models/subscription_status.dart';
import '../repositories/subscription_repository.dart';
import '../services/firestore_payment_service.dart';
import '../services/subscription_storage_service.dart';

/// Provider for subscription storage service
final subscriptionStorageProvider =
    Provider<SubscriptionStorageService>((ref) {
  return SubscriptionStorageService();
});

/// Provider for Firestore payment service
final firestorePaymentServiceProvider =
    Provider<FirestorePaymentService>((ref) {
  return FirestorePaymentService(
    firestore: FirebaseFirestore.instance,
  );
});

/// Provider for subscription repository
final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) {
  final storage = ref.watch(subscriptionStorageProvider);
  final firestore = ref.watch(firestorePaymentServiceProvider);

  return SubscriptionRepository(
    firestoreService: firestore,
    storageService: storage,
  );
});

/// State for subscription notifier
class SubscriptionUIState {
  final SubscriptionStatus status;
  final List<SubscriptionProduct> products;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;
  final bool isProcessingPurchase;

  const SubscriptionUIState({
    required this.status,
    required this.products,
    required this.isLoading,
    required this.isInitialized,
    this.errorMessage,
    this.isProcessingPurchase = false,
  });

  /// Check if user has active subscription
  bool get isPremium => status.isActive;

  /// Check if subscription is expired
  bool get isExpired => status.isExpired;

  /// Check if subscription is pending verification
  bool get isPending => status.isPending;

  /// Create a copy with updated fields
  SubscriptionUIState copyWith({
    SubscriptionStatus? status,
    List<SubscriptionProduct>? products,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool? isProcessingPurchase,
  }) {
    return SubscriptionUIState(
      status: status ?? this.status,
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessingPurchase: isProcessingPurchase ?? this.isProcessingPurchase,
    );
  }

  @override
  String toString() {
    return 'SubscriptionUIState('
        'isPremium: $isPremium, '
        'isLoading: $isLoading, '
        'error: $errorMessage'
        ')';
  }
}

/// Notifier for subscription state management
class SubscriptionNotifier extends StateNotifier<SubscriptionUIState> {
  final SubscriptionRepository _repository;
  final Ref _ref;

  SubscriptionNotifier(
    this._repository,
    this._ref,
  ) : super(
    const SubscriptionUIState(
      status: SubscriptionStatus(state: SubscriptionState.free),
      products: [],
      isLoading: true,
      isInitialized: false,
    ),
  ) {
    _initialize();
  }

  /// Initialize subscription
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Get current user
      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        state = state.copyWith(
          status: SubscriptionStatus.free(),
          products: SubscriptionProduct.allProducts,
          isLoading: false,
          isInitialized: true,
        );
        return;
      }

      // Initialize subscription for user if needed
      await _repository.initializeSubscription(
        userId: authState.user!.uid,
        email: authState.user!.email,
        displayName: authState.user!.displayName,
      );

      // Get current subscription status
      final status =
          await _repository.getSubscriptionStatus(authState.user!.uid);

      state = state.copyWith(
        status: status,
        products: _repository.getAvailableProducts(),
        isLoading: false,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: 'Failed to initialize subscription: $e',
        status: SubscriptionStatus.free(),
      );
    }
  }

  /// Check subscription status (refresh from Firestore)
  Future<void> checkSubscription() async {
    try {
      final authState = _ref.read(authProvider);
      if (authState.user == null) return;

      final status =
          await _repository.getSubscriptionStatus(authState.user!.uid);
      state = state.copyWith(status: status, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Initiate card payment subscription
  Future<void> subscribeWithCard(SubscriptionProduct product) async {
    try {
      state = state.copyWith(
        isProcessingPurchase: true,
        errorMessage: null,
      );

      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      // In real implementation, this would open PayPal/2Checkout payment interface
      // For now, create a payment record
      final paymentId = await _repository.createPaymentRecord(
        userId: authState.user!.uid,
        amount: product.price,
        paymentMethod: 'card',
      );

      state = state.copyWith(
        isProcessingPurchase: false,
        errorMessage: null,
      );

      // Redirect to payment gateway (in UI)
      // Return paymentId for UI to use
    } catch (e) {
      state = state.copyWith(
        isProcessingPurchase: false,
        errorMessage: 'Failed to initiate payment: $e',
      );
      rethrow;
    }
  }

  /// Initiate bank transfer payment
  Future<String> subscribeWithBankTransfer(SubscriptionProduct product) async {
    try {
      state = state.copyWith(
        isProcessingPurchase: true,
        errorMessage: null,
      );

      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      // Create payment record
      final paymentId = await _repository.createPaymentRecord(
        userId: authState.user!.uid,
        amount: product.price,
        paymentMethod: 'bank_transfer',
      );

      state = state.copyWith(
        isProcessingPurchase: false,
        status: state.status.copyWith(
          state: SubscriptionState.pending,
          paymentGateway: 'bank_transfer',
        ),
      );

      return paymentId;
    } catch (e) {
      state = state.copyWith(
        isProcessingPurchase: false,
        errorMessage: 'Failed to initiate bank transfer: $e',
      );
      rethrow;
    }
  }

  /// Submit payment verification for bank transfer
  Future<void> submitPaymentVerification({
    required String paymentId,
    required String receiptUrl,
  }) async {
    try {
      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      await _repository.createPaymentVerification(
        userId: authState.user!.uid,
        paymentId: paymentId,
        receiptUrl: receiptUrl,
      );

      state = state.copyWith(
        status: state.status.copyWith(
          state: SubscriptionState.pending,
          paymentGateway: 'bank_transfer',
        ),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to submit verification: $e',
      );
      rethrow;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      await _repository.cancelSubscription(authState.user!.uid);
      state = state.copyWith(
        status: SubscriptionStatus.free(),
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to cancel subscription: $e',
      );
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Main subscription provider
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionUIState>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionNotifier(repository, ref);
});

/// Helper provider for isPremium check
final isPremiumProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.isPremium;
});

/// Helper provider for subscription status
final subscriptionStatusProvider = Provider<SubscriptionStatus>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.status;
});

/// Helper provider for available products
final availableProductsProvider =
    Provider<List<SubscriptionProduct>>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.products;
});

/// Get specific product by ID
final productByIdProvider =
    Provider.family<SubscriptionProduct?, String>((ref, productId) {
  final products = ref.watch(availableProductsProvider);
  try {
    return products.firstWhere((p) => p.id == productId);
  } catch (e) {
    return null;
  }
});
