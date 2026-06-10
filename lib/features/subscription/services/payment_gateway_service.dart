import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Payment gateway configuration
///
/// PayPal client ID / secret and environment live in the Firebase Cloud
/// Functions runtime config — never in this source file. See
/// `backend/cloud-functions/` for the server-side wiring.
class PaymentConfig {
  // App return URLs (deep links) — consumed by WebView navigation callbacks
  // to detect PayPal approve/cancel redirects.
  static const String returnUrl = 'sanad://payment/success';
  static const String cancelUrl = 'sanad://payment/cancel';
}

/// Result of payment initiation
class PaymentResult {
  final bool success;
  final String? approvalUrl;
  final String? paymentId;
  final String? orderId;
  final String? errorMessage;

  PaymentResult({
    required this.success,
    this.approvalUrl,
    this.paymentId,
    this.orderId,
    this.errorMessage,
  });
}

/// Service for handling payment gateway API calls via Cloud Functions
class PaymentGatewayService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ─── Google Pay ───────────────────────────────────────────────────────────

  /// Create Google Pay payment order
  Future<PaymentResult> createGooglePayOrder({
    required String userId,
    required double amount,
    required String currency,
    required String description,
    String? productId,
    String? paymentToken,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('createGooglePayOrder')
          .call({
            'userId': userId,
            'amount': amount,
            'currency': currency,
            'description': description,
            if (productId != null) 'productId': productId,
            if (paymentToken != null) 'paymentToken': paymentToken,
          });

      final raw = result.data;
      final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

      if (data['success'] == true) {
        return PaymentResult(success: true, orderId: data['orderId'] as String?);
      } else {
        return PaymentResult(
          success: false,
          errorMessage: data['error'] as String? ?? 'Google Pay order failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Error creating Google Pay order: $e',
      );
    }
  }

  // NOTE: Google Pay / Apple Pay verification happens server-side inside
  // `createGooglePayOrder`. The Cloud Function processes the tokenized
  // payment through PayPal and only returns success=true when PayPal has
  // already captured funds — there is no separate client-side verify step.

  // ─── PayPal ───────────────────────────────────────────────────────────────

  /// Create PayPal order via Cloud Function
  Future<PaymentResult> createPayPalOrder({
    required String userId,
    required double amount,
    required String currency,
    required String description,
    required String productId,
    String? bookingId,
    int daysValid = 30,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('createPayPalOrder')
          .call({
            'userId': userId,
            'amount': amount,
            'currency': currency,
            'description': description,
            'productId': productId,
            // Threaded so the Cloud Function can activate the right entitlement
            // server-side after capture (booking vs subscription, valid days).
            'bookingId': bookingId,
            'daysValid': daysValid,
            'returnUrl': PaymentConfig.returnUrl,
            'cancelUrl': PaymentConfig.cancelUrl,
          });

      final raw2 = result.data;
      final data = raw2 is Map ? Map<String, dynamic>.from(raw2) : <String, dynamic>{};

      if (data['success'] == true) {
        return PaymentResult(
          success: true,
          approvalUrl: data['approvalUrl'] as String?,
          orderId: data['orderId'] as String?,
        );
      } else {
        return PaymentResult(
          success: false,
          errorMessage: data['error'] as String? ?? 'PayPal order creation failed',
        );
      }
    } catch (e) {
      debugPrint('Error creating PayPal order: $e');
      return PaymentResult(
        success: false,
        errorMessage: 'Error creating PayPal order: $e',
      );
    }
  }

  /// Capture (finalize) a PayPal order after user approval
  Future<bool> capturePayPalOrder({required String orderId}) async {
    try {
      final result = await _functions
          .httpsCallable('capturePayPalOrder')
          .call({'orderId': orderId});

      final raw3 = result.data;
      final data3 = raw3 is Map ? Map<String, dynamic>.from(raw3) : <String, dynamic>{};
      return data3['success'] == true;
    } catch (e) {
      debugPrint('Error capturing PayPal order: $e');
      return false;
    }
  }
}
