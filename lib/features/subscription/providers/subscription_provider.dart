import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../models/subscription_product.dart';
import '../models/subscription_status.dart';
import '../repositories/subscription_repository.dart';
import '../services/firestore_payment_service.dart';
import '../services/subscription_storage_service.dart';
import '../services/subscription_service.dart';
import '../services/payment_gateway_service.dart';
import '../models/payment_record.dart';
import '../../../core/services/storage_service.dart';

/// Provider for Firebase Storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for subscription storage service
final subscriptionStorageProvider = Provider<SubscriptionStorageService>((ref) {
  return SubscriptionStorageService();
});

/// Provider for Firestore payment service
final firestorePaymentServiceProvider = Provider<FirestorePaymentService>((
  ref,
) {
  return FirestorePaymentService(firestore: FirebaseFirestore.instance);
});

/// Provider for subscription service
final subscriptionServiceLocalProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Provider for subscription repository
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final storage = ref.watch(subscriptionStorageProvider);
  final firestore = ref.watch(firestorePaymentServiceProvider);
  final subscriptionService = ref.watch(subscriptionServiceLocalProvider);

  return SubscriptionRepository(
    firestoreService: firestore,
    storageService: storage,
    subscriptionService: subscriptionService,
  );
});

/// Provider for payment gateway service
final paymentGatewayProvider = Provider<PaymentGatewayService>((ref) {
  return PaymentGatewayService();
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
  StreamSubscription<SubscriptionStatus>? _statusSubscription;
  ProviderSubscription<AuthState>? _authSubscription;
  String? _currentUserId;

  SubscriptionNotifier(this._repository, this._ref)
    : super(
        const SubscriptionUIState(
          status: SubscriptionStatus(state: SubscriptionState.free),
          products: [],
          isLoading: true,
          isInitialized: false,
        ),
      ) {
    // Listen to auth changes to reinitialize when user logs in/out
    _authSubscription = _ref.listen<AuthState>(authProvider, (previous, next) {
      final newUserId = next.user?.uid;
      debugPrint(
        '📦 Auth changed: previous=${previous?.user?.uid}, new=$newUserId, status=${next.status}',
      );

      // Initialize subscription for any logged-in user (authenticated OR profileIncomplete).
      // Admin-granted premium must work even if the user's profile is incomplete.
      final isLoggedIn =
          next.status == AuthStatus.authenticated ||
          next.status == AuthStatus.profileIncomplete;

      // Reinitialize if user changed, OR if same user but we haven't initialized yet
      if (newUserId != null &&
          isLoggedIn &&
          (newUserId != _currentUserId || !state.isInitialized)) {
        debugPrint(
          '📦 User changed or not initialized, reinitializing subscription for: $newUserId (status=${next.status})',
        );
        _currentUserId = newUserId;
        _initialize();
      } else if (newUserId == null && _currentUserId != null) {
        // User logged out
        debugPrint('📦 User logged out, resetting to free');
        _currentUserId = null;
        _statusSubscription?.cancel();
        state = state.copyWith(
          status: SubscriptionStatus.free(),
          isLoading: false,
          isInitialized: true,
        );
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _authSubscription?.close();
    super.dispose();
  }

  /// Initialize subscription
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // Get current user
      final authState = _ref.read(authProvider);
      debugPrint(
        '📦 SubscriptionNotifier._initialize: user=${authState.user?.uid}, email=${authState.user?.email}',
      );

      if (authState.user == null) {
        debugPrint('📦 No user, returning free status');
        // Still load products from Firestore even for unauthenticated users
        final products = await _repository.getAvailableProducts();
        state = state.copyWith(
          status: SubscriptionStatus.free(),
          products: products,
          isLoading: false,
          isInitialized: true,
        );
        return;
      }

      // Initialize subscription for user if needed
      debugPrint('📦 Step 1: Initializing subscription document...');
      await _repository.initializeSubscription(
        userId: authState.user!.uid,
        email: authState.user!.email,
        displayName: authState.user!.displayName,
      );
      debugPrint('📦 Step 1: Done');

      // Get products
      debugPrint('📦 Step 2: Getting products...');
      final products = await _repository.getAvailableProducts();
      debugPrint('📦 Step 2: Got ${products.length} products');

      // Set up real-time listener for subscription status changes
      debugPrint('📦 Step 3: Setting up subscription stream...');
      _statusSubscription?.cancel();
      _statusSubscription = _repository
          .subscriptionStatusStream(authState.user!.uid)
          .listen(
            (status) async {
              debugPrint(
                '📡 Subscription stream update: isPremium=${status.isActive}, state=${status.state}, productId=${status.productId}',
              );

              // Check for expiration. If expired, it updates Firestore and we get an updated stream event.
              final wasExpired = await _repository.checkAndHandleExpiration(
                authState.user!.uid,
                status,
              );

              if (wasExpired) {
                return; // Let the next stream event update the state
              }

              state = state.copyWith(
                status: status,
                isLoading: false,
                isInitialized: true,
                errorMessage: null,
              );
            },
            onError: (e, st) {
              debugPrint('📡 Subscription stream error: $e');
              debugPrintStack(stackTrace: st);
              state = state.copyWith(
                errorMessage: 'Failed to sync subscription: $e',
              );
            },
          );
      debugPrint('📦 Step 3: Stream listener set up');

      // Get initial status while stream sets up
      debugPrint('📦 Step 4: Getting initial subscription status...');
      final initialStatus = await _repository.getSubscriptionStatus(
        authState.user!.uid,
      );

      debugPrint(
        '📦 Step 5: Got initial status: state=${initialStatus.state}, isPremium=${initialStatus.isActive}, productId=${initialStatus.productId}',
      );
      state = state.copyWith(
        status: initialStatus,
        products: products,
        isLoading: false,
        isInitialized: true,
      );
      debugPrint('📦 Step 6: Initialization complete!');
    } catch (e, stackTrace) {
      debugPrint('📦 ERROR in _initialize: $e');
      debugPrintStack(stackTrace: stackTrace);
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

      final status = await _repository.getSubscriptionStatus(
        authState.user!.uid,
      );
      state = state.copyWith(status: status, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Activate a user's subscription after a successful payment.
  ///
  /// Used by all tokenized-wallet flows (PayPal capture, Google Pay, Apple
  /// Pay). The funds have already been captured server-side at this point —
  /// this call only mirrors the entitlement into Firestore so feature gating
  /// unlocks on the client. `gateway` is free-form ('paypal' | 'paypal_card'
  /// | 'google_pay' | 'apple_pay') and stored on the user doc for
  /// bookkeeping.
  Future<void> confirmPaymentSubscription({
    required String orderId,
    required SubscriptionProduct product,
    String gateway = 'google_pay',
  }) async {
    try {
      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      if (orderId.isEmpty) {
        throw Exception('Invalid payment data: orderId missing');
      }

      await _repository.updateSubscriptionStatus(
        userId: authState.user!.uid,
        state: SubscriptionState.active,
        paymentGateway: gateway,
        productId: product.id,
        daysValid: product.billingPeriodDays > 0
            ? product.billingPeriodDays
            : 30,
      );

      // Refresh state
      await checkSubscription();

      state = state.copyWith(isProcessingPurchase: false, errorMessage: null);
    } catch (e) {
      state = state.copyWith(
        isProcessingPurchase: false,
        errorMessage: 'Failed to confirm $gateway payment: $e',
      );
      rethrow;
    }
  }

  /// Initiate bank transfer payment
  Future<String> subscribeWithBankTransfer(SubscriptionProduct product) async {
    try {
      state = state.copyWith(isProcessingPurchase: true, errorMessage: null);

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
      state = state.copyWith(errorMessage: 'Failed to submit verification: $e');
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
      state = state.copyWith(errorMessage: 'Failed to cancel subscription: $e');
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
final availableProductsProvider = Provider<List<SubscriptionProduct>>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.products;
});

/// Get specific product by ID
final productByIdProvider = Provider.family<SubscriptionProduct?, String>((
  ref,
  productId,
) {
  final products = ref.watch(availableProductsProvider);
  try {
    return products.firstWhere((p) => p.id == productId);
  } catch (e) {
    return null;
  }
});

/// Provider for fetching user payment history
final paymentHistoryProvider = FutureProvider.autoDispose<List<PaymentRecord>>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    return [];
  }

  final repository = ref.watch(subscriptionRepositoryProvider);
  return await repository.getPaymentHistory(authState.user!.uid);
});
