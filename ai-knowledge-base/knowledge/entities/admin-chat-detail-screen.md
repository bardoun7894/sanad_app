---
name: AdminChatDetailScreen
description: "Admin screen for one-to-one chat with a user support thread, receiving the thread via GoRouter state.extra or resolving it from Firestore."
type: entity
tags: [firebase, chat]
sources: [sources/admin-chat-name-fix, sources/admin-chat-name-fix-2026-06-26]
created: "2026-06-25"
updated: "2026-07-29"
---
# AdminChatDetailScreen

## What it is

The admin's one-to-one chat detail screen (`lib/features/admin/screens/admin_chat_detail_screen.dart`). It receives an optional `ChatThread` via `initialThread` parameter (from GoRouter `state.extra`) or resolves the thread from Firestore via `chatThreadByUserIdProvider`.

## Key facts

- Displays `thread.userName` in the AppBar; falls back to `thread.userEmail` if the name is empty or `'User'`
- Uses `AdminChatService.sendAdminMessage()` to send messages — but used to pass `thread.userName` directly, which could be `'User'`
- **Fix:** Added `_resolveRealName()` method that reads `users/{userId}` Firestore doc and resolves display name via `resolveDisplayNameFromUserDoc()`
- The resolved name is cached per session in `_resolvedNames` map
- Before sending, if `thread.userName` is empty or `'User'`, the real name is fetched and used instead
- The header label is wrapped in a `FutureBuilder` over `AdminChatService.resolveDisplayNameForThread`, so the email fallback renders immediately while the real name resolves — the name no longer pops in only after the first send
- Sending to a placeholder thread repairs it: the resolved name is written back via `resolveRealName`

## See also

- [[sources/admin-chat-name-fix-2026-06-26]]
- [[entities/admin-chat-service]]
- [[entities/mood-feed-screen]]
- [[concepts/admin-chat-display-name]]
- [[concepts/support-chat-thread]]
- [[sources/admin-chat-name-fix]]
