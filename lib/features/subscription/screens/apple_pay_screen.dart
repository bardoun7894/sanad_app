import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pay/pay.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapists/services/booking_service.dart';
import '../models/subscription_product.dart';
import '../providers/subscription_provider.dart';
import '../services/payment_gateway_service.dart';

/// Apple Pay payment screen using the `pay` package (iOS only).
///
/// When [bookingId] is non-null the screen confirms a booking payment on
/// success instead of activating a subscription.
class ApplePayScreen extends ConsumerStatefulWidget {
  final SubscriptionProduct product;
  final String? bookingId;

  const ApplePayScreen({
    super.key,
    required this.product,
    this.bookingId,
  });

  @override
  ConsumerState<ApplePayScreen> createState() => _ApplePayScreenState();
}

class _ApplePayScreenState extends ConsumerState<ApplePayScreen> {
  late final Future<PaymentConfiguration> _paymentConfiguration;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentConfiguration = PaymentConfiguration.fromAsset(
      'payment_profiles/default_payment_profile_apple_pay.json',
    );
  }

  Future<void> _onApplePayResult(Map<String, dynamic> paymentResult) async {
    debugPrint('Apple Pay Result: $paymentResult');
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final authState = ref.read(authProvider);

      // Extract the PayPal-issued token from the Apple Pay tokenization data
      final paymentData = paymentResult['token']?['paymentData'] as String?;

      final gateway = PaymentGatewayService();
      final result = await gateway.createGooglePayOrder(
        userId: authState.user?.uid ?? '',
        amount: widget.product.price,
        currency: 'USD',
        description: widget.product.title,
        productId: widget.product.id,
        paymentToken: paymentData,
      );

      if (!mounted) return;

      if (result.success) {
        if (widget.bookingId != null) {
          await ref
              .read(bookingServiceProvider)
              .confirmBookingPayment(
                widget.bookingId!,
                result.orderId ?? '',
                paymentMethod: 'apple_pay',
              );
        } else {
          await ref
              .read(subscriptionProvider.notifier)
              .confirmPaymentSubscription(
                orderId: result.orderId ?? '',
                product: widget.product,
                gateway: 'apple_pay',
              );
        }
        if (mounted) context.pushReplacementNamed('paymentSuccess');
      } else {
        _showError(result.errorMessage ?? 'Payment failed');
      }
    } catch (e) {
      _showError('Payment error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.applePayment),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // Apple Pay icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.apple,
                      size: 48,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                s.applePayment,
                style: AppTypography.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                s.googlePaySecure,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Product info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.id == 'chat_monthly'
                                ? s.chatSubscription
                                : (widget.product.id == 'call_hourly'
                                      ? s.therapyCall
                                      : widget.product.title),
                            style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.product.id == 'chat_monthly'
                                ? s.chatSubscriptionDesc
                                : (widget.product.id == 'call_hourly'
                                      ? s.therapyCallDesc
                                      : widget.product.description),
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${widget.product.price.toStringAsFixed(2)}',
                      style: AppTypography.headingMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Apple Pay Button or processing indicator
              FutureBuilder<PaymentConfiguration>(
                future: _paymentConfiguration,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_isProcessing) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 12),
                        ],
                      ),
                    );
                  }
                  return ApplePayButton(
                    paymentConfiguration: snapshot.data!,
                    paymentItems: [
                      PaymentItem(
                        label: widget.product.title,
                        amount: widget.product.price.toStringAsFixed(2),
                        status: PaymentItemStatus.final_price,
                      ),
                    ],
                    style: ApplePayButtonStyle.black,
                    type: ApplePayButtonType.buy,
                    margin: const EdgeInsets.only(top: 15.0),
                    onPaymentResult: _onApplePayResult,
                    loadingIndicator: const Center(
                      child: CircularProgressIndicator(),
                    ),
                    width: double.infinity,
                    height: 50,
                  );
                },
              ),

              const SizedBox(height: 16),

              // Cancel button
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    s.cancel,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
