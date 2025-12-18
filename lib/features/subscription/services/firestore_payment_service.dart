import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_status.dart';

/// Service for handling Firestore payment operations
class FirestorePaymentService {
  final FirebaseFirestore _firestore;

  FirestorePaymentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get current user's subscription status from Firestore
  Future<SubscriptionStatus> getSubscriptionStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return SubscriptionStatus.free();
      }

      final data = doc.data() as Map<String, dynamic>;
      return _parseSubscriptionStatus(data);
    } catch (e) {
      return SubscriptionStatus(
        state: SubscriptionState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Stream subscription status for real-time updates
  Stream<SubscriptionStatus> subscriptionStatusStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return SubscriptionStatus.free();
      }

      final data = doc.data() as Map<String, dynamic>;
      return _parseSubscriptionStatus(data);
    }).handleError((e) {
      return SubscriptionStatus(
        state: SubscriptionState.error,
        errorMessage: e.toString(),
      );
    });
  }

  /// Create a payment record for tracking
  Future<String> createPaymentRecord({
    required String userId,
    required double amount,
    required String paymentMethod, // 'card', 'bank_transfer'
    String? referenceCode,
    String? gatewayTransactionId,
  }) async {
    try {
      final doc = await _firestore.collection('payments').add({
        'user_id': userId,
        'amount': amount,
        'currency': 'USD',
        'status': 'pending',
        'payment_method': paymentMethod,
        'reference_code': referenceCode,
        'gateway_transaction_id': gatewayTransactionId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return doc.id;
    } catch (e) {
      throw Exception('Failed to create payment record: $e');
    }
  }

  /// Create a payment verification request (for bank transfers)
  Future<String> createPaymentVerification({
    required String userId,
    required String paymentId,
    required String receiptUrl,
  }) async {
    try {
      final doc = await _firestore.collection('payment_verifications').add({
        'user_id': userId,
        'payment_id': paymentId,
        'status': 'pending',
        'receipt_url': receiptUrl,
        'verified_by': null,
        'verified_at': null,
        'rejection_reason': null,
        'created_at': FieldValue.serverTimestamp(),
      });

      return doc.id;
    } catch (e) {
      throw Exception('Failed to create payment verification: $e');
    }
  }

  /// Get payment verification status
  Future<Map<String, dynamic>?> getPaymentVerification(
    String verificationId,
  ) async {
    try {
      final doc = await _firestore
          .collection('payment_verifications')
          .doc(verificationId)
          .get();

      return doc.data();
    } catch (e) {
      throw Exception('Failed to get payment verification: $e');
    }
  }

  /// Update subscription status (called from Cloud Function webhook)
  Future<void> updateSubscriptionStatus({
    required String userId,
    required SubscriptionState state,
    required String paymentGateway,
    String? productId,
    int? daysValid = 30,
  }) async {
    try {
      final expiryDate = daysValid != null
          ? DateTime.now().add(Duration(days: daysValid))
          : null;

      await _firestore.collection('users').doc(userId).update({
        'subscription_status': state.name,
        'subscription_plan': productId,
        'subscription_expiry_date': expiryDate != null
            ? Timestamp.fromDate(expiryDate)
            : FieldValue.delete(),
        'payment_gateway': paymentGateway,
        'auto_renew': paymentGateway == 'paypal' || paymentGateway == '2checkout',
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update subscription status: $e');
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription_status': SubscriptionState.cancelled.name,
        'auto_renew': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  /// Check if subscription is valid
  bool isSubscriptionValid(SubscriptionStatus status) {
    return status.isActive && !status.isExpired;
  }

  /// Parse Firestore document to SubscriptionStatus
  SubscriptionStatus _parseSubscriptionStatus(Map<String, dynamic> data) {
    try {
      final statusName =
          data['subscription_status'] as String? ?? 'free';
      final state =
          SubscriptionState.values.asNameMap()[statusName] ??
              SubscriptionState.free;

      DateTime? expiryDate;
      final expiryTimestamp = data['subscription_expiry_date'];
      if (expiryTimestamp != null) {
        expiryDate =
            (expiryTimestamp as Timestamp).toDate();
      }

      return SubscriptionStatus(
        state: state,
        productId: data['subscription_plan'] as String?,
        expiryDate: expiryDate,
        autoRenew: data['auto_renew'] as bool? ?? false,
        paymentGateway: data['payment_gateway'] as String?,
      );
    } catch (e) {
      return SubscriptionStatus.free();
    }
  }

  /// Initialize user document in Firestore if it doesn't exist
  Future<void> initializeUserDocument(
    String userId, {
    required String email,
    String? displayName,
  }) async {
    try {
      final doc = _firestore.collection('users').doc(userId);
      final snapshot = await doc.get();

      if (!snapshot.exists) {
        await doc.set({
          'uid': userId,
          'email': email,
          'displayName': displayName,
          'subscription_status': SubscriptionState.free.name,
          'subscription_plan': null,
          'subscription_expiry_date': null,
          'payment_gateway': null,
          'auto_renew': false,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to initialize user document: $e');
    }
  }
}
