import 'subscription_product.dart';

/// Arguments passed via `GoRouter`'s `extra` to a payment gateway screen.
///
/// When [bookingId] is non-null the gateway screen treats the payment as a
/// per-session booking charge: on success it calls
/// `BookingService.confirmBookingPayment` instead of activating a subscription.
/// When [bookingId] is null the gateway falls back to its original behaviour
/// (activate a subscription via `subscriptionProvider`).
class PaymentRouteArgs {
  final SubscriptionProduct product;
  final String? bookingId;

  const PaymentRouteArgs({required this.product, this.bookingId});

  /// Decode a `state.extra` payload that may be:
  ///   * `PaymentRouteArgs` (preferred — used by the booking flow)
  ///   * `SubscriptionProduct` (legacy — subscription flow)
  ///   * `Map<String, dynamic>` JSON of a SubscriptionProduct (legacy)
  static PaymentRouteArgs fromExtra(Object? extra) {
    if (extra is PaymentRouteArgs) return extra;
    if (extra is SubscriptionProduct) {
      return PaymentRouteArgs(product: extra);
    }
    return PaymentRouteArgs(
      product: SubscriptionProduct.fromJson(extra as Map<String, dynamic>),
    );
  }
}
