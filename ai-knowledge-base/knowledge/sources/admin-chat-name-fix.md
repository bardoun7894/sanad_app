---
name: "Admin Chat Name Fix — Root Cause Analysis & Fixes"
description: "Six-file fix chain resolving the \"Unknown\" user name bug in admin chat, traced from mood feed navigation through service-layer thread creation and display name resolution."
type: source
tags: [auth, ui, firebase]
sources: [raw/admin-chat-name-fix-2026-06-25.md]
created: "2026-06-25"
updated: "2026-06-25"
---
# Admin Chat Name Fix

## Summary

Messages sent from the admin dashboard's emotions tab (تبويب المشاعر) arrived in the chat screen without the client's name, showing "Unknown" instead. The root cause was a six-file chain: the mood feed navigated to chat without passing user info; the chat service saved `'User'` as a placeholder name; `resolveDisplayName` filtered out `'User'` → `null` → "Unknown"; and neither the admin message send nor the user message send ever corrected the placeholder.

## Key points

- **6 files** were modified across 3 layers (UI, service, provider) to fix the bug
- The core principle: **never write `'User'` as a user name to Firestore**; only write real, resolved display names
- When the current name is a placeholder (`'User'` or empty), resolve it from `users/{userId}` at the point of use (admin sending a message) rather than at thread creation time
- `SupportChatParams` and `SupportChatNotifier` were augmented with an optional `userName` field threaded from Firebase Auth's `user.displayName`

## See also

- [[entities/mood-feed-screen]]
- [[entities/admin-chat-detail-screen]]
- [[entities/admin-chat-service]]
- [[entities/user-support-chat-service]]
- [[entities/user-support-chat-provider]]
- [[concepts/admin-chat-display-name]]
- [[concepts/support-chat-thread]]
- [[sources/admin-chat-name-fix-2026-06-26]] — follow-up pass covering the list card, broadcast path, and async resolution
