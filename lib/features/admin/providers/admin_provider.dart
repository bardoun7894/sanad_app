import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/payment_verification.dart';

// Admin state
class AdminState {
  final bool isAdmin;
  final bool isLoading;
  final List<PaymentVerification> pendingVerifications;
  final List<PaymentVerification> processedVerifications;
  final String? error;
  final VerificationFilter filter;

  const AdminState({
    this.isAdmin = false,
    this.isLoading = false,
    this.pendingVerifications = const [],
    this.processedVerifications = const [],
    this.error,
    this.filter = VerificationFilter.pending,
  });

  AdminState copyWith({
    bool? isAdmin,
    bool? isLoading,
    List<PaymentVerification>? pendingVerifications,
    List<PaymentVerification>? processedVerifications,
    String? error,
    VerificationFilter? filter,
  }) {
    return AdminState(
      isAdmin: isAdmin ?? this.isAdmin,
      isLoading: isLoading ?? this.isLoading,
      pendingVerifications: pendingVerifications ?? this.pendingVerifications,
      processedVerifications: processedVerifications ?? this.processedVerifications,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  List<PaymentVerification> get filteredVerifications {
    switch (filter) {
      case VerificationFilter.pending:
        return pendingVerifications;
      case VerificationFilter.approved:
        return processedVerifications
            .where((v) => v.status == VerificationStatus.approved)
            .toList();
      case VerificationFilter.rejected:
        return processedVerifications
            .where((v) => v.status == VerificationStatus.rejected)
            .toList();
      case VerificationFilter.all:
        return [...pendingVerifications, ...processedVerifications];
    }
  }
}

enum VerificationFilter { pending, approved, rejected, all }

// Admin provider
class AdminNotifier extends StateNotifier<AdminState> {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  AdminNotifier(this._ref)
      : _firestore = FirebaseFirestore.instance,
        super(const AdminState()) {
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        state = state.copyWith(isAdmin: false, isLoading: false);
        return;
      }

      final adminDoc = await _firestore
          .collection('admins')
          .doc(authState.user!.uid)
          .get();

      final isAdmin = adminDoc.exists && (adminDoc.data()?['is_active'] ?? false);
      state = state.copyWith(isAdmin: isAdmin, isLoading: false);

      if (isAdmin) {
        await loadVerifications();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check admin status: $e',
      );
    }
  }

  Future<void> loadVerifications() async {
    if (!state.isAdmin) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load pending verifications
      final pendingSnapshot = await _firestore
          .collection('payment_verifications')
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at', descending: true)
          .get();

      final pending = pendingSnapshot.docs
          .map((doc) => PaymentVerification.fromFirestore(doc))
          .toList();

      // Load processed verifications (last 50)
      final processedSnapshot = await _firestore
          .collection('payment_verifications')
          .where('status', whereIn: ['approved', 'rejected'])
          .orderBy('reviewed_at', descending: true)
          .limit(50)
          .get();

      final processed = processedSnapshot.docs
          .map((doc) => PaymentVerification.fromFirestore(doc))
          .toList();

      state = state.copyWith(
        pendingVerifications: pending,
        processedVerifications: processed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load verifications: $e',
      );
    }
  }

  void setFilter(VerificationFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<bool> approveVerification(String verificationId) async {
    if (!state.isAdmin) return false;

    try {
      final authState = _ref.read(authProvider);
      final adminId = authState.user?.uid ?? 'unknown';

      // Get verification details
      final verificationDoc = await _firestore
          .collection('payment_verifications')
          .doc(verificationId)
          .get();

      if (!verificationDoc.exists) {
        state = state.copyWith(error: 'Verification not found');
        return false;
      }

      final verification = PaymentVerification.fromFirestore(verificationDoc);

      // Update verification status
      await _firestore
          .collection('payment_verifications')
          .doc(verificationId)
          .update({
        'status': 'approved',
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': adminId,
      });

      // Activate user subscription
      await _activateSubscription(
        userId: verification.odId,
        productId: verification.productId,
        productTitle: verification.productTitle,
        amount: verification.amount,
        currency: verification.currency,
      );

      // Reload verifications
      await loadVerifications();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to approve: $e');
      return false;
    }
  }

  Future<bool> rejectVerification(String verificationId, String reason) async {
    if (!state.isAdmin) return false;

    try {
      final authState = _ref.read(authProvider);
      final adminId = authState.user?.uid ?? 'unknown';

      await _firestore
          .collection('payment_verifications')
          .doc(verificationId)
          .update({
        'status': 'rejected',
        'reviewed_at': FieldValue.serverTimestamp(),
        'reviewed_by': adminId,
        'rejection_reason': reason,
      });

      // Reload verifications
      await loadVerifications();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to reject: $e');
      return false;
    }
  }

  Future<void> _activateSubscription({
    required String userId,
    required String productId,
    required String productTitle,
    required double amount,
    required String currency,
  }) async {
    // Calculate end date (1 month from now for monthly, 1 year for yearly)
    final now = DateTime.now();
    final isYearly = productId.contains('yearly') || productId.contains('annual');
    final endDate = isYearly
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);

    // Update user subscription status
    await _firestore.collection('users').doc(userId).update({
      'subscription_status': 'active',
      'subscription_product_id': productId,
      'subscription_product_title': productTitle,
      'subscription_start_date': FieldValue.serverTimestamp(),
      'subscription_end_date': Timestamp.fromDate(endDate),
      'is_premium': true,
    });

    // Create payment record
    await _firestore.collection('payments').add({
      'user_id': userId,
      'product_id': productId,
      'product_title': productTitle,
      'amount': amount,
      'currency': currency,
      'payment_method': 'bank_transfer',
      'status': 'completed',
      'created_at': FieldValue.serverTimestamp(),
      'start_date': FieldValue.serverTimestamp(),
      'end_date': Timestamp.fromDate(endDate),
    });
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref);
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(adminProvider).isAdmin;
});

final pendingVerificationsCountProvider = Provider<int>((ref) {
  return ref.watch(adminProvider).pendingVerifications.length;
});
