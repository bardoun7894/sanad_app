import 'dart:convert';
import 'package:http/http.dart' as http;

/// Payment gateway configuration
class PaymentConfig {
  // PayPal Configuration
  static const String paypalClientId = 'YOUR_PAYPAL_CLIENT_ID';
  static const String paypalSecret = 'YOUR_PAYPAL_SECRET';
  static const bool paypalSandbox = true; // Set to false for production

  static String get paypalBaseUrl => paypalSandbox
      ? 'https://api-m.sandbox.paypal.com'
      : 'https://api-m.paypal.com';

  // 2Checkout Configuration
  static const String twoCheckoutMerchantCode = 'YOUR_2CHECKOUT_MERCHANT_CODE';
  static const String twoCheckoutSecretKey = 'YOUR_2CHECKOUT_SECRET_KEY';
  static const bool twoCheckoutSandbox = true; // Set to false for production

  static String get twoCheckoutBaseUrl => twoCheckoutSandbox
      ? 'https://sandbox.2checkout.com'
      : 'https://www.2checkout.com';

  // App return URLs (deep links)
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

/// Service for handling payment gateway API calls
class PaymentGatewayService {
  String? _paypalAccessToken;
  DateTime? _tokenExpiry;

  /// Get PayPal access token
  Future<String?> _getPayPalAccessToken() async {
    // Return cached token if still valid
    if (_paypalAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _paypalAccessToken;
    }

    try {
      final credentials = base64Encode(
        utf8.encode('${PaymentConfig.paypalClientId}:${PaymentConfig.paypalSecret}'),
      );

      final response = await http.post(
        Uri.parse('${PaymentConfig.paypalBaseUrl}/v1/oauth2/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _paypalAccessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(
          Duration(seconds: data['expires_in'] - 60),
        );
        return _paypalAccessToken;
      }
    } catch (e) {
      print('Error getting PayPal token: $e');
    }
    return null;
  }

  /// Create PayPal subscription for user
  Future<PaymentResult> createPayPalSubscription({
    required String userId,
    required String planId,
    required String userEmail,
  }) async {
    try {
      final token = await _getPayPalAccessToken();
      if (token == null) {
        return PaymentResult(
          success: false,
          errorMessage: 'Failed to authenticate with PayPal',
        );
      }

      final response = await http.post(
        Uri.parse('${PaymentConfig.paypalBaseUrl}/v1/billing/subscriptions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'PayPal-Request-Id': 'SANAD-${userId}-${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'plan_id': planId,
          'subscriber': {
            'email_address': userEmail,
          },
          'custom_id': userId, // This links the subscription to our user
          'application_context': {
            'brand_name': 'Sanad',
            'locale': 'ar-SA',
            'shipping_preference': 'NO_SHIPPING',
            'user_action': 'SUBSCRIBE_NOW',
            'payment_method': {
              'payer_selected': 'PAYPAL',
              'payee_preferred': 'IMMEDIATE_PAYMENT_REQUIRED',
            },
            'return_url': PaymentConfig.returnUrl,
            'cancel_url': PaymentConfig.cancelUrl,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final links = data['links'] as List;
        final approvalLink = links.firstWhere(
          (link) => link['rel'] == 'approve',
          orElse: () => null,
        );

        return PaymentResult(
          success: true,
          approvalUrl: approvalLink?['href'],
          paymentId: data['id'],
        );
      } else {
        final error = jsonDecode(response.body);
        return PaymentResult(
          success: false,
          errorMessage: error['message'] ?? 'PayPal subscription creation failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Error creating PayPal subscription: $e',
      );
    }
  }

  /// Create PayPal one-time payment order
  Future<PaymentResult> createPayPalOrder({
    required String userId,
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      final token = await _getPayPalAccessToken();
      if (token == null) {
        return PaymentResult(
          success: false,
          errorMessage: 'Failed to authenticate with PayPal',
        );
      }

      final response = await http.post(
        Uri.parse('${PaymentConfig.paypalBaseUrl}/v2/checkout/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'PayPal-Request-Id': 'SANAD-ORDER-${userId}-${DateTime.now().millisecondsSinceEpoch}',
        },
        body: jsonEncode({
          'intent': 'CAPTURE',
          'purchase_units': [
            {
              'reference_id': userId,
              'description': description,
              'custom_id': userId,
              'amount': {
                'currency_code': currency,
                'value': amount.toStringAsFixed(2),
              },
            },
          ],
          'application_context': {
            'brand_name': 'Sanad',
            'locale': 'ar-SA',
            'shipping_preference': 'NO_SHIPPING',
            'user_action': 'PAY_NOW',
            'return_url': PaymentConfig.returnUrl,
            'cancel_url': PaymentConfig.cancelUrl,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final links = data['links'] as List;
        final approvalLink = links.firstWhere(
          (link) => link['rel'] == 'approve',
          orElse: () => null,
        );

        return PaymentResult(
          success: true,
          approvalUrl: approvalLink?['href'],
          orderId: data['id'],
        );
      } else {
        final error = jsonDecode(response.body);
        return PaymentResult(
          success: false,
          errorMessage: error['message'] ?? 'PayPal order creation failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Error creating PayPal order: $e',
      );
    }
  }

  /// Create 2Checkout hosted checkout URL
  Future<PaymentResult> create2CheckoutOrder({
    required String userId,
    required String userEmail,
    required String userName,
    required double amount,
    required String productName,
  }) async {
    try {
      // Generate signature for 2Checkout
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final orderData = {
        'merchant': PaymentConfig.twoCheckoutMerchantCode,
        'dynamic': '1',
        'prod': productName,
        'price': amount.toStringAsFixed(2),
        'qty': '1',
        'type': 'product',
        'name': userName,
        'email': userEmail,
        'currency': 'USD',
        'custom_product_id': userId,
        'return_url': PaymentConfig.returnUrl,
        'cancel_url': PaymentConfig.cancelUrl,
        'tpl': 'default',
        'test': PaymentConfig.twoCheckoutSandbox ? '1' : '0',
      };

      // Build checkout URL
      final queryString = orderData.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final checkoutUrl = '${PaymentConfig.twoCheckoutBaseUrl}/checkout/purchase?$queryString';

      return PaymentResult(
        success: true,
        approvalUrl: checkoutUrl,
        orderId: 'TCO-$userId-$timestamp',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Error creating 2Checkout order: $e',
      );
    }
  }

  /// Verify PayPal payment was captured (call after user returns)
  Future<bool> verifyPayPalPayment(String orderId) async {
    try {
      final token = await _getPayPalAccessToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('${PaymentConfig.paypalBaseUrl}/v2/checkout/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'COMPLETED';
      }
    } catch (e) {
      print('Error verifying PayPal payment: $e');
    }
    return false;
  }

  /// Capture PayPal payment after approval
  Future<bool> capturePayPalPayment(String orderId) async {
    try {
      final token = await _getPayPalAccessToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('${PaymentConfig.paypalBaseUrl}/v2/checkout/orders/$orderId/capture'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['status'] == 'COMPLETED';
      }
    } catch (e) {
      print('Error capturing PayPal payment: $e');
    }
    return false;
  }
}
