import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/admin_chat_service.dart';

/// Admin-only composer for sending a general announcement to every user's
/// in-app notification bell.
///
/// Writes one doc per user to `notifications/` (no chat thread). The bell
/// stream picks them up immediately. Open via showDialog.
class BroadcastNotificationDialog extends StatefulWidget {
  const BroadcastNotificationDialog({super.key});

  @override
  State<BroadcastNotificationDialog> createState() =>
      _BroadcastNotificationDialogState();
}

class _BroadcastNotificationDialogState
    extends State<BroadcastNotificationDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;
  String? _error;
  BroadcastReport? _report;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      setState(() => _error = 'Title and message are both required.');
      return;
    }
    setState(() {
      _isSending = true;
      _error = null;
      _report = null;
    });

    try {
      final report =
          await AdminChatService().broadcastNotificationToAllUsers(
        title: title,
        body: body,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _report = report;
      });
      if (report.isSuccess) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = 'Send failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final report = _report;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          const Expanded(child: Text('Send Notification')),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This announcement will appear in the bell icon for ALL users.',
              style: TextStyle(
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              maxLength: 80,
              enabled: !_isSending,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. New feature available',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor:
                    isDark ? AppColors.adminSurface : AppColors.background,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              maxLength: 280,
              enabled: !_isSending,
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Write the body of the announcement…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor:
                    isDark ? AppColors.adminSurface : AppColors.background,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ResultBanner(
                text: _error!,
                color: AppColors.error,
                background: AppColors.error.withValues(alpha: 0.1),
              ),
            ],
            if (report != null) ...[
              const SizedBox(height: 12),
              _ResultBanner(
                text: report.isSuccess
                    ? 'Sent to ${report.sentCount} users.'
                    : 'Sent to ${report.sentCount}, failed ${report.failedCount}.',
                color: report.isSuccess ? Colors.green : AppColors.statusWarning,
                background: (report.isSuccess
                        ? Colors.green
                        : AppColors.statusWarning)
                    .withValues(alpha: 0.1),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _send,
          icon: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.campaign_rounded),
          label: Text(_isSending ? 'Sending…' : 'Send to All'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _ResultBanner({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
