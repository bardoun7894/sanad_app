import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../models/subscription_product.dart';
import '../providers/subscription_provider.dart';
import '../../../core/widgets/whatsapp_support_button.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.subscription),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status badge
              if (subscriptionState.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.subscriptionActive,
                              style: AppTypography.buttonSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (subscriptionState.status.expiryDate != null)
                              Text(
                                '${s.renewalDate}: ${_formatDate(subscriptionState.status.expiryDate!)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (subscriptionState.status.state.name == 'pending')
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hourglass_empty_outlined,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.verificationPending,
                              style: AppTypography.buttonSmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              s.paymentHelp,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (subscriptionState.isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.subscriptionExpired,
                          style: AppTypography.buttonSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Header
              Text(
                s.upgradeToPremium,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                s.unlimitedChat,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textMuted
                      : AppColors.textMutedLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Products list
              if (subscriptionState.isLoading)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(s.processingPayment),
                    ],
                  ),
                )
              else
                ...subscriptionState.products.map((product) {
                  final isSelected = false; // Could track selected product
                  return _ProductCard(
                    product: product,
                    isSelected: isSelected,
                    onTap: () => _showPaymentOptions(context, product, s),
                  );
                }).toList(),

              const SizedBox(height: 24),

              // Legal disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark.withValues(alpha: 0.5)
                      : AppColors.softBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.billingStatement,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark.withValues(alpha: 0.5)
                      : AppColors.softBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s.therapistDisclaimer,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Cancel subscription button (if subscribed)
              if (subscriptionState.isPremium) ...[
                const SizedBox(height: 24),
                SanadButton(
                  text: s.cancelSubscription,
                  variant: SanadButtonVariant.outline,
                  isFullWidth: true,
                  onPressed: () => _showCancelDialog(context, s),
                ),
              ],
              const SizedBox(height: 32),
              const WhatsAppSupportButton(),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentOptions(
    BuildContext context,
    SubscriptionProduct product,
    dynamic s,
  ) {
    context.push('/payment-method', extra: product);
  }

  void _showCancelDialog(BuildContext context, dynamic s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.cancelSubscription),
        content: Text(s.cancellationStatement),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(s.contactSupport),
          ),
          TextButton(
            onPressed: () {
              ref.read(subscriptionProvider.notifier).cancelSubscription();
              context.pop();
            },
            child: Text(
              s.cancelSubscription,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ProductCard extends ConsumerWidget {
  final SubscriptionProduct product;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product name and badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (product.id == 'chat_monthly')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'POPULAR',
                      style: AppTypography.buttonSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Price
            Text(
              '\$${product.price.toStringAsFixed(2)}/month',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Features
            ...product.features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(feature, style: AppTypography.bodySmall),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),

            // Subscribe button
            SanadButton(
              text: s.upgradeToPremium,
              isFullWidth: true,
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
