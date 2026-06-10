// ignore_for_file: unused_import, unused_element, unused_field
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/providers/system_settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../../routes/app_routes.dart';
import '../models/subscription_product.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  final SubscriptionProduct product;

  const PaymentMethodScreen({super.key, required this.product});

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen>
    with TickerProviderStateMixin {
  // Apple Pay / Google Pay hidden for now — re-enable by restoring the
  // commented wallet block below and switching the default back to:
  //   late String _selectedMethod = _isIOS ? 'apple_pay' : 'google_pay';
  final bool _isIOS = defaultTargetPlatform == TargetPlatform.iOS;
  String _selectedMethod = 'paypal';

  late final AnimationController _staggeredController;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _staggeredController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final items = 7;
    _fadeAnimations = List.generate(items, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggeredController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _slideAnimations = List.generate(items, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggeredController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _staggeredController.forward();
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Admin can hide PayPal from the dashboard (payment_paypal_enabled).
    final paypalEnabled =
        ref.watch(systemSettingsProvider).value?.paypalEnabled ?? true;
    // Admin can show/hide the native wallet (Google Pay / Apple Pay) from the
    // dashboard (payment_google_pay_enabled). Defaults to hidden.
    final googlePayEnabled =
        ref.watch(systemSettingsProvider).value?.googlePayEnabled ?? false;
    // If PayPal got hidden while it was the selected method, move the
    // selection to the card option so "Continue" can't route to a hidden screen.
    if (!paypalEnabled && _selectedMethod == 'paypal') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedMethod = 'freemius');
      });
    }
    // Same guard for the wallet tile — if it's disabled while selected, fall
    // back to the card option.
    if (!googlePayEnabled &&
        (_selectedMethod == 'google_pay' || _selectedMethod == 'apple_pay')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedMethod = 'freemius');
      });
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.paymentMethod),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeTransition(
                opacity: _fadeAnimations[0],
                child: SlideTransition(
                  position: _slideAnimations[0],
                  child: _OrderSummaryCard(
                    product: widget.product,
                    isDark: isDark,
                    s: s,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              FadeTransition(
                opacity: _fadeAnimations[1],
                child: SlideTransition(
                  position: _slideAnimations[1],
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.payments_outlined,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        s.choosePaymentMethod,
                        style: AppTypography.headingSmall.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Apple Pay / Google Pay (native wallet) — shown only when the
              // admin enables it from the dashboard (payment_google_pay_enabled).
              if (googlePayEnabled) ...[
                FadeTransition(
                  opacity: _fadeAnimations[2],
                  child: SlideTransition(
                    position: _slideAnimations[2],
                    child: _isIOS
                        ? _PaymentMethodCard(
                            title: 'Apple Pay',
                            subtitle: s.securePayment,
                            brandColor: Colors.black,
                            iconWidget: _ApplePayIcon(),
                            selected: _selectedMethod == 'apple_pay',
                            onTap: () =>
                                setState(() => _selectedMethod = 'apple_pay'),
                            isDark: isDark,
                            index: 0,
                          )
                        : _PaymentMethodCard(
                            title: 'Google Pay',
                            subtitle: s.securePayment,
                            brandColor: Colors.black,
                            iconWidget: _GooglePayIcon(),
                            selected: _selectedMethod == 'google_pay',
                            onTap: () =>
                                setState(() => _selectedMethod = 'google_pay'),
                            isDark: isDark,
                            index: 0,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Visa / Mastercard (Freemius hosted checkout)
              FadeTransition(
                opacity: _fadeAnimations[3],
                child: SlideTransition(
                  position: _slideAnimations[3],
                  child: _PaymentMethodCard(
                    title: 'بطاقة فيزا / ماستر',
                    subtitle: s.securePayment,
                    brandColor: const Color(0xFF1A1F71),
                    iconWidget: const Icon(
                      Icons.credit_card_rounded,
                      color: Color(0xFF1A1F71),
                      size: 26,
                    ),
                    selected: _selectedMethod == 'freemius',
                    onTap: () => setState(() => _selectedMethod = 'freemius'),
                    isDark: isDark,
                    index: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // PayPal — hidden when the admin disables it from the dashboard.
              if (paypalEnabled) ...[
                FadeTransition(
                  opacity: _fadeAnimations[4],
                  child: SlideTransition(
                    position: _slideAnimations[4],
                    child: _PaymentMethodCard(
                      title: 'PayPal',
                      subtitle: s.securePayment,
                      brandColor: const Color(0xFF003087),
                      iconWidget: _PayPalIcon(),
                      selected: _selectedMethod == 'paypal',
                      onTap: () => setState(() => _selectedMethod = 'paypal'),
                      isDark: isDark,
                      index: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              FadeTransition(
                opacity: _fadeAnimations[5],
                child: SlideTransition(
                  position: _slideAnimations[5],
                  child: _PaymentMethodCard(
                    title: s.bankTransferWhatsApp,
                    subtitle: s.payHere,
                    brandColor: const Color(0xFF25D366),
                    iconWidget: const Icon(
                      Icons.account_balance_rounded,
                      color: Color(0xFF25D366),
                      size: 26,
                    ),
                    selected: _selectedMethod == 'bank_transfer',
                    onTap: () =>
                        setState(() => _selectedMethod = 'bank_transfer'),
                    isDark: isDark,
                    index: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FadeTransition(
                opacity: _fadeAnimations[6],
                child: SlideTransition(
                  position: _slideAnimations[6],
                  child: _SecurityBadge(
                    isDark: isDark,
                    s: s,
                    isBankSelected: false,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SanadButton(
                text: '${s.pay} - \$${widget.product.price.toStringAsFixed(2)}',
                isFullWidth: true,
                size: SanadButtonSize.large,
                backgroundColor: widget.product.id.contains('premium')
                    ? const Color(0xFFD4AF37) // Gold for Premium
                    : null, // Default primary
                textColor: widget.product.id.contains('premium')
                    ? Colors.white
                    : null,
                onPressed: () => _handlePaymentMethodSelection(context),
              ),
              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    s.cancel,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
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

  void _handlePaymentMethodSelection(BuildContext context) {
    if (_selectedMethod == 'apple_pay') {
      context.push(AppRoutes.applePayPayment, extra: widget.product);
    } else if (_selectedMethod == 'google_pay') {
      context.push(AppRoutes.googlePayPayment, extra: widget.product);
    } else if (_selectedMethod == 'paypal') {
      context.push(AppRoutes.paypalPayment, extra: widget.product);
    } else if (_selectedMethod == 'freemius') {
      context.push(AppRoutes.freemiusPayment, extra: widget.product);
    } else if (_selectedMethod == 'bank_transfer') {
      _launchWhatsApp();
    }
  }

  Future<void> _launchWhatsApp() async {
    final s = ref.read(stringsProvider);

    String productName = widget.product.title;
    if (widget.product.id == 'chat_monthly') {
      productName = s.chatSubscription;
    } else if (widget.product.id == 'call_hourly') {
      productName = s.therapyCall;
    }

    final amount = '\$${widget.product.price.toStringAsFixed(2)}';
    final message = s.bankTransferMessage
        .replaceFirst('\$productName', productName)
        .replaceFirst('\$amount', amount)
        .replaceFirst('\$refCode', '');

    final phone = s.supportWhatsAppNumber;
    final url = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.whatsappLaunchError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// Apple Pay / Google Pay icon widgets — used by the native wallet tile, which
// the admin shows/hides via payment_google_pay_enabled.
class _GooglePayIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SvgPicture.asset(
        'assets/icons/google_pay.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ApplePayIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SvgPicture.asset(
        'assets/icons/apple_pay.svg',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _PayPalIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'Pay\nPal',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF003087),
          fontWeight: FontWeight.w800,
          fontSize: 13,
          height: 1.1,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final SubscriptionProduct product;
  final bool isDark;
  final dynamic s;

  const _OrderSummaryCard({
    required this.product,
    required this.isDark,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = product.id.contains('premium');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPremium
                ? [
                    const Color(0xFFD4AF37), // Gold
                    const Color(0xFFFFD700), // Yellow Gold
                  ]
                : [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.85),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isPremium
                  ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isPremium
                          ? Icons.star_rounded
                          : Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.id == 'chat_monthly'
                              ? s.chatSubscription
                              : (product.id == 'call_hourly'
                                    ? s.therapyCall
                                    : product.title),
                          style: AppTypography.headingMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.id == 'premium_vip'
                                  ? s.bestValue
                                  : s.popular,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 4),
                          Text(
                            product.id == 'chat_monthly'
                                ? s.chatSubscriptionDesc
                                : (product.id == 'call_hourly'
                                      ? s.therapyCallDesc
                                      : product.description),
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.total,
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.billingPeriod == 'monthly'
                            ? '/${s.month}'
                            : '/${s.hour}',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color brandColor;
  final Widget iconWidget;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final int index;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.brandColor,
    required this.iconWidget,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.index,
  });

  @override
  State<_PaymentMethodCard> createState() => _PaymentMethodCardState();
}

class _PaymentMethodCardState extends State<_PaymentMethodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Material(
        color: widget.isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: widget.selected ? 2 : 0,
        shadowColor: widget.brandColor.withValues(alpha: 0.15),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(16),
          splashColor: widget.brandColor.withValues(alpha: 0.1),
          highlightColor: widget.brandColor.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.selected
                    ? widget.brandColor
                    : (widget.isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                width: widget.selected ? 2.5 : 1,
              ),
            ),
            child: Row(
              children: [
                widget.iconWidget,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AnimatedSelectionIndicator(
                  selected: widget.selected,
                  brandColor: widget.brandColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSelectionIndicator extends StatelessWidget {
  final bool selected;
  final Color brandColor;

  const _AnimatedSelectionIndicator({
    required this.selected,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? brandColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? brandColor
              : AppColors.textMuted.withValues(alpha: 0.5),
          width: selected ? 2.5 : 2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: selected
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
                key: ValueKey('check'),
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  final bool isDark;
  final dynamic s;
  final bool isBankSelected;

  const _SecurityBadge({
    required this.isDark,
    required this.s,
    required this.isBankSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.5)
              : AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: AppColors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.paymentSecure,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBankSelected
                        ? s.verificationPending
                        : s.autoRenewalStatement,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
