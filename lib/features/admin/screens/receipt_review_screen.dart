import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/widgets/sanad_button.dart';
import '../providers/admin_provider.dart';
import '../models/payment_verification.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final PaymentVerification verification;

  const ReceiptReviewScreen({super.key, required this.verification});

  @override
  ConsumerState<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  bool _isProcessing = false;
  final _rejectionController = TextEditingController();

  @override
  void dispose() {
    _rejectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final verification = widget.verification;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.reviewReceipt),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            if (verification.status != VerificationStatus.pending)
              _StatusBanner(
                status: verification.status,
                rejectionReason: verification.rejectionReason,
              ),

            // User info card
            _InfoCard(
              title: s.userInformation,
              icon: Icons.person_outline,
              children: [
                _InfoRow(label: s.name, value: verification.userName),
                _InfoRow(label: s.email, value: verification.userEmail),
                _InfoRow(label: s.userId, value: verification.odId),
              ],
            ),

            const SizedBox(height: 16),

            // Payment info card
            _InfoCard(
              title: s.paymentDetails,
              icon: Icons.payment_outlined,
              children: [
                _InfoRow(label: s.product, value: verification.productTitle),
                _InfoRow(
                  label: s.amount,
                  value: '${verification.currency} ${verification.amount.toStringAsFixed(2)}',
                  valueColor: AppColors.success,
                ),
                _InfoRow(label: s.referenceCode, value: verification.referenceCode),
                _InfoRow(label: s.submittedAt, value: _formatDateTime(verification.createdAt)),
              ],
            ),

            const SizedBox(height: 16),

            // Receipt image
            Text(
              s.receiptImage,
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 12),

            if (verification.receiptUrl != null && verification.receiptUrl!.isNotEmpty)
              GestureDetector(
                onTap: () => _showFullImage(context, verification.receiptUrl!),
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.network(
                          verification.receiptUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_outlined,
                                      size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 8),
                                  Text(s.failedToLoadImage,
                                      style: TextStyle(color: AppColors.textMuted)),
                                ],
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(s.tapToZoom,
                                    style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 8),
                      Text(s.noReceiptUploaded,
                          style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons (only for pending)
            if (verification.status == VerificationStatus.pending) ...[
              SanadButton(
                text: s.approvePayment,
                icon: Icons.check_circle_outline,
                onPressed: _isProcessing ? null : () => _handleApprove(),
                isFullWidth: true,
                size: SanadButtonSize.large,
              ),
              const SizedBox(height: 12),
              SanadButton(
                text: s.rejectPayment,
                icon: Icons.cancel_outlined,
                onPressed: _isProcessing ? null : () => _showRejectDialog(),
                isFullWidth: true,
                size: SanadButtonSize.large,
                variant: SanadButtonVariant.outline,
              ),
            ],

            // Review info (for processed)
            if (verification.status != VerificationStatus.pending &&
                verification.reviewedAt != null) ...[
              const SizedBox(height: 16),
              _InfoCard(
                title: s.reviewDetails,
                icon: Icons.history,
                children: [
                  _InfoRow(label: s.reviewedAt, value: _formatDateTime(verification.reviewedAt!)),
                  _InfoRow(label: s.reviewedBy, value: verification.reviewedBy ?? 'Unknown'),
                ],
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove() async {
    final s = ref.read(stringsProvider);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.confirmApproval),
        content: Text(s.approvalConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(s.approve, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    final success = await ref
        .read(adminProvider.notifier)
        .approveVerification(widget.verification.id);

    setState(() => _isProcessing = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.paymentApproved),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showRejectDialog() {
    final s = ref.read(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(s.rejectPayment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.rejectionReasonPrompt),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: s.enterRejectionReason,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleReject(_rejectionController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(s.reject, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReject(String reason) async {
    final s = ref.read(stringsProvider);

    setState(() => _isProcessing = true);

    final success = await ref
        .read(adminProvider.notifier)
        .rejectVerification(widget.verification.id, reason);

    setState(() => _isProcessing = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.paymentRejected),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullImageScreen(imageUrl: imageUrl),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBanner extends ConsumerWidget {
  final VerificationStatus status;
  final String? rejectionReason;

  const _StatusBanner({required this.status, this.rejectionReason});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isApproved = status == VerificationStatus.approved;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: (isApproved ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApproved ? AppColors.success : AppColors.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApproved ? Icons.check_circle : Icons.cancel,
                color: isApproved ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                isApproved ? s.paymentApproved : s.paymentRejected,
                style: TextStyle(
                  color: isApproved ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (rejectionReason != null && rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${s.reason}: $rejectionReason',
              style: TextStyle(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: valueColor ?? (isDark ? Colors.white : AppColors.textLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullImageScreen extends StatelessWidget {
  final String imageUrl;

  const _FullImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
