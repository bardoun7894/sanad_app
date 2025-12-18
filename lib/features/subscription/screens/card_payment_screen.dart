import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../models/subscription_product.dart';
import '../providers/subscription_provider.dart';

class CardPaymentScreen extends ConsumerStatefulWidget {
  final SubscriptionProduct product;

  const CardPaymentScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends ConsumerState<CardPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _acceptTerms = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.creditCard),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product summary
                _buildProductSummary(isDark),
                const SizedBox(height: 32),

                // Cardholder name
                Text(
                  s.cardholderName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                    hint: s.enterFullName,
                    isDark: isDark,
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return s.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Card number
                Text(
                  s.cardNumber,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: _buildInputDecoration(
                    hint: s.enterCardNumber,
                    isDark: isDark,
                    prefixIcon: Icons.credit_card_outlined,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return s.fieldRequired;
                    }
                    if (value!.replaceAll(' ', '').length != 16) {
                      return s.invalidCardNumber;
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Format with spaces every 4 digits
                    final clean = value.replaceAll(' ', '');
                    if (clean.length <= 16) {
                      _cardNumberController.value = TextEditingValue(
                        text: _formatCardNumber(clean),
                        selection: TextSelection.fromPosition(
                          TextPosition(offset: _formatCardNumber(clean).length),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Expiry and CVV row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.expiryDate,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _expiryController,
                            decoration: _buildInputDecoration(
                              hint: 'MM/YY',
                              isDark: isDark,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return s.fieldRequired;
                              }
                              if (!value!.contains('/')) {
                                return 'Invalid format';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.length == 2 &&
                                  !value.contains('/')) {
                                _expiryController.value = TextEditingValue(
                                  text: '${value.substring(0, 2)}/',
                                  selection: TextSelection.fromPosition(
                                    TextPosition(offset: 3),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.cvv,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _cvvController,
                            decoration: _buildInputDecoration(
                              hint: 'XXX',
                              isDark: isDark,
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return s.fieldRequired;
                              }
                              if (value!.length != 3) {
                                return 'Invalid CVV';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Terms checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() => _acceptTerms = value ?? false);
                      },
                      activeColor: AppColors.primary,
                    ),
                    Expanded(
                      child: Text(
                        s.billingStatement,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pay button
                SanadButton(
                  text: '${s.payNow} \$${widget.product.price.toStringAsFixed(2)}',
                  isFullWidth: true,
                  isLoading: subscriptionState.isProcessingPurchase,
                  onPressed: _acceptTerms && !subscriptionState.isProcessingPurchase
                      ? _handlePayment
                      : null,
                ),
                const SizedBox(height: 12),

                // Cancel button
                SanadButton(
                  text: s.cancel,
                  variant: SanadButtonVariant.outline,
                  isFullWidth: true,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 16),

                // Security note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark.withValues(alpha: 0.5)
                        : AppColors.softBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.paymentSecure,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.softBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            '\$${widget.product.price.toStringAsFixed(2)}',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required bool isDark,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }

  String _formatCardNumber(String value) {
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  void _handlePayment() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await ref.read(subscriptionProvider.notifier)
            .subscribeWithCard(widget.product);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.watch(stringsProvider).processingPayment),
              backgroundColor: AppColors.success,
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.pushReplacement('/payment-success');
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
