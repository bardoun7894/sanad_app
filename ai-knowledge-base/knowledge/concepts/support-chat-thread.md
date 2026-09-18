---
name: Support Chat Thread
description: "Firestore document model for one-to-one support chat threads — schema, creation patterns, and name/email metadata lifecycle."
type: concept
tags: [auth, firebase, collection]
sources: [sources/admin-chat-name-fix, sources/admin-chat-name-fix-2026-06-26]
created: "2026-06-25"
updated: "2026-07-29"
---
# Support Chat Thread

## Overview

Support chat threads live in the `support_chats` Firestore collection, one document per user (`support_chats/{userId}`). Each thread doc contains thread metadata (last_message, last_message_time, unread counts) plus user info (user_name, user_email). Messages are stored in a subcollection: `support_chats/{userId}/messages/{messageId}`.

## Thread Creation

Threads are created lazily by `UserSupportChatService.getOrCreateThread()`, which checks if the doc exists before creating. The `user_name` field is set at creation time from the `userName` parameter — which now comes from Firebase Auth's `user.displayName` threaded through `SupportChatParams`.

## Name Propagation

The `user_name` field is updated by:
- **Admin side** — `sendAdminMessage()` writes `user_name` only if it's a real name (non-empty, not `'User'`)
- **User side** — `sendUserMessage()` now accepts and writes `user_name` when a real name is available

Previously, neither path reliably corrected a placeholder `'User'` name. The admin path wrote it back as-is, and the user path never wrote `user_name` at all.

- **Broadcast side** — `broadcastMessageWithReport` wrote raw `userData['name']`, which meant broadcasts kept minting new `'User'` values in thread docs long after the send paths were fixed. It now resolves the name first.

## Reading the cached name

`user_name` is a cache of the users collection, so it can be stale or hold a placeholder. `ChatThread.fallbackDisplayName` treats `'User'` as absent and falls back to `user_email`, then to `'Unknown User'`. Consumers that need the true name call `AdminChatService.resolveDisplayNameForThread`, which reads `users/{userId}` only when the cached value fails the placeholder check — keeping the common case free of an extra read.

## See also

- [[sources/admin-chat-name-fix-2026-06-26]]
- [[concepts/therapist-chat-id-convention]]
- [[entities/user-support-chat-service]]
- [[entities/admin-chat-service]]
- [[concepts/admin-chat-display-name]]
- [[sources/admin-chat-name-fix]]
