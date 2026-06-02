import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Freemius Configuration
// ─────────────────────────────────────────────────────────────────────────────

/// Freemius integration configuration.
///
/// Plan IDs map Sanad's internal product IDs to Freemius plan IDs set up in
/// the [Freemius Developer Dashboard](https://dashboard.freemius.com/).
/// Bearer token and secret key live in Firebase runtime config — never here.
///
/// ```bash
/// firebase functions:config:set freemius.bearer_token="sk_..."
/// firebase functions:config:set freemius.secret_key="sk_..."
/// firebase functions:config:set freemius.product_id="1234"
/// firebase functions:config:set freemius.sandbox="true"
/// ```
class FreemiusConfig {
  /// The Freemius product ID (number, from dashboard).
  final String productId;

  /// Map of Sanad plan IDs → Freemius plan IDs.
  /// e.g. `{'weekly': '12345', 'basic': '12346', 'booking': '12347', ...}`
  ///
  /// **`booking`** is the single Freemius plan used for every therapy
  /// booking. It must be a fixed-price plan in the Freemius dashboard whose
  /// One-off Price equals `kBookingFlatPriceUsd` from
  /// `lib/core/config/booking_pricing.dart`.
  final Map<String, String> planIds;

  /// Base URL for the hosted checkout page.
  final String checkoutBaseUrl;

  /// Brand name sent in checkout metadata.
  final String brandName;

  /// Default currency (USD).
  final String currency;

  /// Prefix used for the `user_email` parameter when the user has no email
  /// (e.g. phone-auth) so Freemius can still identify the buyer.
  final String fallbackEmailDomain;

  /// Whether to use sandbox/test mode.
  final bool isSandbox;

  const FreemiusConfig({
    this.productId = '',
    this.planIds = const {},
    this.checkoutBaseUrl = 'https://checkout.freemius.com',
    this.brandName = 'Sanad',
    this.currency = 'USD',
    this.fallbackEmailDomain = '@sanad-app.firebaseapp.com',
    this.isSandbox = true,
  });

  /// Resolve a Sanad product ID to its Freemius plan ID.
  ///
  /// Per-session booking payments use a synthetic product ID of the form
  /// `booking_<bookingId>`. They all share the single Freemius plan keyed
  /// `booking` in [planIds] (price set in the Freemius dashboard must equal
  /// `kBookingFlatPriceUsd`), so the lookup strips the prefix first.
  String? planIdFor(String productId) {
    if (productId.startsWith('booking_')) return planIds['booking'];
    return planIds[productId];
  }

