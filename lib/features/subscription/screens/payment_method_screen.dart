import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../models/subscription_product.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  final SubscriptionProduct product;

  const PaymentMethodScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  String _selectedMethod = 'card';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.paymentMethod),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Summary Card
              _OrderSummaryCard(product: widget.product, isDark: isDark, s: s),
              const SizedBox(height: 24),

              // Payment method selection title
              Row(
                children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 20,
                    color: isDark ? Colors.white : AppColors.textLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.choosePaymentMethod,
                    style: AppTypography.headingSmall.copyWith(
                      color: isDark ? Colors.white : AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Credit/Debit Card (2Checkout)
              _PaymentMethodCard(
                title: s.creditCard,
                subtitle: 'Visa, Mastercard, Amex',
                brandColor: const Color(0xFF1A1F71),
                gradientColors: [const Color(0xFF1A1F71), const Color(0xFF2B3990)],
                iconWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CardBrandIcon(color: const Color(0xFF1A1F71)),
                    const SizedBox(width: 4),
                    _CardBrandIcon(color: const Color(0xFFEB001B)),
                    const SizedBox(width: 4),
                    _CardBrandIcon(color: const Color(0xFF006FCF)),
                  ],
                ),
                selected: _selectedMethod == 'card',
                onTap: () => setState(() => _selectedMethod = 'card'),
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // PayPal
              _PaymentMethodCard(
                title: 'PayPal',
                subtitle: s.paypalSecure,
                brandColor: const Color(0xFF003087),
                gradientColors: [const Color(0xFF003087), const Color(0xFF009CDE)],
                iconWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003087),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Pay',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                selected: _selectedMethod == 'paypal',
                onTap: () => setState(() => _selectedMethod = 'paypal'),
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Bank Transfer
              _PaymentMethodCard(
                title: s.bankTransfer,
                subtitle: s.manualVerification,
                brandColor: AppColors.success,
                gradientColors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
                iconWidget: Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.success,
                  size: 24,
                ),
                selected: _selectedMethod == 'bank',
                onTap: () => setState(() => _selectedMethod = 'bank'),
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Security Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark.withValues(alpha: 0.5)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.paymentSecure,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.textDark : AppColors.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedMethod == 'bank'
                                ? s.verificationPending
                                : s.autoRenewalStatement,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Continue button
              SanadButton(
                text: '${s.next} - \$${widget.product.price.toStringAsFixed(2)}',
                isFullWidth: true,
                size: SanadButtonSize.large,
                onPressed: () => _handlePaymentMethodSelection(context),
              ),
              const SizedBox(height: 12),

              // Cancel button
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
      ),
    );
  }

  void _handlePaymentMethodSelection(BuildContext context) {
    switch (_selectedMethod) {
      case 'card':
        context.push('/card-payment', extra: widget.product);
        break;
      case 'paypal':
        context.push('/paypal-payment', extra: widget.product);
        break;
      case 'bank':
        context.push('/bank-transfer', extra: widget.product);
        break;
    }
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: AppTypography.headingSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      product.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.total,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '\$${product.price.toStringAsFixed(2)}/${s.month}',
                style: AppTypography.headingMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color brandColor;
  final List<Color> gradientColors;
  final Widget iconWidget;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.brandColor,
    required this.gradientColors,
    required this.iconWidget,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? brandColor : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Brand icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected
                    ? brandColor.withValues(alpha: 0.1)
                    : (isDark ? AppColors.backgroundDark : AppColors.softBlue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: 16),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? brandColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? brandColor : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBrandIcon extends StatelessWidget {
  final Color color;

  const _CardBrandIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
