import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../services/admin_chat_service.dart';
import '../admin_bento_ui.dart';
import 'admin_chat_message_bubble.dart';

/// Reusable 2026 Bento conversation workspace used both inside the desktop
/// split-pane Support Inbox and standalone in [AdminChatDetailScreen].
class AdminChatConversationPane extends ConsumerStatefulWidget {
  final ChatThread thread;
  final bool embedded;
  final VoidCallback? onOpenFullScreen;

  const AdminChatConversationPane({
    super.key,
    required this.thread,
    this.embedded = false,
    this.onOpenFullScreen,
  });

  @override
  ConsumerState<AdminChatConversationPane> createState() =>
      _AdminChatConversationPaneState();
}

class _AdminChatConversationPaneState
    extends ConsumerState<AdminChatConversationPane> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = AdminChatService();
  late Future<String> _nameFuture;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initThread();
  }

  @override
  void didUpdateWidget(covariant AdminChatConversationPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thread.userId != widget.thread.userId) {
      _messageController.clear();
      _initThread();
    }
  }

  void _initThread() {
    _nameFuture = _chatService.resolveDisplayNameForThread(widget.thread);
    _chatService.markAsRead(widget.thread.userId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    _messageController.clear();
    setState(() => _sending = true);

    try {
      String nameToUse = widget.thread.userName;
      if (nameToUse.isEmpty || nameToUse.toLowerCase() == 'user') {
        final realName = await _chatService.resolveRealName(
          widget.thread.userId,
        );
        if (realName != null) nameToUse = realName;
      }

      await _chatService.sendAdminMessage(
        widget.thread.userId,
        text,
        userEmail: widget.thread.userEmail,
        userName: nameToUse,
      );
    } catch (e) {
      if (mounted) {
        final isAr = ref.read(languageProvider).language == AppLanguage.arabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'فشل إرسال الرسالة: $e' : 'Failed to send: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _insertEmoji(String emoji) {
    final value = _messageController.value;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : value.text.length;
    final end = sel.isValid ? sel.end : value.text.length;
    final newText = value.text.replaceRange(start, end, emoji);
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isAr = ref.watch(languageProvider).language == AppLanguage.arabic;
    final thread = widget.thread;
    final fallbackName = thread.fallbackDisplayName;

    return Column(
      children: [
        // ── Conversation Header ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AdminBento.surface(isDark),
            border: Border(
              bottom: BorderSide(color: AdminBento.border(isDark)),
            ),
          ),
          child: Row(
            children: [
              if (!widget.embedded) ...[
                AdminHeaderIconButton(
                  icon: isRtl
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                  tooltip: isAr ? 'رجوع' : 'Back',
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/admin/chat');
                    }
                  },
                ),
                const SizedBox(width: 12),
              ],
              FutureBuilder<String>(
                future: _nameFuture,
                initialData: fallbackName,
                builder: (context, snapshot) {
                  final displayName = snapshot.data ?? fallbackName;
                  final initial = displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?';
                  return Expanded(
                    child: InkWell(
                      onTap: () =>
                          context.push('/admin/users/${thread.userId}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 19,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              ),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AdminBento.textPrimary(isDark),
                                    ),
                                  ),
                                  if (thread.userEmail.isNotEmpty &&
                                      thread.userEmail != displayName)
                                    Text(
                                      thread.userEmail,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AdminBento.textSecondary(isDark),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              AdminBentoButton(
                icon: Icons.person_outline_rounded,
                label: isAr ? 'ملف المريض' : 'Profile',
                onPressed: () => context.push('/admin/users/${thread.userId}'),
              ),
              if (widget.embedded && widget.onOpenFullScreen != null) ...[
                const SizedBox(width: 6),
                AdminHeaderIconButton(
                  icon: Icons.open_in_full_rounded,
                  tooltip: isAr ? 'فتح بشاشة كاملة' : 'Open full screen',
                  onTap: widget.onOpenFullScreen!,
                ),
              ],
            ],
          ),
        ),

        // ── Message Stream ──────────────────────────────────────────────
        Expanded(
          child: Container(
            color: isDark
                ? AppColors.adminBackground.withValues(alpha: 0.55)
                : const Color(0xFFF8FAFC),
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(thread.userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      isAr
                          ? 'حدث خطأ: ${snapshot.error}'
                          : 'Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isAr ? 'ابدأ المحادثة الآن' : 'Start the conversation',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AdminBento.textPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr
                              ? 'اكتب رسالتك الأولى أدناه للتواصل مع المريض.'
                              : 'Type your first reply below to message the patient.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AdminBento.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isAdmin = message.senderId == 'admin';
                    // Because list is reversed, index+1 is chronologically older.
                    final showDateHeader =
                        index == messages.length - 1 ||
                        !_isSameDay(
                          message.timestamp,
                          messages[index + 1].timestamp,
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateHeader)
                          AdminChatDatePill(
                            timestamp: message.timestamp,
                            isDark: isDark,
                            isAr: isAr,
                          ),
                        AdminChatMessageBubble(
                          message: message,
                          isAdmin: isAdmin,
                          isDark: isDark,
                          isAr: isAr,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),

        // ── Composer Bar ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: AdminBento.surface(isDark),
            border: Border(top: BorderSide(color: AdminBento.border(isDark))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AdminBento.surfaceMuted(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminBento.borderStrong(isDark)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined),
                        tooltip: isAr ? 'رموز تعبيرية' : 'Emoji',
                        iconSize: 20,
                        color: AdminBento.textSecondary(isDark),
                        onPressed: () => showAdminChatEmojiPicker(
                          context: context,
                          isDark: isDark,
                          onEmojiSelected: _insertEmoji,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(
                            fontSize: 14,
                            color: AdminBento.textPrimary(isDark),
                          ),
                          minLines: 1,
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            filled: false,
                            hintText: isAr
                                ? 'اكتب ردك هنا...'
                                : 'Type a reply...',
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: AdminBento.textSecondary(isDark),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _sending ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
