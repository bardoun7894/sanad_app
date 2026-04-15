import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/subscription_product.dart';
import '../providers/subscription_provider.dart';
import '../services/payment_gateway_service.dart';

/// Card payment screen — clean Visa/Mastercard form, no PayPal branding.
/// Uses PayPal's hosted card fields behind the scenes via WebView.
class CardPaymentScreen extends ConsumerStatefulWidget {
  final SubscriptionProduct product;

  const CardPaymentScreen({super.key, required this.product});

  @override
  ConsumerState<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends ConsumerState<CardPaymentScreen> {
  bool _isCreatingOrder = true;
  bool _isWebViewLoading = true;
  String? _errorMessage;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _createOrder();
  }

  Future<void> _createOrder() async {
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
        _initWebView(result.approvalUrl!, result.orderId ?? '');
        setState(() => _isCreatingOrder = false);
      } else {
        setState(() {
          _isCreatingOrder = false;
          _errorMessage =
              result.errorMessage ?? 'Failed to create payment order';
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

  void _initWebView(String approvalUrl, String orderId) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'CardPayment',
        onMessageReceived: (message) => _handleMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isWebViewLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isWebViewLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith(PaymentConfig.returnUrl) ||
                (url.contains('success') &&
                    url.contains('token') &&
                    url.contains('PayerID'))) {
              _handlePaymentSuccess(url);
              return NavigationDecision.prevent;
            }
            if (url.startsWith(PaymentConfig.cancelUrl) ||
                url.contains('sanad://payment/cancel')) {
              _handlePaymentCancelled();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      // Load the approval URL directly — PayPal checkout with card option
      ..loadRequest(Uri.parse(approvalUrl));
  }

  void _handleMessage(String message) {
    try {
      final data = json.decode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'success') {
        _handlePaymentSuccess(data['url'] as String? ?? '');
      } else if (type == 'cancel') {
        _handlePaymentCancelled();
      } else if (type == 'error') {
        _showError(data['message'] as String? ?? 'Payment failed');
      }
    } catch (_) {}
  }

  Future<void> _handlePaymentSuccess(String url) async {
    final s = ref.read(stringsProvider);
    setState(() => _isWebViewLoading = true);

    try {
      final uri = Uri.parse(url);
      final payerId = uri.queryParameters['PayerID'];
      final token = uri.queryParameters['token'];

      if (payerId != null && token != null) {
        final gateway = PaymentGatewayService();
        final captured = await gateway.capturePayPalOrder(orderId: token);

        if (captured) {
          // Cloud Function capturePayPalOrder captures funds + inserts a
          // payments/ record but does NOT update users/{uid}.subscription_*.
          // Mirror the entitlement client-side so feature gating unlocks.
          await ref
              .read(subscriptionProvider.notifier)
              .confirmPaymentSubscription(
                orderId: token,
                product: widget.product,
                gateway: 'paypal_card',
              );
          if (mounted) context.go('/payment-success');
          return;
        }
      }

      // Capture failed — don't fake success.
      _showError(s.paymentFailed);
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
        title: Text(s.creditCard),
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
    if (_errorMessage != null) return _buildErrorState(isDark, s);
    if (_isCreatingOrder) return _buildLoadingState(isDark, s);

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
                  const CircularProgressIndicator(color: AppColors.primary),
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

  Widget _buildLoadingState(bool isDark, dynamic s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              child: const Center(
                child: Icon(
                  Icons.credit_card_rounded,
                  size: 48,
                  color: Color(0xFF1A1F71),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              s.processingPayment,
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
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isCreatingOrder = true;
                  _errorMessage = null;
                });
                _createOrder();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                s.cancel,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
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
            child: Text(s.yes,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // Primary flow loads approvalUrl directly in WebView — no HTML wrapper needed.
}

