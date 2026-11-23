import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../services/admin_chat_service.dart';
import '../widgets/admin_bento_ui.dart';
import '../widgets/chat/admin_chat_conversation_pane.dart';

/// Riverpod provider that resolves a [ChatThread] by userId from Firestore.
/// Used as a fallback when GoRouter's state.extra is lost on Flutter Web
/// URL rehydration (idle reconnect).
final chatThreadByUserIdProvider = StreamProvider.family<ChatThread?, String>((
  ref,
  userId,
) {
  if (userId.isEmpty) return const Stream.empty();
  return AdminChatService().getChatThread(userId);
});

class AdminChatDetailScreen extends ConsumerWidget {
  /// The userId that identifies the support_chats document.
  final String userId;

  /// Fast-path thread passed via GoRouter state.extra.
  final ChatThread? initialThread;

  const AdminChatDetailScreen({
    super.key,
    required this.userId,
    this.initialThread,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (initialThread != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AdminBento.cardRadius),
            child: Container(
              decoration: AdminBento.cardDecoration(isDark),
              child: AdminChatConversationPane(thread: initialThread!),
            ),
          ),
        ),
      );
    }

    final asyncThread = ref.watch(chatThreadByUserIdProvider(userId));

    return asyncThread.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/admin/chat');
        });
        return const SizedBox.shrink();
      },
      data: (thread) {
        final resolved =
            thread ??
            ChatThread(
              userId: userId,
              userEmail: '',
              userName: '',
              lastMessage: '',
              lastMessageTime: DateTime.now(),
            );
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AdminBento.cardRadius),
              child: Container(
                decoration: AdminBento.cardDecoration(isDark),
                child: AdminChatConversationPane(thread: resolved),
              ),
            ),
          ),
        );
      },
    );
  }
}
