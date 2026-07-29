---
name: UserSupportChatService
description: Firestore-based chat service for user-side operations — creating/reading support threads and sending user messages.
type: entity
tags: [firebase, chat]
sources: [sources/admin-chat-name-fix]
created: "2026-06-25"
updated: "2026-06-25"
---
# UserSupportChatService

## What it is

A service class (`lib/features/chat/services/user_support_chat_service.dart`) handling Firestore operations for the user side of the support chat: getting or creating the thread doc, sending messages, marking as read.

## Key facts

- `getOrCreateThread()` creates a `support_chats/{userId}` doc with `user_name`, `user_email`, and thread metadata
- **Bug:** Used `'User'` as the default `user_name` when no name was provided — this placeholder propagated everywhere
- `sendUserMessage()` updated `user_email` on every message but **never updated `user_name`**, so the placeholder never self-corrected
- **Fix 1:** `getOrCreateThread()` now saves empty string `''` instead of `'User'`
- **Fix 2:** `sendUserMessage()` now accepts optional `userName` parameter and updates `user_name` in the thread doc when a real name is provided

## See also

- [[entities/admin-chat-service]]
- [[entities/user-support-chat-provider]]
- [[concepts/admin-chat-display-name]]
- [[concepts/support-chat-thread]]
- [[sources/admin-chat-name-fix]]
