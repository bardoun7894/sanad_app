import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapists/services/booking_service.dart';
import '../models/subscription_product.dart';
import '../providers/subscription_provider.dart';
import '../services/payment_gateway_service.dart';

/// PayPal payment screen using WebView for checkout.
///
/// When [bookingId] is non-null the screen confirms a booking payment on
/// success instead of activating a subscription.
class PayPalPaymentScreen extends ConsumerStatefulWidget {
  final SubscriptionProduct product;
  final String? bookingId;

  const PayPalPaymentScreen({
    super.key,
    required this.product,
    this.bookingId,
  });

  @override
  ConsumerState<PayPalPaymentScreen> createState() =>
      _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends ConsumerState<PayPalPaymentScreen> {
  bool _isCreatingOrder = true;
  bool _isWebViewLoading = true;
  String? _errorMessage;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _createPayPalOrder();
  }

  Future<void> _createPayPalOrder() async {
    try {
      final gateway = PaymentGatewayService();
      final authState = ref.read(authProvider);
      final result = await gateway.createPayPalOrder(
        userId: authState.user?.uid ?? '',
        amount: widget.product.price,
        currency: 'USD',
        description: widget.product.title,
        productId: widget.product.id,
      );

      if (!mounted) return;

      if (result.success && result.approvalUrl != null) {
        _initWebView(result.approvalUrl!);
        setState(() {
          _isCreatingOrder = false;
        });
      } else {
        setState(() {
          _isCreatingOrder = false;
          _errorMessage = result.errorMessage ?? 'Failed to create PayPal order';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingOrder = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _initWebView(String approvalUrl) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isWebViewLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isWebViewLoading = false);
          },
          onNavigationRequest: (request) =>
              _handleNavigationRequest(request),
          onWebResourceError: (error) {
            debugPrint('PayPal WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(approvalUrl));
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final url = request.url;

    // Check for success return URL
    if (url.startsWith(PaymentConfig.returnUrl) ||
        url.contains('sanad://payment/success') ||
        (url.contains('success') && url.contains('token') && url.contains('PayerID'))) {
      _handlePaymentSuccess(url);
      return NavigationDecision.prevent;
    }

    // Check for cancel return URL — match only the specific deep-link scheme,
    // not any PayPal page that happens to contain the word "cancel"
    if (url.startsWith(PaymentConfig.cancelUrl) ||
        url.startsWith('sanad://payment/cancel')) {
      _handlePaymentCancelled();
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _handlePaymentSuccess(String url) async {
    final s = ref.read(stringsProvider);

    setState(() => _isWebViewLoading = true);

    try {
      // Extract PayerID and token from URL
      final uri = Uri.parse(url);
      final payerId = uri.queryParameters['PayerID'];
      final token = uri.queryParameters['token'];

      if (payerId != null && token != null) {
        final gateway = PaymentGatewayService();
        final captured = await gateway.capturePayPalOrder(orderId: token);

        if (captured) {
          // Cloud Function `capturePayPalOrder` captures funds + writes a row
          // into `payments/` but does NOT update the user's subscription_*
          // fields. For subscription flow: mirror entitlement client-side.
          // For booking flow: confirm the booking instead.
          if (widget.bookingId != null) {
            await ref
                .read(bookingServiceProvider)
                .confirmBookingPayment(
                  widget.bookingId!,
                  token,
                  paymentMethod: 'paypal',
                );
          } else {
            await ref
                .read(subscriptionProvider.notifier)
                .confirmPaymentSubscription(
                  orderId: token,
                  product: widget.product,
                  gateway: 'paypal',
                );
          }

          if (mounted) {
            context.go('/payment-success');
          }
          return;
        }
      }

      // Capture failed — surface the error, do NOT fake a success screen.
      if (mounted) {
        _showError(s.paymentFailed);
      }
    } catch (e) {
      _showError('${s.paymentFailed}: $e');
    }
  }

  void _handlePaymentCancelled() {
    final s = ref.read(stringsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.paymentCancelled),
          backgroundColor: AppColors.warning,
        ),
      );
      context.pop();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isWebViewLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.paypalPayment),
        centerTitle: true,
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelConfirmation(context, s),
        ),
      ),
      body: _buildBody(isDark, s),
    );
  }

  Widget _buildBody(bool isDark, dynamic s) {
    // Show error state
    if (_errorMessage != null) {
      return _buildErrorState(isDark, s);
    }

    // Show loading while creating order
    if (_isCreatingOrder) {
      return _buildCreatingOrderState(isDark, s);
    }

    // Show WebView with PayPal checkout
    return Stack(
      children: [
        if (_webViewController != null)
          WebViewWidget(controller: _webViewController!),
        if (_isWebViewLoading)
          Container(
            color: isDark
                ? AppColors.backgroundDark.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF0070BA)),
                  const SizedBox(height: 16),
                  Text(
                    s.processingPayment,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCreatingOrderState(bool isDark, dynamic s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PayPal Logo
            Container(
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
                      'Pay',
                      style: TextStyle(
                        color: const Color(0xFF003087),
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    Text(
                      'Pal',
                      style: TextStyle(
                        color: const Color(0xFF0070BA),
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Color(0xFF0070BA)),
            const SizedBox(height: 16),
            Text(
              s.paypalRedirect,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, dynamic s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              s.paymentFailed,
              style: AppTypography.headingSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isCreatingOrder = true;
                  _errorMessage = null;
                });
                _createPayPalOrder();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0070BA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                s.cancel,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, dynamic s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.cancelPayment),
        content: Text(s.cancelPaymentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child:
                Text(s.yes, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
