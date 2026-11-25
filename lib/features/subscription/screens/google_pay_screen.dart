import 'package:sanad_app/core/l10n/coaching_wording.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_android/pay_android.dart';
import 'package:pay_platform_interface/core/payment_item.dart';
import 'package:pay_platform_interface/pay_channel.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapists/services/booking_service.dart';
import '../models/subscription_product.dart';
import '../providers/subscription_provider.dart';
import '../services/payment_gateway_service.dart';

/// Google Pay payment screen (Android only) using `pay_android` directly
/// without pulling in `pay_ios` / PassKit on iOS.
///
/// When [bookingId] is non-null the screen confirms a booking payment on
/// success instead of activating a subscription.
class GooglePayScreen extends ConsumerStatefulWidget {
  final SubscriptionProduct product;
  final String? bookingId;

  const GooglePayScreen({
    super.key,
    required this.product,
    this.bookingId,
  });

  @override
  ConsumerState<GooglePayScreen> createState() => _GooglePayScreenState();
}

class _GooglePayScreenState extends ConsumerState<GooglePayScreen> {
  final PayMethodChannel _payChannel = PayMethodChannel();
  late final Future<({PaymentConfiguration config, bool canPay})>
      _googlePaySetup;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _googlePaySetup = _initGooglePay();
  }

  Future<({PaymentConfiguration config, bool canPay})> _initGooglePay() async {
    final config = await PaymentConfiguration.fromAsset(
      'payment_profiles/default_payment_profile_google_pay.json',
    );
    if (defaultTargetPlatform != TargetPlatform.android) {
      return (config: config, canPay: false);
    }
    try {
      final canPay = await _payChannel.userCanPay(config);
      return (config: config, canPay: canPay);
    } catch (_) {
      return (config: config, canPay: false);
    }
  }

  Future<void> _launchGooglePay(PaymentConfiguration config) async {
    if (_isProcessing) return;
    final items = [
      PaymentItem(
        label: widget.product.title,
        amount: widget.product.price.toStringAsFixed(2),
        status: PaymentItemStatus.final_price,
      ),
    ];
    try {
      final result = await _payChannel.showPaymentSelector(config, items);
      await _onGooglePayResult(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Pay error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _onGooglePayResult(Map<String, dynamic> paymentResult) async {
    debugPrint('Google Pay Result: $paymentResult');
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final authState = ref.read(authProvider);

      // Extract the PayPal-issued token from the Google Pay tokenization data
      final tokenizationData =
          (paymentResult['paymentMethodData'] as Map?)?['tokenizationData']
              as Map?;
      final paymentToken = tokenizationData?['token'] as String?;

      final gateway = PaymentGatewayService();
      final result = await gateway.createGooglePayOrder(
        userId: authState.user?.uid ?? '',
        amount: widget.product.price,
        currency: 'USD',
        description: widget.product.title,
        productId: widget.product.id,
        paymentToken: paymentToken,
      );

      if (!mounted) return;

      if (result.success) {
        if (widget.bookingId != null) {
          await ref
              .read(bookingServiceProvider)
              .confirmBookingPayment(
                widget.bookingId!,
                result.orderId ?? '',
                paymentMethod: 'google_pay',
              );
        } else {
          await ref
              .read(subscriptionProvider.notifier)
              .confirmPaymentSubscription(
                orderId: result.orderId ?? '',
                product: widget.product,
                gateway: 'google_pay',
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
        title: Text(s.googlePayment),
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

              // Google Pay icon
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
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'G',
                          style: TextStyle(
                            color: const Color(0xFF4285F4),
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        Text(
                          'Pay',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 28,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                s.googlePayment,
                style: AppTypography.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
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
                  color: const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.3),
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
                                      : CoachingWording.any(widget.product.description)),
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

              // Google Pay Button
              FutureBuilder<({PaymentConfiguration config, bool canPay})>(
                future: _googlePaySetup,
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
                  final setup = snapshot.data!;
                  if (!setup.canPay) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: RawGooglePayButton(
                        paymentConfiguration: setup.config,
                        type: GooglePayButtonType.pay,
                        theme: GooglePayButtonTheme.dark,
                        onPressed: () => _launchGooglePay(setup.config),
                      ),
                    ),
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
