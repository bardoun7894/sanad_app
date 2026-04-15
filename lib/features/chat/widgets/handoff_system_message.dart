import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../models/chat_handoff.dart';

/// Special chat bubble rendered inline within the message list for handoff
/// events. Styled as a centered system message with a grey background,
/// distinct from regular user/bot bubbles.
class HandoffSystemMessage extends StatelessWidget {
  final ChatHandoff handoff;

  const HandoffSystemMessage({super.key, required this.handoff});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.8)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.5)
                  : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForStatus(), size: 16, color: _colorForStatus()),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _messageText(),
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _messageText() {
    switch (handoff.status) {
      case HandoffStatus.pending:
        return 'Requesting a therapist...';
      case HandoffStatus.accepted:
        if (handoff.therapistName != null) {
          return 'Session transferred to ${handoff.therapistName}';
        }
        return "You've been connected with a therapist";
      case HandoffStatus.inProgress:
        if (handoff.therapistName != null) {
          return 'In session with ${handoff.therapistName}';
        }
        return 'Therapist session in progress';
      case HandoffStatus.completed:
        return 'Therapist session ended';
      case HandoffStatus.expired:
        return 'Therapist request expired';
      case HandoffStatus.cancelled:
        return 'Therapist request cancelled';
    }
  }

  IconData _iconForStatus() {
    switch (handoff.status) {
      case HandoffStatus.pending:
        return Icons.hourglass_top_rounded;
      case HandoffStatus.accepted:
      case HandoffStatus.inProgress:
        return Icons.person_rounded;
      case HandoffStatus.completed:
        return Icons.check_circle_outline_rounded;
      case HandoffStatus.expired:
        return Icons.timer_off_rounded;
      case HandoffStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _colorForStatus() {
    switch (handoff.status) {
      case HandoffStatus.pending:
        return AppColors.warning;
      case HandoffStatus.accepted:
      case HandoffStatus.inProgress:
        return AppColors.success;
      case HandoffStatus.completed:
        return AppColors.info;
      case HandoffStatus.expired:
      case HandoffStatus.cancelled:
        return AppColors.textMuted;
    }
  }
}
