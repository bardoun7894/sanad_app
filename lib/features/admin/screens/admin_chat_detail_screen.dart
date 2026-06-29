import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../services/admin_chat_service.dart';
import 'package:intl/intl.dart';

/// Riverpod provider that resolves a [ChatThread] by userId from Firestore.
/// Used as a fallback when GoRouter's state.extra is lost on Flutter Web
/// URL rehydration (idle reconnect).
final chatThreadByUserIdProvider =
    StreamProvider.family<ChatThread?, String>((ref, userId) {
  if (userId.isEmpty) return const Stream.empty();
  return AdminChatService().getChatThread(userId);
});

class AdminChatDetailScreen extends ConsumerStatefulWidget {
  /// The userId that identifies the support_chats document. Always present
  /// (comes from the URL path param).
  final String userId;

  /// Fast-path thread passed via GoRouter state.extra. May be null when the
  /// page is reloaded from the URL (Flutter Web idle rehydration).
  final ChatThread? initialThread;

  const AdminChatDetailScreen({
    super.key,
    required this.userId,
    this.initialThread,
  });

  @override
  ConsumerState<AdminChatDetailScreen> createState() =>
      _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends ConsumerState<AdminChatDetailScreen> {
  final _messageController = TextEditingController();
  final _chatService = AdminChatService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark as read immediately if we already have the thread (fast path).
    _chatService.markAsRead(widget.userId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(ChatThread thread) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    try {
      // Resolve real name if the thread has a placeholder/missing name.
      String nameToUse = thread.userName;
      if (nameToUse.isEmpty || nameToUse.toLowerCase() == 'user') {
        final realName = await _chatService.resolveRealName(thread.userId);
        if (realName != null) nameToUse = realName;
      }

      await _chatService.sendAdminMessage(
        thread.userId,
        text,
        userEmail: thread.userEmail,
        userName: nameToUse,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fast path: extra thread was passed (no rehydration needed).
    if (widget.initialThread != null) {
      return _ChatDetailContent(
        thread: widget.initialThread!,
        chatService: _chatService,
        scrollController: _scrollController,
        messageController: _messageController,
        onSend: _sendMessage,
      );
    }

    // Slow path: resolve from Firestore (URL rehydration scenario).
    final asyncThread =
        ref.watch(chatThreadByUserIdProvider(widget.userId));

    return asyncThread.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.adminBackground
            : AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) {
        // Error — redirect to list.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/admin/chat');
        });
        return const SizedBox.shrink();
      },
      data: (thread) {
        if (thread == null) {
          // Thread not found — redirect to list.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/admin/chat');
          });
          return const SizedBox.shrink();
        }
        return _ChatDetailContent(
          thread: thread,
          chatService: _chatService,
          scrollController: _scrollController,
          messageController: _messageController,
          onSend: _sendMessage,
        );
      },
    );
  }
}

/// Displays the chat once a thread is known.
class _ChatDetailContent extends StatefulWidget {
  final ChatThread thread;
  final AdminChatService chatService;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final void Function(ChatThread thread) onSend;

  const _ChatDetailContent({
    required this.thread,
    required this.chatService,
    required this.scrollController,
    required this.messageController,
    required this.onSend,
  });

  @override
  State<_ChatDetailContent> createState() => _ChatDetailContentState();
}

class _ChatDetailContentState extends State<_ChatDetailContent> {
  late final Future<String> _nameFuture;

  @override
  void initState() {
    super.initState();
    _nameFuture = widget.chatService.resolveDisplayNameForThread(widget.thread);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final isDark = theme.brightness == Brightness.dark;
    final thread = widget.thread;

    // Never show placeholder 'User' — fall back to email, and resolve the
    // real name from `users/{userId}` when available.
    final fallbackName = thread.fallbackDisplayName;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.adminBackground
          : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 52,
        title: FutureBuilder<String>(
          future: _nameFuture,
          initialData: fallbackName,
          builder: (context, snapshot) {
            final displayName = snapshot.data ?? fallbackName;
            // Tapping the name opens the client's account/profile data.
            return InkWell(
              onTap: () => context.push('/admin/users/${thread.userId}'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        leading: BackButton(color: textColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.chatService.getMessages(thread.userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
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
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: textColor.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start the conversation',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: widget.scrollController,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isAdmin = message.senderId == 'admin';

                    return _ChatBubble(
                      message: message,
                      isAdmin: isAdmin,
                      textColor: textColor,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(context, textColor, isDark, thread),
        ],
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    Color textColor,
    bool isDark,
    ChatThread thread,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2B3943) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    tooltip: 'Emoji',
                    color: isDark ? Colors.white54 : Colors.black54,
                    onPressed: () => _showEmojiPicker(context, isDark),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.messageController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      // Enter inserts a new line (for long, organized replies);
                      // sending is done with the send button only.
                      minLines: 1,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type a reply…',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(onPressed: () => widget.onSend(thread)),
        ],
      ),
    );
  }

  /// Insert [emoji] at the current cursor position (or append if no selection).
  void _insertEmoji(String emoji) {
    final value = widget.messageController.value;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : value.text.length;
    final end = sel.isValid ? sel.end : value.text.length;
    final newText = value.text.replaceRange(start, end, emoji);
    widget.messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void _showEmojiPicker(BuildContext context, bool isDark) {
    const emojis = [
      '😀', '😊', '😄', '😁', '🙂', '😉', '😍', '🥰', '😘', '😎',
      '🤝', '🙏', '👍', '👏', '🙌', '💪', '✅', '❤️', '💚', '💙',
      '🌸', '🔥', '🎉', '✨', '⭐', '😢', '🥺', '😔', '😮', '🤔',
      '👋', '🤲', '☺️', '💬', '📌', '⚡', '💯', '🌟', '🤗', '😇',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F2A33) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final e in emojis)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _insertEmoji(e);
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
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isAdmin;
  final Color textColor;

  const _ChatBubble({
    required this.message,
    required this.isAdmin,
    required this.textColor,
  });

  void _copyText(BuildContext context) {
    if (message.content.isNotEmpty && message.content != '📷') {
      Clipboard.setData(ClipboardData(text: message.content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isAdmin
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppColors.primary
                        : (isDark ? AppColors.adminSurface : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isAdmin ? 16 : 0),
                      topRight: Radius.circular(isAdmin ? 0 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        offset: const Offset(0, 1),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
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
                    if (message.content.isNotEmpty &&
                        message.content != '📷')
                      const SizedBox(height: 6),
                  ],
                  if (message.content.isNotEmpty && message.content != '📷')
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              message.content,
                              style: TextStyle(
                                color: isAdmin
                                    ? Colors.white
                                    : (isDark ? Colors.white : AppColors.textPrimary),
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _copyText(context),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 13,
                                color: isAdmin
                                    ? Colors.white60
                                    : (isDark ? Colors.white38 : Colors.black38),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SendButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
