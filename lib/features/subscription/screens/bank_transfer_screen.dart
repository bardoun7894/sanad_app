import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/subscription_product.dart';
import '../providers/subscription_provider.dart';

class BankTransferScreen extends ConsumerStatefulWidget {
  final SubscriptionProduct product;

  const BankTransferScreen({super.key, required this.product});

  @override
  ConsumerState<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends ConsumerState<BankTransferScreen> {
  bool _copied = false;
  late final String _referenceCode;

  @override
  void initState() {
    super.initState();
    // Generate a unique reference code: REF-<short-uid>-<yyyymmdd>-<millis-suffix>
    final uid = ref.read(authProvider).user?.uid ?? 'USR';
    final shortUid = uid.length > 6 ? uid.substring(0, 6).toUpperCase() : uid.toUpperCase();
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final suffix = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    _referenceCode = 'REF-$shortUid-$datePart-$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.bankTransfer),
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
              // Product summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.softBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
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
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.product.id == 'chat_monthly'
                                ? s.chatSubscriptionDesc
                                : (widget.product.id == 'call_hourly'
                                      ? s.therapyCallDesc
                                      : widget.product.description),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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
              ),
              const SizedBox(height: 32),

              // Instructions
              Text(
                s.bankTransferInstructions,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
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
                  s.bankTransferInfo,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Bank details
              Text(
                s.bankDetails,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // TODO: Replace these with your real bank account details
              // Bank name
              _BankDetailItem(
                label: s.bankName,
                value: s.bankAccountName,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Account number
              _BankDetailItem(
                label: s.accountNumber,
                value: s.bankAccountNumber,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Account holder
              _BankDetailItem(
                label: s.accountHolder,
                value: s.bankAccountHolder,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // SWIFT code
              _BankDetailItem(
                label: s.swiftCode,
                value: s.bankSwiftCode,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // IBAN
              _BankDetailItem(
                label: s.iban,
                value: s.bankIban,
                isDark: isDark,
              ),
              const SizedBox(height: 28),

              // Reference code (unique per payment)
              Text(
                s.referenceCode,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.referenceCode,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _referenceCode,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: _referenceCode),
                        );
                        setState(() => _copied = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() => _copied = false);
                          }
                        });
                      },
                      child: Icon(
                        _copied ? Icons.check : Icons.copy_outlined,
                        color: _copied ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.bankTransferWarning,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Next button
              SanadButton(
                text: s.paymentSent,
                isFullWidth: true,
                onPressed: () => _handleBankTransfer(context, s),
              ),
              const SizedBox(height: 12),

              // WhatsApp Notification Button
              SanadButton(
                text: s.notifyWhatsApp,
                variant: SanadButtonVariant.outline,
                isFullWidth: true,
                onPressed: _launchWhatsApp,
                // backgroundColor: const Color(0xFF25D366), // WhatsApp Green - SanadButton might not support this override easily without checking source
                // For now, stick to outline variant which is safe.
              ),
              const SizedBox(height: 12),

              // Cancel button
              SanadButton(
                text: s.cancel,
                variant: SanadButtonVariant.outline,
                isFullWidth: true,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final s = ref.read(stringsProvider);

    // Get localized product name
    String productName = widget.product.title;
    if (widget.product.id == 'chat_monthly') {
      productName = s.chatSubscription;
    } else if (widget.product.id == 'call_hourly') {
      productName = s.therapyCall;
    }

    final amount = '\$${widget.product.price.toStringAsFixed(2)}';
    final refCode = _referenceCode;

    final message = s.bankTransferMessage
        .replaceFirst('\$productName', productName)
        .replaceFirst('\$amount', amount)
        .replaceFirst('\$refCode', refCode);

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

  void _handleBankTransfer(BuildContext context, dynamic s) async {
    try {
      final paymentId = await ref
          .read(subscriptionProvider.notifier)
          .subscribeWithBankTransfer(widget.product);

      if (!context.mounted) return;
      context.push('/receipt-upload', extra: paymentId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }
}

class _BankDetailItem extends ConsumerWidget {
  final String label;
  final String value;
  final bool isDark;

  const _BankDetailItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.softBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ref.read(stringsProvider).copiedToClipboard,
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Icon(
                  Icons.copy_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
