import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/app_colors.dart';
import '../../services/admin_chat_service.dart';
import '../admin_bento_ui.dart';

/// Shows the 2026 Bento emoji picker modal sheet for the admin chat composer.
void showAdminChatEmojiPicker({
  required BuildContext context,
  required bool isDark,
  required ValueChanged<String> onEmojiSelected,
}) {
  const emojis = [
    '😀', '😊', '😄', '😁', '🙂', '😉', '😍', '🥰', '😘', '😎',
    '🤝', '🙏', '👍', '👏', '🙌', '💪', '✅', '❤️', '💚', '💙',
    '🌸', '🔥', '🎉', '✨', '⭐', '😢', '🥺', '😔', '😮', '🤔',
    '👋', '🤲', '☺️', '💬', '📌', '⚡', '💯', '🌟', '🤗', '😇',
  ];
  showModalBottomSheet(
    context: context,
    backgroundColor: AdminBento.surface(isDark),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in emojis)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  onEmojiSelected(e);
                  Navigator.of(ctx).pop();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(e, style: const TextStyle(fontSize: 24)),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Centered pill divider showing a bilingual day label (Today / Yesterday / date).
class AdminChatDatePill extends StatelessWidget {
  final DateTime timestamp;
  final bool isDark;
  final bool isAr;

  const AdminChatDatePill({
    super.key,
    required this.timestamp,
    required this.isDark,
    required this.isAr,
  });

  String _dateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return isAr ? 'اليوم' : 'Today';
    if (diff == 1) return isAr ? 'أمس' : 'Yesterday';
    return DateFormat('d MMM yyyy').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AdminBento.surface(isDark),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AdminBento.border(isDark)),
          ),
          child: Text(
            _dateLabel(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AdminBento.textSecondary(isDark),
            ),
          ),
        ),
      ),
    );
  }
}

/// RTL-aware 2026 Bento message bubble with optional network image preview,
/// selectable text, and quick copy action.
class AdminChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isAdmin;
  final bool isDark;
  final bool isAr;

  const AdminChatMessageBubble({
    super.key,
    required this.message,
    required this.isAdmin,
    required this.isDark,
    required this.isAr,
  });

  void _copyText(BuildContext context) {
    if (message.content.isNotEmpty && message.content != '📷') {
      Clipboard.setData(ClipboardData(text: message.content));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم النسخ' : 'Copied'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAdmin
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.62,
        ),
        child: Column(
          crossAxisAlignment: isAdmin
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAdmin ? AppColors.primary : AdminBento.surface(isDark),
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(isAdmin ? 16 : 4),
                  topEnd: Radius.circular(isAdmin ? 4 : 16),
                  bottomStart: const Radius.circular(16),
                  bottomEnd: const Radius.circular(16),
                ),
                border: isAdmin
                    ? null
                    : Border.all(color: AdminBento.border(isDark)),
                boxShadow: [
                  BoxShadow(
                    color: isAdmin
                        ? AppColors.primary.withValues(alpha: 0.16)
                        : const Color(0xFF0F172A).withValues(alpha: 0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        message.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, child, progress) => progress == null
                            ? child
                            : const SizedBox(
                                width: 180,
                                height: 130,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                        errorBuilder: (c, e, s) => const SizedBox(
                          width: 180,
                          height: 130,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                    if (message.content.isNotEmpty && message.content != '📷')
                      const SizedBox(height: 8),
                  ],
                  if (message.content.isNotEmpty && message.content != '📷')
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SelectableText(
                            message.content,
                            style: TextStyle(
                              color: isAdmin
                                  ? Colors.white
                                  : AdminBento.textPrimary(isDark),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: isAr ? 'نسخ' : 'Copy',
                          child: InkWell(
                            onTap: () => _copyText(context),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 13,
                                color: isAdmin
                                    ? Colors.white70
                                    : AdminBento.textSecondary(isDark),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: TextStyle(
                color: AdminBento.textSecondary(isDark),
                fontSize: 10.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
