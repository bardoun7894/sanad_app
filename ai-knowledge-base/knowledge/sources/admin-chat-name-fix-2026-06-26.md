---
name: Admin Chat Name Fix — List and Broadcast Follow-up
description: Second pass on the admin chat placeholder-name bug, covering the thread list card, the broadcast write path, and async name resolution
type: source
sources: [raw/admin-chat-name-fix-2026-06-26.md]
created: "2026-07-29"
updated: "2026-07-29"
---
# Admin Chat Name Fix — List and Broadcast Follow-up

## Summary

A follow-up to the 2026-06-25 fix, addressing the surfaces the first pass did not cover. The admin support inbox (`AdminChatListScreen`) and the chat detail screen still rendered `"User"` and `"Unknown User"` placeholders for some threads. Four overlapping causes were identified, spanning legacy signup data, cached thread metadata, an insufficient display check, and a missing-email fallback. The fix adds a placeholder-aware fallback on the thread model, an async name resolver on the service, and closes the broadcast write path that was still producing new `"User"` values.

## Key points

- Legacy signup code wrote the literal string `"User"` as the default display name on some accounts, so the placeholder originates in the `users` collection, not only in cached copies.
- `support_chats` thread documents cache `user_name` from the users collection; historical threads and the broadcast path had stored `"User"` there.
- The list card only tested `userName.isNotEmpty`, so `"User"` passed the check and rendered verbatim.
- When `user_email` was missing, the thread model fell back to `"Unknown User"` — a second, distinct placeholder.
- `ChatThread.fallbackDisplayName` now treats `"User"` as absent and falls back to email, then to `"Unknown User"`.
- `AdminChatService.resolveRealName(userId)` reads the real name from `users/{userId}` via the existing `resolveDisplayName` / `resolveDisplayNameFromUserDoc` helpers.
- `AdminChatService.resolveDisplayNameForThread(thread)` combines cached thread data with a users-collection lookup, performing the read only when the cached value is a placeholder.
- Name labels in `_ChatThreadCard` and `_ChatDetailContent` are wrapped in `FutureBuilder`, so the email fallback shows instantly while the real name loads.
- `broadcastMessageWithReport` now writes `resolveDisplayNameFromUserDoc(userData) ?? ''` instead of raw `userData['name']`, stopping the creation of new `"User"` values.
- The detail-screen send path reuses `resolveRealName` so replying to a placeholder thread repairs it.

## Files changed

- `lib/features/admin/services/admin_chat_service.dart`
- `lib/features/admin/screens/admin_chat_list_screen.dart`
- `lib/features/admin/screens/admin_chat_detail_screen.dart`
- `test/features/admin/admin_chat_route_fix_test.dart`

## Verification

- `flutter analyze` clean on the four changed files.
- `flutter test` passing for `admin_chat_route_fix_test.dart`, `admin_unread_badge_test.dart`, and `user_display_name_test.dart`.
- `flutter build web --base-href="/s4n4d-ac42/"` succeeds.

## See also

- [[sources/admin-chat-name-fix]] — the first pass, covering the detail screen and service write guard
- [[concepts/admin-chat-display-name]] — the resolution strategy this extends
- [[concepts/support-chat-thread]] — the thread model carrying the cached name
- [[entities/admin-chat-service]]
- [[entities/admin-chat-detail-screen]]
