import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/subscription_provider.dart';
import '../services/payment_gateway_service.dart';

class PaymentWebViewScreen extends ConsumerStatefulWidget {
  final String paymentUrl;
  final String paymentType; // 'paypal' or '2checkout'
  final String? orderId;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.paymentType,
    this.orderId,
  });

  @override
  ConsumerState<PaymentWebViewScreen> createState() =>
      _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            return _handleNavigationRequest(request);
          },
          onWebResourceError: (error) {
            print('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final url = request.url;

    // Check for success return URL
    if (url.startsWith('sanad://payment/success') ||
        url.contains('success') && url.contains('token')) {
      _handlePaymentSuccess(url);
      return NavigationDecision.prevent;
    }

    // Check for cancel return URL
    if (url.startsWith('sanad://payment/cancel') ||
        url.contains('cancel')) {
      _handlePaymentCancelled();
      return NavigationDecision.prevent;
    }

    // Allow navigation for payment gateway URLs
    return NavigationDecision.navigate;
  }

  Future<void> _handlePaymentSuccess(String url) async {
    final s = ref.read(stringsProvider);

    // Show loading while verifying
    setState(() => _isLoading = true);

    try {
      if (widget.paymentType == 'paypal' && widget.orderId != null) {
        // Capture PayPal payment
        final gateway = PaymentGatewayService();
        final captured = await gateway.capturePayPalPayment(widget.orderId!);

        if (captured) {
          // Refresh subscription status
          await ref.read(subscriptionProvider.notifier).checkSubscription();

          if (mounted) {
            context.go('/payment-success');
          }
        } else {
          _showError(s.paymentFailed);
        }
      } else {
        // For 2Checkout, webhook will handle activation
        // Refresh subscription status
        await ref.read(subscriptionProvider.notifier).checkSubscription();

        if (mounted) {
          context.go('/payment-success');
        }
      }
    } catch (e) {
      _showError('${s.paymentFailed}: $e');
    }
  }

  void _handlePaymentCancelled() {
    final s = ref.read(stringsProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.paymentCancelled),
        backgroundColor: AppColors.warning,
      ),
    );

    context.pop();
  }

  void _showError(String message) {
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.paymentType == 'paypal' ? 'PayPal' : s.creditCard,
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelConfirmation(context, s),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: isDark
                  ? AppColors.backgroundDark.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.processingPayment,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
            child: Text(
              s.yes,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
