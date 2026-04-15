import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firestore_cache_helper.dart';
import '../models/subscription_status.dart';
import '../models/payment_record.dart';

/// Service for handling Firestore payment operations
class FirestorePaymentService {
  final FirebaseFirestore _firestore;

  FirestorePaymentService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get current user's subscription status from Firestore
  Future<SubscriptionStatus> getSubscriptionStatus(String userId) async {
    try {
      debugPrint('🔥 Firestore: Getting subscription status for user: $userId');
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .getCacheFirst();

      if (!doc.exists) {
        debugPrint('🔥 Firestore: User document does not exist');
        return SubscriptionStatus.free();
      }

      final data = doc.data() as Map<String, dynamic>;
      debugPrint('🔥 Firestore: Raw user data keys: ${data.keys.toList()}');
      debugPrint(
        '🔥 Firestore: is_premium=${data['is_premium']}, subscription_status=${data['subscription_status']}, subscription_plan=${data['subscription_plan']}',
      );
      return _parseSubscriptionStatus(data);
    } catch (e, st) {
      debugPrint('🔥 Firestore: Error getting subscription: $e');
      debugPrintStack(stackTrace: st);
      return SubscriptionStatus(
        state: SubscriptionState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Stream subscription status for real-time updates
  Stream<SubscriptionStatus> subscriptionStatusStream(String userId) {
    debugPrint(
      '🔥 Firestore: Setting up subscription stream for user: $userId',
    );
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          debugPrint(
            '🔥 Firestore: Stream snapshot received, exists=${doc.exists}',
          );
          if (!doc.exists) {
            debugPrint('🔥 Firestore: Stream - user document does not exist');
            return SubscriptionStatus.free();
          }

          final data = doc.data() as Map<String, dynamic>;
          debugPrint(
            '🔥 Firestore: Stream - is_premium=${data['is_premium']}, subscription_status=${data['subscription_status']}',
          );
          return _parseSubscriptionStatus(data);
        })
        .handleError((Object e, StackTrace st) {
          debugPrint('🔥 Firestore: Stream error: $e');
          debugPrintStack(stackTrace: st);
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
        'auto_renew': paymentGateway == 'google_pay',
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

  /// Mark subscription as expired
  Future<void> setSubscriptionExpired(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription_status': SubscriptionState.expired.name,
        'is_premium': false,
        'auto_renew': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking subscription as expired: $e');
    }
  }

  /// Get user payment history
  Future<List<PaymentRecord>> getUserPayments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .getCacheFirst();

      return snapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }

  /// Check if subscription is valid
  bool isSubscriptionValid(SubscriptionStatus status) {
    return status.isActive && !status.isExpired;
  }

  /// Parse Firestore document to SubscriptionStatus
  SubscriptionStatus _parseSubscriptionStatus(Map<String, dynamic> data) {
    try {
      // Check is_premium flag first as a simple fallback
      final isPremiumFlag = data['is_premium'] as bool? ?? false;

      final statusName = data['subscription_status'] as String? ?? 'free';
      // Handle case-sensitivity by normalizing to lowercase
      final normalizedStatusName = statusName.toLowerCase();

      var state =
          SubscriptionState.values.asNameMap()[normalizedStatusName] ??
          SubscriptionState.free;

      // Debug logging
      debugPrint(
        '🔍 _parseSubscriptionStatus: is_premium=$isPremiumFlag, subscription_status=$statusName (norm=$normalizedStatusName), parsed_state=$state',
      );

      // CRITICAL: If is_premium is true using boolean flag, FORCE active state
      // This handles cases where 'subscription_status' string might be missing or mismatched
      if (isPremiumFlag) {
        if (state != SubscriptionState.active) {
          debugPrint(
            '🔍 Forced state to active because is_premium=true (was $state)',
          );
          state = SubscriptionState.active;
        }
      }

      DateTime? expiryDate;
      final expiryTimestamp =
          data['subscription_expiry_date'] ??
          data['subscription_end_date']; // Also check old field name
      if (expiryTimestamp != null && expiryTimestamp is Timestamp) {
        expiryDate = expiryTimestamp.toDate();
      }

      // If we have an expiry date that is in the future, and we are premium, ensure active
      if (expiryDate != null &&
          expiryDate.isAfter(DateTime.now()) &&
          isPremiumFlag) {
        if (state != SubscriptionState.active) {
          state = SubscriptionState.active;
          debugPrint(
            '🔍 Re-Forced state to active based on valid future expiry date',
          );
        }
      }

      // Get product ID from multiple possible field names
      final productId =
          data['subscription_plan'] as String? ??
          data['subscription_product_id'] as String?;

      debugPrint(
        '🔍 Final Check: state=$state, productId=$productId, expiryDate=$expiryDate',
      );

      return SubscriptionStatus(
        state: state,
        productId: productId,
        expiryDate: expiryDate,
        autoRenew: data['auto_renew'] as bool? ?? false,
        paymentGateway: data['payment_gateway'] as String?,
      );
    } catch (e, st) {
      debugPrint('🔍 _parseSubscriptionStatus error: $e');
      debugPrintStack(stackTrace: st);
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
