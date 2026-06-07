// ignore_for_file: unused_import, unused_field
import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../routes/app_routes.dart';
import '../../subscription/models/payment_route_args.dart';
import '../../subscription/models/subscription_product.dart';
import '../../subscription/services/freemius_checkout_service.dart';
import '../../therapists/services/booking_service.dart';

/// Screen for completing payment after booking a session.
/// Shows booking summary, countdown timer, and payment options.
class BookingPaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;
  final String currency;
  final String therapistName;
  final DateTime paymentDeadline;

  const BookingPaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.therapistName,
    required this.paymentDeadline,
  });

  @override
  ConsumerState<BookingPaymentScreen> createState() =>
      _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends ConsumerState<BookingPaymentScreen> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  // Apple Pay / Google Pay hidden for now — re-enable by restoring the
  // commented wallet option in build() and switching the default back to:
  //   late String _selectedMethod = _isIOS ? 'apple_pay' : 'google_pay';
  final bool _isIOS = defaultTargetPlatform == TargetPlatform.iOS;
  String _selectedMethod = 'paypal';

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final remaining = widget.paymentDeadline.difference(DateTime.now());
    if (remaining.isNegative) {
      _countdownTimer?.cancel();
      // Booking expired
      if (mounted) {
        setState(() => _remaining = Duration.zero);
        _handleExpired();
      }
    } else {
      if (mounted) setState(() => _remaining = remaining);
    }
  }

  void _handleExpired() async {
    final bookingService = ref.read(bookingServiceProvider);
    await bookingService.cancelBooking(widget.bookingId, 'payment_timeout');
    if (mounted) {
      final s = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.bookingExpired)),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == 'bank_transfer') {
      // WhatsApp-first: the user requests transfer details immediately. The
      // admin replies with the bank account and later marks the booking paid
      // via BookingService.markBankTransferPaid. No unlock gate on the request.
      await _launchWhatsApp();
      return;
    }

    // Synthesize a SubscriptionProduct that carries the booking's amount /
    // currency / label into the existing gateway screens. The screens branch
    // on `bookingId` and call `confirmBookingPayment` on success, so this
    // product is never persisted as a subscription.
    final product = SubscriptionProduct(
      id: 'booking_${widget.bookingId}',
      title: widget.therapistName,
      description: widget.therapistName,
      price: widget.amount,
      currencyCode: widget.currency,
      billingPeriod: 'one_time',
      billingPeriodDays: 0,
    );
    final args = PaymentRouteArgs(
      product: product,
      bookingId: widget.bookingId,
    );

    final route = switch (_selectedMethod) {
      // 'apple_pay' => AppRoutes.applePayPayment,
      // 'google_pay' => AppRoutes.googlePayPayment,
      'paypal' => AppRoutes.paypalPayment,
      'freemius' => AppRoutes.freemiusPayment,
      _ => null,
    };
    if (route == null) return;

    context.push(route, extra: args);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.completePayment,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Countdown timer
            _buildCountdownCard(isDark, s),
            const SizedBox(height: 24),

            // Booking summary
            _buildSummaryCard(isDark, s),
            const SizedBox(height: 24),

            // Payment methods
            Text(
              s.selectPaymentMethod,
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Apple Pay / Google Pay — hidden for now (uncomment to restore).
            /*
            _buildPaymentOption(
              _isIOS ? 'apple_pay' : 'google_pay',
              _isIOS ? 'Apple Pay' : s.googlePay,
              Icons.payment_rounded,
              isDark,
            ),
            */
            // Visa/Mastercard via Freemius — only shown when
            // `bookingPriceTiers` is populated in freemiusProductionConfig.
            // Without tiers there's no Freemius plan to map the booking's
            // variable amount to, so the option is hidden to avoid errors.
            if (freemiusBookingPlanConfigured(freemiusProductionConfig)) ...[
              const SizedBox(height: 12),
              _buildPaymentOption(
                'freemius',
                'Visa / Mastercard',
                Icons.credit_card_rounded,
                isDark,
              ),
            ],
            const SizedBox(height: 12),
            _buildPaymentOption(
              'paypal',
              'PayPal',
              Icons.account_balance_wallet_rounded,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'bank_transfer',
              s.bankTransferWhatsApp,
              Icons.account_balance_rounded,
              isDark,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SanadButton(
            text: '${s.payNow} - ${widget.amount} ${widget.currency}',
            isFullWidth: true,
            onPressed: _remaining.inSeconds > 0 ? _processPayment : null,
            size: SanadButtonSize.large,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownCard(bool isDark, dynamic s) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);
    final isUrgent = _remaining.inHours < 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: isUrgent ? AppColors.error : AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.paymentDeadline,
                  style: AppTypography.labelMedium.copyWith(
                    color: isUrgent ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: AppTypography.headingMedium.copyWith(
                    color: isUrgent ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, dynamic s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.bookingSummary,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(
            Icons.person_outline_rounded,
            s.therapist,
            widget.therapistName,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildRow(
            Icons.attach_money_rounded,
            s.price,
            '${widget.amount} ${widget.currency}',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    String id,
    String label,
    IconData icon,
    bool isDark, {
    bool isLocked = false,
  }) {
    final isSelected = !isLocked && _selectedMethod == id;

    return Opacity(
      opacity: isLocked ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: isLocked ? null : () => setState(() => _selectedMethod = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.08))
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : (isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isLocked)
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                )
              else if (isSelected)
                Icon(Icons.check_circle, color: AppColors.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final s = ref.read(stringsProvider);
    final amount = '${widget.amount} ${widget.currency}';
    final message = s.bankTransferMessage
        .replaceFirst('\$productName', widget.therapistName)
        .replaceFirst('\$amount', amount)
        .replaceFirst('\$refCode', widget.bookingId);

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
