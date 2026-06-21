import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_chat_service.dart';

// ---------------------------------------------------------------------------
// Pure helper functions (tested in isolation)
// ---------------------------------------------------------------------------

/// Sums [ChatThread.unreadCount] across all threads.
int totalUnreadFromThreads(List<ChatThread> threads) {
  return threads.fold(0, (sum, t) => sum + t.unreadCount);
}

/// Returns the badge label string:
/// - "" when total == 0 (badge is hidden)
/// - "1".."9" for low counts
/// - "9+" when total > 9
String unreadBadgeLabel(int total) {
  if (total <= 0) return '';
  if (total > 9) return '9+';
  return '$total';
}

/// Returns true only when the toast should fire:
/// - `prev` is null → first emission, initialize silently → false
/// - `next` > `prev` AND admin is NOT already on the chat screen
bool shouldShowNewMessageToast({
  required int? prev,
  required int next,
  bool onChatScreen = false,
}) {
  if (prev == null) return false;
  if (next <= prev) return false;
  if (onChatScreen) return false;
  return true;
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

/// Singleton service instance used by admin providers.
final adminChatServiceProvider = Provider<AdminChatService>(
  (ref) => AdminChatService(),
);

/// Streams the raw list of chat threads (all support_chats).
final adminChatThreadsProvider = StreamProvider<List<ChatThread>>(
  (ref) => ref.watch(adminChatServiceProvider).getChatThreads(),
);

/// Derived provider: total unread count across all threads.
final adminTotalUnreadProvider = StreamProvider<int>((ref) {
  return ref
      .watch(adminChatServiceProvider)
      .getChatThreads()
      .map(totalUnreadFromThreads);
});
