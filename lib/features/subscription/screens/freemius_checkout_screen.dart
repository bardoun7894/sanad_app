import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/providers/system_settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/payment_webview.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapists/services/booking_service.dart';
import '../models/subscription_product.dart';
import '../providers/subscription_provider.dart';
import '../services/freemius_checkout_service.dart';

/// Freemius hosted-checkout screen.
///
/// Opens the Freemius checkout page in a WebView. Once the user completes the
/// order inside the Freemius page, the screen detects the payment
/// automatically — it polls the backend until the webhook confirms a *fresh*
/// purchase, then navigates to the success screen. There is deliberately no
/// manual "I've paid" button: users used to tap it before finishing the order,
/// which produced false "payment not confirmed" errors.
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
  bool _isActivating = false;
  String? _errorMessage;
  WebViewController? _webViewController;
  String? _checkoutUrl;
  Timer? _pollTimer;
  int _pollAttempts = 0;

  /// The Freemius checkout is a heavy Angular+Stripe page — several seconds
  /// even on good wifi, far longer on mobile data. Until it paints, the WebView
  /// is plain white, which users read as a crash ("شاشة بيضاء"). We cover it
  /// with a branded loader until the page finishes.
  bool _isPageLoading = true;
  int _loadProgress = 0;

  /// Shows a "slow connection, still loading" reassurance if the checkout page
  /// takes unusually long, so a slow network never looks like a dead screen.
  Timer? _slowLoadTimer;
  bool _isSlowLoad = false;
  static const _slowLoadAfter = Duration(seconds: 8);

  /// Hard cap on the post-load paint probe — reveal the WebView after this even
  /// if the probe never sees text, so the loader can't become a dead end.
  static const _paintProbeCap = Duration(seconds: 6);

  /// Body-text length that means the checkout actually painted. The live
  /// Freemius form measures ~500 chars once rendered and ~0 while blank
  /// (verified against the production checkout URL), so 100 separates them
  /// cleanly without being brittle.
  static const _paintedTextThreshold = 100;

  /// Payment id already present in `freemius_purchases/{userId}` when this
  /// screen opened. Anything different that appears later is the purchase from
  /// *this* checkout — see [isNewFreemiusPurchase].
  String? _baselinePaymentId;
  bool _softNoticeShown = false;

  /// Poll cadence and the point at which we show a soft "still processing"
  /// notice. We never hard-fail: the webhook is the source of truth and may
  /// land late, so we keep polling for as long as the screen stays open.
  static const _pollInterval = Duration(seconds: 3);
  static const _softNoticeAfterAttempts = 40; // ~2 minutes

  /// Resolved once per checkout from the admin `payment_test_mode` flag:
  /// sandbox when test mode is on, live (production) otherwise.
  late final FreemiusConfig _freemiusConfig =
      ref.read(systemSettingsProvider).value?.paymentTestMode == true
          ? freemiusSandboxConfig
          : freemiusProductionConfig;

  @override
  void initState() {
    super.initState();
    _generateCheckoutUrl();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _slowLoadTimer?.cancel();
    super.dispose();
  }

  // ── Generate checkout URL ─────────────────────────────────────────────

  Future<void> _generateCheckoutUrl() async {
    try {
      final service = FreemiusCheckoutService(
        config: _freemiusConfig,
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

      if (result.success &&
          result.checkoutUrl != null &&
          result.checkoutUrl!.trim().isNotEmpty) {
        setState(() {
          _checkoutUrl = result.checkoutUrl;
          _isLoadingUrl = false;
        });
        _initWebView(result.checkoutUrl!);
        _startAutoDetect();
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
    _startSlowLoadWatch();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // The checkout renders on white; matching it avoids a dark flash on the
      // way in for dark-mode users.
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isPageLoading = true;
                _loadProgress = 0;
              });
              _startSlowLoadWatch();
            }
          },
          onProgress: (progress) {
            if (mounted) setState(() => _loadProgress = progress);
          },
          onPageFinished: (_) => _revealWhenPainted(),
          onWebResourceError: (error) {
            debugPrint('Freemius WebView error: ${error.description}');
            // Surface main-frame failures as an error state instead of a blank
            // WebView. Clearing _checkoutUrl flips _buildBody to the error view.
            if ((error.isForMainFrame ?? false) && mounted) {
              _slowLoadTimer?.cancel();
              setState(() {
                _isPageLoading = false;
                _checkoutUrl = null;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  /// Holds the loader until the checkout has actually painted text.
  ///
  /// `onPageFinished` fires on the browser load event, but Freemius renders its
  /// form with Angular *after* that — lifting the loader there would expose the
  /// very white screen we're covering. So we poll for real body text before
  /// revealing. Always resolves: after [_paintProbeCap] we reveal regardless,
  /// so a probe failure can never strand the user on the loader.
  Future<void> _revealWhenPainted() async {
    final controller = _webViewController;
    final deadline = DateTime.now().add(_paintProbeCap);

    while (mounted && DateTime.now().isBefore(deadline)) {
      try {
        final raw = await controller?.runJavaScriptReturningResult(
          'document.body ? document.body.innerText.trim().length : 0',
        );
        if (parseJsNumberResult(raw) > _paintedTextThreshold) break;
      } catch (_) {
        break; // JS unavailable — don't hold the user hostage to the probe.
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    _slowLoadTimer?.cancel();
    if (mounted) {
      setState(() {
        _isPageLoading = false;
        _isSlowLoad = false;
      });
    }
  }

  /// After [_slowLoadAfter] with no `onPageFinished`, upgrade the loader copy
  /// to explain the wait rather than leaving the user guessing.
  void _startSlowLoadWatch() {
    _slowLoadTimer?.cancel();
    _isSlowLoad = false;
    _slowLoadTimer = Timer(_slowLoadAfter, () {
      if (mounted && _isPageLoading) setState(() => _isSlowLoad = true);
    });
  }

  // ── Automatic payment detection ───────────────────────────────────────

  /// Records the payment id already on file (if any), then polls until a
  /// *new* purchase from this checkout appears. No manual confirmation button:
  /// the webhook is the source of truth, so we just wait for it.
  Future<void> _startAutoDetect() async {
    if (_pollTimer != null) return;

    final service = FreemiusCheckoutService(config: _freemiusConfig);
    final userId = ref.read(authProvider).user?.uid;
    if (userId == null) {
      _showError('المستخدم غير مسجل الدخول');
      return;
    }

    // Baseline: a purchase doc may already exist from an earlier payment.
    // Capture its id so we only react to a genuinely new one.
    try {
      final existing = await service.waitForPurchase(userId: userId);
      _baselinePaymentId = existing?.paymentId;
    } catch (_) {
      _baselinePaymentId = null;
    }

    _pollAttempts = 0;
    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      _pollAttempts++;
      try {
        final purchase = await service.waitForPurchase(userId: userId);
        if (!mounted) return;

        if (isNewFreemiusPurchase(_baselinePaymentId, purchase)) {
          timer.cancel();
          _pollTimer = null;
          await _activateSubscription(purchase);
          return;
        }
      } catch (_) {}

      // Soft, one-time reassurance after a couple of minutes — never a
      // blocking error, since the payment may still be settling.
      if (_pollAttempts == _softNoticeAfterAttempts &&
          !_softNoticeShown &&
          mounted) {
        _softNoticeShown = true;
        _showInfo('ما زلنا ننتظر تأكيد الدفع. يمكنك إبقاء الشاشة مفتوحة، '
            'أو إغلاقها والتحقق من حالة اشتراكك لاحقاً.');
      }
    });
  }

  Future<void> _activateSubscription(dynamic purchase) async {
    if (mounted) setState(() => _isActivating = true);
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
      if (mounted) setState(() => _isActivating = false);
      _showError('تم تأكيد الدفع ولكن فشل تفعيل الاشتراك: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 6),
      ),
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

    // With adjustResize the keyboard already halves the available height. Give
    // that space back to the card form instead of the status/cancel bar, which
    // is useless while the user is mid-field.
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      children: [
        // Sandbox banner — only shown when admin payment_test_mode is on, so
        // no one mistakes a test checkout for a real charge.
        if (_freemiusConfig.isSandbox)
          Container(
            width: double.infinity,
            color: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: const Text(
              'وضع الاختبار — لن يتم سحب أي مبلغ حقيقي',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

        // WebView — kept in the tree while loading so it can paint underneath
        // the loader, which is removed the moment the page is ready.
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: buildPaymentWebView(_webViewController!)),
              if (_isPageLoading)
                Positioned.fill(child: _buildCheckoutLoader(isDark)),
            ],
          ),
        ),

        // Bottom actions — hidden while typing so the card form keeps the room.
        if (!keyboardOpen)
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
              // Passive status — payment is detected automatically once the
              // order is completed above. No manual "I've paid" button.
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _isActivating
                            ? 'جاري تفعيل طلبك...'
                            : 'أكمل الدفع بالأعلى — سيتم تأكيد طلبك تلقائياً',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SanadButton(
                text: 'إلغاء',
                onPressed: _isActivating ? null : _cancelCheckout,
                variant: SanadButtonVariant.ghost,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Covers the WebView until the checkout page paints. Without this the user
  /// stares at a blank white WebView for several seconds and assumes the app
  /// broke — the exact complaint that surfaced on the first live payment.
  Widget _buildCheckoutLoader(bool isDark) {
    final surface = isDark ? AppColors.backgroundDark : Colors.white;

    return Container(
      color: surface,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.lock_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'جاري فتح صفحة الدفع الآمنة',
            textAlign: TextAlign.center,
            style: AppTypography.headingSmall.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isSlowLoad
                ? 'الاتصال بطيء قليلاً — لا تغلق الشاشة، ما زلنا نحمّل صفحة الدفع.'
                : 'قد تستغرق بضع ثوانٍ حسب سرعة الإنترنت. من فضلك انتظر.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          // Real progress from the WebView, so the bar reflects actual work
          // rather than a decorative animation.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _loadProgress > 0 ? _loadProgress / 100 : null,
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
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
