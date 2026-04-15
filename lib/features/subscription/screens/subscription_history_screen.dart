import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

class SubscriptionHistoryScreen extends ConsumerWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentHistoryAsync = ref.watch(paymentHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = ref.watch(languageProvider).language == AppLanguage.arabic;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          isArabic ? 'سجل الاشتراكات' : 'Subscription History',
          style: AppTypography.headingMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: paymentHistoryAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.history,
              message: isArabic ? 'لا توجد مدفوعات سابقة' : 'No payment history',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: payments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final payment = payments[index];
              return _buildPaymentCard(context, payment, isDark, isArabic);
            },
          );
        },
        loading: () => const LoadingStateWidget(),
        error: (error, stack) => ErrorStateWidget(
          message: isArabic ? 'حدث خطأ أثناء جلب السجل' : 'Error fetching history',
          retryLabel: isArabic ? 'إعادة المحاولة' : 'Retry',
          onRetry: () => ref.invalidate(paymentHistoryProvider),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    dynamic payment,
    bool isDark,
    bool isArabic,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm a');
    final formattedDate = dateFormat.format(payment.createdAt);

    Color statusColor;
    String statusText = payment.status.toUpperCase();
    if (payment.status == 'completed' ||
        payment.status == 'active' ||
        payment.status == 'success') {
      statusColor = AppColors.success;
      if (isArabic) statusText = 'مكتمل';
    } else if (payment.status == 'pending') {
      statusColor = AppColors.warning;
      if (isArabic) statusText = 'قيد الانتظار';
    } else {
      statusColor = AppColors.error;
      if (isArabic) statusText = payment.status == 'failed' ? 'فشل' : 'ملغى';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${payment.amount} ${payment.currency}',
                style: AppTypography.headingMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.credit_card_outlined,
            text: payment.paymentMethod.replaceAll('_', ' ').toUpperCase(),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            text: formattedDate,
            isDark: isDark,
          ),
          if (payment.referenceCode != null &&
              payment.referenceCode!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.tag_rounded,
              text: 'Ref: ${payment.referenceCode}',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
