---
name: UserSupportChatProvider
description: "Riverpod StateNotifier that manages user support chat session state — thread creation, message sending, AI escalation."
type: entity
tags: [auth, firebase]
sources: [sources/admin-chat-name-fix]
created: "2026-06-25"
updated: "2026-06-25"
---
# UserSupportChatProvider

## What it is

A Riverpod provider family (`lib/features/chat/providers/user_support_chat_provider.dart`) managing the `SupportChatNotifier` state and `SupportChatParams` for each user chat session.

## Key facts

- `SupportChatParams` used to carry only `userId` and `userEmail` — no `userName`
- `SupportChatNotifier` called `getOrCreateThread` and `sendUserMessage` without a userName, causing the service to fall back to `'User'`
- **Fix:** `SupportChatParams` now includes optional `userName` field
- `SupportChatNotifier` passes `userName` to both `getOrCreateThread` and `sendUserMessage`
- The `userName` is threaded from Firebase Auth's `user.displayName` via `user_support_chat_screen.dart`

## See also

- [[entities/user-support-chat-service]]
- [[concepts/admin-chat-display-name]]
- [[concepts/support-chat-thread]]
- [[sources/admin-chat-name-fix]]
