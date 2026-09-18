---
name: AdminChatService
description: Firestore-based chat service for admin-side operations — sending messages and updating thread metadata.
type: entity
tags: [firebase, chat]
sources: [sources/admin-chat-name-fix, sources/admin-chat-name-fix-2026-06-26]
created: "2026-06-25"
updated: "2026-07-29"
---
# AdminChatService

## What it is

A service class (`lib/features/admin/services/admin_chat_service.dart`) handling Firestore operations for the admin side of the support chat: writing messages to `support_chats/{userId}/messages/` and updating the thread doc.

## Key facts

- `sendAdminMessage()` writes the message and updates `last_message`, `last_message_time`, `unread_count_user`, and optionally `user_name` and `user_email`
- **Bug:** The service wrote `user_name` unconditionally when non-null — but the value could be `'User'` from the thread doc, cementing the placeholder
- **Fix:** Now only writes `user_name` if it's a real name — non-empty, non-`'User'` (case-insensitive)
- `resolveRealName(userId)` reads the real name from `users/{userId}` through the existing `resolveDisplayName` / `resolveDisplayNameFromUserDoc` helpers
- `resolveDisplayNameForThread(thread)` combines the cached thread value with a users-collection lookup, performing the read only when the cached value is a placeholder
- `broadcastMessageWithReport` wrote raw `userData['name']` and so kept creating new `'User'` values; it now writes `resolveDisplayNameFromUserDoc(userData) ?? ''`

## See also

- [[sources/admin-chat-name-fix-2026-06-26]]
- [[entities/user-support-chat-service]]
- [[entities/admin-chat-detail-screen]]
- [[concepts/support-chat-thread]]
- [[concepts/admin-chat-display-name]]
- [[sources/admin-chat-name-fix]]
