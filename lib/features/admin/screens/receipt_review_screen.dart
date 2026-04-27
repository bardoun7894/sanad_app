import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/skeuomorphic_button.dart';
import '../providers/admin_provider.dart';
import '../models/payment_verification.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final PaymentVerification verification;
  const ReceiptReviewScreen({super.key, required this.verification});

  @override
  ConsumerState<ReceiptReviewScreen> createState() =>
      _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  bool _isProcessing = false;

  Future<void> _handleApprove() async {
    setState(() => _isProcessing = true);
    try {
      final success = await ref
          .read(adminProvider.notifier)
          .approveVerification(widget.verification.id);
      if (success && mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject(String reason) async {
    setState(() => _isProcessing = true);
    try {
      final success = await ref
          .read(adminProvider.notifier)
          .rejectVerification(widget.verification.id, reason);
      if (success && mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
        final primaryText = isDark ? Colors.white : AppColors.textPrimary;
        final hintColor = isDark ? Colors.white54 : AppColors.textMuted;
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(
            'Reject Verification',
            style: TextStyle(color: primaryText),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: primaryText),
            decoration: InputDecoration(
              hintText: 'Reason for rejection...',
              hintStyle: TextStyle(color: hintColor),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleReject(controller.text);
              },
              child: const Text(
                'Reject',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = ref.watch(stringsProvider);
    final verification = widget.verification;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Review Receipt'),
        leading: BackButton(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(verification, s),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildInfoSection(
                        'User Information',
                        Icons.person_outline_rounded,
                        [
                          _InfoRow('Name', verification.userName, textColor),
                          _InfoRow('Email', verification.userEmail, textColor),
                          _InfoRow('User ID', verification.odId, textColor),
                        ],
                        textColor,
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection(
                        'Payment Details',
                        Icons.payments_outlined,
                        [
                          _InfoRow(
                            'Amount',
                            '${verification.currency} ${verification.amount}',
                            textColor,
                          ),
                          _InfoRow(
                            'Ref Code',
                            verification.referenceCode,
                            textColor,
                          ),
                          _InfoRow(
                            'Date',
                            verification.createdAt.toString(),
                            textColor,
                          ),
                        ],
                        textColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (verification.receiptUrl != null)
                        _ReceiptImage(url: verification.receiptUrl!, s: s)
                      else
                        _EmptyReceiptPlaceholder(s: s, textColor: textColor),
                      const SizedBox(height: 32),
                      if (verification.status == VerificationStatus.pending)
                        Column(
                          children: [
                            SkeuomorphicButton(
                              onPressed: _isProcessing ? null : _handleApprove,
                              baseColor: AppColors.success,
                              child: const Text('Approve Payment'),
                            ),
                            const SizedBox(height: 16),
                            SkeuomorphicButton(
                              onPressed: _isProcessing
                                  ? null
                                  : _showRejectDialog,
                              baseColor: AppColors.error,
                              child: const Text('Reject Payment'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(PaymentVerification verification, dynamic s) {
    final statusColor = _getStatusColor(verification.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Text(
            'Status: ${verification.status.name.toUpperCase()}',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return AppColors.warning;
      case VerificationStatus.approved:
        return AppColors.success;
      case VerificationStatus.rejected:
        return AppColors.error;
    }
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    List<Widget> rows,
    Color textColor,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 32),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;
  const _InfoRow(this.label, this.value, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor.withOpacity(0.5))),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptImage extends StatelessWidget {
  final String url;
  final dynamic s;
  const _ReceiptImage({required this.url, required this.s});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Image.network(
        url,
        fit: BoxFit.contain,
        height: 400,
        width: double.infinity,
      ),
    );
  }
}

class _EmptyReceiptPlaceholder extends StatelessWidget {
  final dynamic s;
  final Color textColor;
  const _EmptyReceiptPlaceholder({required this.s, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: textColor.withOpacity(0.2),
          ),
          const SizedBox(height: 12),
          const Text(
            'No receipt image provided',
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
