import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapists/services/booking_service.dart';
import '../models/subscription_product.dart';
import '../providers/subscription_provider.dart';
import '../services/freemius_checkout_service.dart';

/// Freemius hosted-checkout screen.
///
/// Opens the Freemius checkout page in a WebView. After the user completes
/// payment, they tap "Done" — the screen polls the backend until the webhook
/// confirms the purchase, then navigates to the success screen.
///
/// When [bookingId] is non-null the screen confirms a booking payment on
/// success instead of activating a subscription.
class FreemiusCheckoutScreen extends ConsumerStatefulWidget {
  final SubscriptionProduct product;
  final String? bookingId;

  const FreemiusCheckoutScreen({
    super.key,
    required this.product,
    this.bookingId,
  });

  @override
  ConsumerState<FreemiusCheckoutScreen> createState() =>
      _FreemiusCheckoutScreenState();
}

class _FreemiusCheckoutScreenState
    extends ConsumerState<FreemiusCheckoutScreen> {
  bool _isLoadingUrl = true;
  bool _isVerifying = false;
  String? _errorMessage;
  WebViewController? _webViewController;
  String? _checkoutUrl;
  Timer? _pollTimer;
  int _pollAttempts = 0;

  @override
  void initState() {
    super.initState();
    _generateCheckoutUrl();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Generate checkout URL ─────────────────────────────────────────────

  Future<void> _generateCheckoutUrl() async {
    try {
      final service = FreemiusCheckoutService(
        config: freemiusProductionConfig,
      );
      final authState = ref.read(authProvider);

      final result = await service.getCheckoutUrl(
        userId: authState.user?.uid ?? '',
        productId: widget.product.id,
        userEmail: authState.user?.email,
        // Only bookings forward a price override — the synthetic product
        // carries the therapist's per-hour rate. Subscriptions leave it
        // null so Freemius charges the plan's configured price.
        price: widget.bookingId != null ? widget.product.price : null,
      );

      if (!mounted) return;

      if (result.success && result.checkoutUrl != null) {
        setState(() {
          _checkoutUrl = result.checkoutUrl;
          _isLoadingUrl = false;
        });
        _initWebView(result.checkoutUrl!);
      } else {
        setState(() {
          _isLoadingUrl = false;
          _errorMessage =
               result.errorMessage ?? 'فشل إنشاء رابط الدفع';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingUrl = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ── WebView ───────────────────────────────────────────────────────────

  void _initWebView(String url) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted && _isVerifying) {
              setState(() => _isVerifying = false);
            }
          },
          onWebResourceError: (error) {
            debugPrint('Freemius WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  // ── Verification ──────────────────────────────────────────────────────

  Future<void> _verifyPurchase() async {
    if (_pollTimer != null) return;

    setState(() {
      _isVerifying = true;
      _pollAttempts = 0;
    });

    final service = FreemiusCheckoutService(
      config: freemiusProductionConfig,
    );
    final authState = ref.read(authProvider);
    final userId = authState.user?.uid;
    if (userId == null) {
      _showError('المستخدم غير مسجل الدخول');
      return;
    }

    // Poll every 3 seconds, up to 10 attempts (30 seconds total)
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollAttempts++;
      try {
        final purchase = await service.waitForPurchase(
          userId: userId,
          planId: widget.product.id,
        );

        if (!mounted) return;

        if (purchase != null) {
          timer.cancel();
          _pollTimer = null;
          await _activateSubscription(purchase);
          return;
        }
      } catch (_) {}

      if (_pollAttempts >= 10 && mounted) {
        timer.cancel();
        _pollTimer = null;
        setState(() => _isVerifying = false);
        _showError('لم يتم تأكيد الدفع بعد. قد يستغرق لحظة. '
            'يمكنك إغلاق الشاشة والتحقق من حالة اشتراكك.');
      }
    });
  }

  Future<void> _activateSubscription(dynamic purchase) async {
    try {
      if (widget.bookingId != null) {
        await ref
            .read(bookingServiceProvider)
            .confirmBookingPayment(
              widget.bookingId!,
              purchase.paymentId,
              paymentMethod: 'freemius_card',
            );
      } else {
        await ref.read(subscriptionProvider.notifier).confirmPaymentSubscription(
              orderId: purchase.paymentId,
              product: widget.product,
              gateway: 'freemius',
            );
      }

      if (mounted) {
        context.go('/payment-success');
      }
    } catch (e) {
      _showError('تم تأكيد الدفع ولكن فشل تفعيل الاشتراك: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isVerifying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _cancelCheckout() {
    _pollTimer?.cancel();
    if (mounted) context.pop();
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.product.title),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoadingUrl) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _checkoutUrl == null) {
      return _buildErrorState(isDark);
    }

    return Column(
      children: [
        // WebView
        Expanded(child: WebViewWidget(controller: _webViewController!)),

        // Bottom actions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isVerifying)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('جاري التحقق من الدفع...'),
                    ],
                  ),
                ),
              SanadButton(
                text: _isVerifying ? 'جاري التحقق...' : 'تم الدفع',
                onPressed: _isVerifying ? null : _verifyPurchase,
                isLoading: _isVerifying,
                variant: SanadButtonVariant.primary,
                isFullWidth: true,
              ),
              const SizedBox(height: 12),
              SanadButton(
                text: 'إلغاء',
                onPressed: _cancelCheckout,
                variant: SanadButtonVariant.ghost,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'حدث خطأ ما',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SanadButton(
              text: 'حاول مرة أخرى',
              onPressed: () {
                setState(() {
                  _isLoadingUrl = true;
                  _errorMessage = null;
                });
                _generateCheckoutUrl();
              },
            ),
          ],
        ),
      ),
    );
  }
}
