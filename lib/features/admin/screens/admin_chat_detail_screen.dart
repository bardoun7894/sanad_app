import 'package:flutter/material.dart';
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
      await _chatService.sendAdminMessage(
        thread.userId,
        text,
        userEmail: thread.userEmail,
        userName: thread.userName,
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

/// Pure-render widget that displays the chat once a thread is known.
class _ChatDetailContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final isDark = theme.brightness == Brightness.dark;

    final displayName = thread.userName.isNotEmpty
        ? thread.userName
        : thread.userEmail;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.adminBackground
          : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 52,
        title: Text(
          displayName,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        leading: BackButton(color: textColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatService.getMessages(thread.userId),
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
                  controller: scrollController,
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
              child: TextField(
                controller: messageController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Type a reply...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSend(thread),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(onPressed: () => onSend(thread)),
        ],
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