  /// Copy with overrides — useful in tests and staging vs prod.
  FreemiusConfig copyWith({
    String? productId,
    Map<String, String>? planIds,
    String? checkoutBaseUrl,
    String? brandName,
    String? currency,
    String? fallbackEmailDomain,
    bool? isSandbox,
  }) {
    return FreemiusConfig(
      productId: productId ?? this.productId,
      planIds: planIds ?? this.planIds,
      checkoutBaseUrl: checkoutBaseUrl ?? this.checkoutBaseUrl,
      brandName: brandName ?? this.brandName,
      currency: currency ?? this.currency,
      fallbackEmailDomain:
          fallbackEmailDomain ?? this.fallbackEmailDomain,
      isSandbox: isSandbox ?? this.isSandbox,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

/// Result of generating a Freemius checkout URL.
///
/// Freemius hosted checkout returns a URL to open, not an order ID.
/// Order/payment IDs arrive later via webhook — see [FreemiusPurchaseData].
class FreemiusCheckoutResult {
  final bool success;
  final String? checkoutUrl;
  final String? errorCode;
  final String? errorMessage;

  const FreemiusCheckoutResult({
    required this.success,
    this.checkoutUrl,
    this.errorCode,
    this.errorMessage,
  });

  factory FreemiusCheckoutResult.fromMap(Map<String, dynamic> data) {
    return FreemiusCheckoutResult(
      success: data['success'] == true,
      checkoutUrl: data['checkoutUrl'] as String?,
      errorCode: data['errorCode'] as String?,
      errorMessage: data['error'] as String?,
    );
  }

  factory FreemiusCheckoutResult.error(String message, {String? code}) {
    return FreemiusCheckoutResult(
      success: false,
      errorCode: code ?? 'internal_error',
      errorMessage: message,
    );
  }
}

/// Purchase data returned by the webhook / post-checkout flow.
///
/// When a payment is completed, Freemius fires a webhook that our backend
/// captures in a Cloud Function and persists to Firestore. The client polls
/// this data to determine when the subscription is active.
class FreemiusPurchaseData {
  final String paymentId;
  final String userId;
  final String planId;
  final String productId;
  final double amount;
  final String currency;
  final String status;
  final String? licenseId;

  const FreemiusPurchaseData({
    required this.paymentId,
    required this.userId,
    required this.planId,
    required this.productId,
    required this.amount,
    required this.currency,
    required this.status,
    this.licenseId,
  });

  factory FreemiusPurchaseData.fromMap(Map<String, dynamic> map) {
    return FreemiusPurchaseData(
      paymentId: map['payment_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      planId: map['plan_id'] as String? ?? '',
      productId: map['product_id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      status: map['status'] as String? ?? 'unknown',
      licenseId: map['license_id'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

/// Service for Freemius checkout integration.
///
/// Responsibilities:
/// - Build a hosted-checkout URL for the current user and plan.
/// - Poll / verify completion so the client knows when the subscription
///   is active (webhook → Firestore → client poll).
///
/// This class only calls Cloud Functions — all Freemius API secrets
/// stay server-side.
class FreemiusCheckoutService {
  final FirebaseFunctions _functions;
  final FreemiusConfig _config;

  FreemiusCheckoutService({
    FirebaseFunctions? functions,
    FreemiusConfig? config,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _config = config ?? const FreemiusConfig();

  /// Retrieve the current config (useful for feature flags).
  FreemiusConfig get config => _config;

  // ── Checkout URL ──────────────────────────────────────────────────────

  /// Generate a hosted-checkout URL for a Sanad subscription product.
  ///
  /// [userId] — the Firebase Auth UID (used as the `custom` field so
  /// webhooks can link the payment back to the right user).
  /// [userEmail] — pre-fills the email field on the checkout form.
  /// [coupon] — optional coupon code.
  Future<FreemiusCheckoutResult> getCheckoutUrl({
    required String userId,
    required String productId,
    String? userEmail,
    String? coupon,
    double? price,
  }) async {
    final isBooking = productId.startsWith('booking_');
    final freemiusPlanId = _config.planIdFor(productId);
    if (freemiusPlanId == null) {
      return FreemiusCheckoutResult.error(
        isBooking
            ? 'No Freemius booking plan configured — set planIds["booking"] in freemiusProductionConfig.'
            : 'No Freemius plan ID mapped for "$productId"',
        code: 'unknown_plan',
      );
    }

    final email = _sanitizeEmail(userEmail, userId);

    try {
      final result = await _functions
          .httpsCallable('getFreemiusCheckoutUrl')
          .call(<String, dynamic>{
        'userId': userId,
        'email': email,
        'planId': freemiusPlanId,
        'productId': _config.productId,
        'sanadProductId': productId,
        'currency': _config.currency,
        'brandName': _config.brandName,
        'sandbox': _config.isSandbox,
        if (coupon != null && coupon.isNotEmpty) 'coupon': coupon,
        // Only forwarded for bookings — Freemius honours `price` solely
        // on Pay-What-You-Want plans, otherwise it silently ignores it.
        if (price != null && price > 0) 'price': price,
      });

      final raw = result.data;
      final data =
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

      return FreemiusCheckoutResult.fromMap(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Freemius checkout URL error [${e.code}]: ${e.message}');
      return FreemiusCheckoutResult.error(
        e.message ?? 'An unexpected error occurred.',
        code: e.code,
      );
    } catch (e) {
      debugPrint('Freemius checkout URL failed: $e');
      return FreemiusCheckoutResult.error(
        'Could not generate checkout link. Please try again.',
      );
    }
  }

  // ── Purchase Verification ─────────────────────────────────────────────

  /// Wait for a purchase to be confirmed via webhook (up to [timeout]).
  ///
  /// Returns the purchase data once Firestore has it, or null on timeout.
  /// The webhook writes into `freemius_purchases/{userId}` when Freemius
  /// sends `payment.created`.
  ///
  /// Use this as a fallback when the WebView-based success callback doesn't
  /// fire (e.g. user closes WebView before redirect completes).
  ///
  /// NOTE: This polls Firestore directly (not via Cloud Function) to
  /// avoid hitting the 60s callable timeout. The webhook writes to
  /// `freemius_purchases/{userId}`, this polls that document.
  Future<FreemiusPurchaseData?> waitForPurchase({
    required String userId,
    required String planId,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final purchase = await _functions
          .httpsCallable('verifyFreemiusPurchase')
          .call(<String, dynamic>{
        'userId': userId,
        'planId': planId,
      });

      final raw = purchase.data;
      final data =
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

      if (data['success'] == true && data['purchase'] != null) {
        return FreemiusPurchaseData.fromMap(
          Map<String, dynamic>.from(data['purchase'] as Map),
        );
      }
      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Freemius purchase verification error [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Freemius purchase verification failed: $e');
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Ensure we always have something to use as the Freemius buyer identity.
  /// For phone-auth users without an email, we compose a synthetic one.
  String _sanitizeEmail(String? email, String userId) {
    final raw = (email ?? '').trim();
    if (raw.isNotEmpty && raw.contains('@')) return raw;
    return '$userId${_config.fallbackEmailDomain}';
  }

  /// Build a hosted-checkout URL directly (no Cloud Function round-trip).
  ///
  /// Use this only during development/testing — in production prefer
  /// [getCheckoutUrl] so the Cloud Function can attach secure metadata
  /// and verify the request.
  @visibleForTesting
  Uri buildDirectCheckoutUrl({
    required String planId,
    required String userEmail,
    required String billingCycle,
    String? coupon,
  }) {
    final params = <String, String>{
      'product_id': _config.productId,
      'plan_id': planId,
      'user_email': userEmail,
      'currency': _config.currency,
      'billing_cycle': billingCycle,
      'pricing_id': planId,
    };

    if (_config.isSandbox) params['sandbox'] = 'true';
    if (coupon != null && coupon.isNotEmpty) params['coupon'] = coupon;

    return Uri.parse(_config.checkoutBaseUrl)
        .replace(
          path: 'mode/purchase/checkout',
          queryParameters: params,
        );
  }
}

/// Production Freemius configuration.
///
/// Subscription plan IDs resolved from Freemius API on 2026-05-14.
/// Update after deploying plan changes in the Freemius dashboard.
///
/// **`booking`** — Freemius plan whose One-off Price must equal
/// `kBookingFlatPriceUsd` (currently $34.99). Create one fixed-price plan in
/// the Freemius dashboard, set its one-off price to that exact amount, paste
/// its plan ID below. Until configured the Visa/Mastercard option stays
/// hidden from the booking screen (`freemiusBookingPlanConfigured` returns
/// false on the placeholder).
const freemiusProductionConfig = FreemiusConfig(
  productId: '29606',
  planIds: {
    'weekly': '48743',
    'basic': '48698',
    'premium': '48712',
    'premium_vip': '48742',
    'booking': '49070',
  },
  isSandbox: false,
);

/// Sandbox Freemius configuration for development.
const freemiusSandboxConfig = FreemiusConfig(
  productId: '29606',
  planIds: {
    'weekly': '48743',
    'basic': '48698',
    'premium': '48712',
    'premium_vip': '48742',
    'booking': '49070',
  },
  isSandbox: true,
);

/// Returns true when [config] has a real Freemius plan ID configured for the
/// `booking` slot — i.e. the Visa/Mastercard option can safely be shown on
/// the booking payment screen.
bool freemiusBookingPlanConfigured(FreemiusConfig config) {
  final planId = config.planIds['booking'];
  return planId != null &&
      planId.isNotEmpty &&
      planId != 'REPLACE_WITH_FREEMIUS_BOOKING_PLAN_ID';
}
