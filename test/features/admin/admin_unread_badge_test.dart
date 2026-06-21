import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/services/admin_chat_service.dart';
import 'package:sanad_app/features/admin/providers/admin_unread_provider.dart';

/// Tests for Issue 2a: in-dashboard new-message alert logic.
///
/// Covers:
/// 1. totalUnread() correctly sums unreadCount across all threads.
/// 2. Badge label caps at "9+" when total > 9.
/// 3. Toast suppression: toast fires only when new total > previous total.
/// 4. Toast suppressed on first emission (initialize prev silently).
/// 5. Toast suppressed when admin is already on chat screen.
void main() {
  group('totalUnreadFromThreads', () {
    test('returns 0 when thread list is empty', () {
      final threads = <ChatThread>[];
      expect(totalUnreadFromThreads(threads), 0);
    });

    test('sums unreadCount across all threads', () {
      final threads = [
        _thread('u1', unread: 3),
        _thread('u2', unread: 0),
        _thread('u3', unread: 5),
      ];
      expect(totalUnreadFromThreads(threads), 8);
    });

    test('single thread with unread', () {
      final threads = [_thread('u1', unread: 7)];
      expect(totalUnreadFromThreads(threads), 7);
    });

    test('ignores threads with zero unread', () {
      final threads = [
        _thread('u1', unread: 0),
        _thread('u2', unread: 0),
      ];
      expect(totalUnreadFromThreads(threads), 0);
    });
  });

  group('unreadBadgeLabel', () {
    test('returns empty string when total is 0 (badge hidden)', () {
      expect(unreadBadgeLabel(0), '');
    });

    test('returns count as string for 1..9', () {
      expect(unreadBadgeLabel(1), '1');
      expect(unreadBadgeLabel(9), '9');
    });

    test('returns "9+" when total exceeds 9', () {
      expect(unreadBadgeLabel(10), '9+');
      expect(unreadBadgeLabel(100), '9+');
    });
  });

  group('shouldShowNewMessageToast', () {
    test('does NOT fire on first emission (prev is null)', () {
      // On first load we initialize prev silently — no toast.
      expect(shouldShowNewMessageToast(prev: null, next: 5), false);
    });

    test('does NOT fire when total stays the same', () {
      expect(shouldShowNewMessageToast(prev: 3, next: 3), false);
    });

    test('does NOT fire when total decreases (admin read a message)', () {
      expect(shouldShowNewMessageToast(prev: 5, next: 3), false);
    });

    test('fires when total increases', () {
      expect(shouldShowNewMessageToast(prev: 0, next: 1), true);
      expect(shouldShowNewMessageToast(prev: 3, next: 4), true);
    });

    test('does NOT fire when onChatScreen is true even if total increased', () {
      expect(
        shouldShowNewMessageToast(prev: 2, next: 5, onChatScreen: true),
        false,
      );
    });

    test('fires when onChatScreen is false and total increased', () {
      expect(
        shouldShowNewMessageToast(prev: 2, next: 5, onChatScreen: false),
        true,
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

ChatThread _thread(String userId, {int unread = 0}) {
  return ChatThread(
    userId: userId,
    userEmail: '$userId@example.com',
    lastMessage: '',
    lastMessageTime: DateTime.now(),
    unreadCount: unread,
  );
}
