import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../../core/l10n/language_provider.dart';
import '../../therapists/services/booking_service.dart';
import '../../therapists/providers/therapist_provider.dart';

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
  bool _isProcessing = false;
  bool _paymentComplete = false;
  String _selectedMethod = 'google_pay';

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
    setState(() => _isProcessing = true);

    try {
      final bookingService = ref.read(bookingServiceProvider);

      // Simulate payment processing
      // In production, integrate with PaymentGatewayService
      final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';

      // Confirm the booking payment
      await bookingService.confirmBookingPayment(
        widget.bookingId,
        paymentId,
      );

      if (mounted) {
        setState(() {
          _paymentComplete = true;
          _isProcessing = false;
        });

        // Navigate back after showing success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ref.read(bookingsTabTriggerProvider.notifier).state = 1;
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.errorOccurred}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    if (_paymentComplete) {
      return _buildSuccessView(isDark, s);
    }

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

            _buildPaymentOption(
              'google_pay',
              s.googlePay,
              Icons.payment_rounded,
              isDark,
            ),
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
              s.bankTransfer,
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
            text: _isProcessing
                ? s.loading
                : '${s.payNow} - ${widget.amount} ${widget.currency}',
            isFullWidth: true,
            onPressed:
                (_remaining.inSeconds > 0 && !_isProcessing)
                    ? _processPayment
                    : null,
            isLoading: _isProcessing,
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
    bool isDark,
  ) {
    final isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
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
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(bool isDark, dynamic s) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                s.paymentSuccessful,
                style: AppTypography.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.bookingConfirmed,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
