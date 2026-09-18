# Fix: Support chat list showing "User" / "Unknown User" placeholders

## Problem
The admin support inbox (`AdminChatListScreen`) and chat detail screen (`AdminChatDetailScreen`) displayed generic placeholders instead of real user names for some threads. Screenshot showed entries labeled "User" and "Unknown User".

## Root cause
1. Legacy signup code wrote the literal string `"User"` as the default display name for some accounts.
2. `support_chats` thread documents cached `user_name` from the users collection. Historical threads, and the broadcast path, stored `"User"` as the cached name.
3. The list card only checked `userName.isNotEmpty`, so `"User"` was rendered verbatim.
4. When `user_email` was missing, the thread model fell back to `"Unknown User"`.

## Fix
- Added `ChatThread.fallbackDisplayName` that treats `"User"` as absent and falls back to email / "Unknown User".
- Added `AdminChatService.resolveRealName(userId)` to fetch the real name from `users/{userId}` using the existing `resolveDisplayName` / `resolveDisplayNameFromUserDoc` helpers.
- Added `AdminChatService.resolveDisplayNameForThread(thread)` to combine cached thread data with a users-collection lookup only when needed.
- Wrapped the name label in `_ChatThreadCard` and `_ChatDetailContent` with `FutureBuilder` so real names load asynchronously while the email fallback shows instantly.
- Fixed `broadcastMessageWithReport` to write `resolveDisplayNameFromUserDoc(userData) ?? ''` instead of raw `userData['name']`, preventing future `"User"` writes.
- The existing `sendAdminMessage` already rejected the placeholder; detail-screen send now reuses `resolveRealName` to write the real name when replying to a placeholder thread.

## Files changed
- `lib/features/admin/services/admin_chat_service.dart`
- `lib/features/admin/screens/admin_chat_list_screen.dart`
- `lib/features/admin/screens/admin_chat_detail_screen.dart`
- `test/features/admin/admin_chat_route_fix_test.dart`

## Verification
- `flutter analyze` clean on the four changed files.
- `flutter test test/features/admin/admin_chat_route_fix_test.dart test/features/admin/admin_unread_badge_test.dart test/core/utils/user_display_name_test.dart` all pass.
- `flutter build web --base-href="/s4n4d-ac42/"` succeeds.
