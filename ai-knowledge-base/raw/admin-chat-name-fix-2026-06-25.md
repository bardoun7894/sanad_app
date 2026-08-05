# Fix: Admin Chat Shows "Unknown" Instead of User Name

## Root Cause Analysis

Messages sent from the admin dashboard's **emotions tab (تبويب المشاعر)** arrived in the chat screen without the client's name, showing "Unknown" instead. This was a multi-layered bug propagating through 6 files.

### Chain of Failure

1. **`mood_feed_screen.dart`** — The "Message" button navigated to `/admin/chat/detail/${entry.userId}` **without passing a `ChatThread`** via GoRouter's `state.extra`. The `MoodAlert` model already had `userName` (resolved via `resolveDisplayNameFromUserDoc`), but it was never passed along.

2. **`admin_chat_detail_screen.dart`** — Receives `ChatThread?` via `state.extra`. Since mood feed didn't pass one, the screen had no initial name context.

3. **`user_support_chat_service.dart` `getOrCreateThread` (line ~27)** — When creating a new support thread, it saved `'user_name': userName ?? 'User'`. The `'User'` placeholder was the fallback when no name was provided.

4. **`user_display_name.dart` `resolveDisplayName`** — Explicitly filters out `'User'` (case-insensitive), returning `null` → UI shows "Unknown".

5. **`admin_chat_service.dart` `sendAdminMessage`** — Writes `userName` (which was `'User'` from the thread doc) back into the thread's Firestore doc, cementing the bad name.

6. **`user_support_chat_service.dart` `sendUserMessage`** — Updated `user_email` on every user message but **never updated `user_name`**, so the placeholder never self-corrected.

## Fixes Applied

Six files were modified across the layers:

### A. Mood Feed → Chat Navigation (mood_feed_screen.dart)
- Imported `ChatThread` model
- Before navigating, constructs a `ChatThread` with `entry.userName` (already resolved to real name by the provider) and passes it via `extra` parameter

### B. Admin Chat Detail — Name Resolution (admin_chat_detail_screen.dart)
- Added `_resolveRealName()` method that reads `users/{userId}` Firestore doc and resolves the display name via `resolveDisplayNameFromUserDoc`
- Before sending, if `thread.userName` is empty or equals `'User'` (case-insensitive), fetches the real name
- Display name logic also skips `'User'` and falls back to email
- Results cached in `_resolvedNames` map per session

### C. Admin Chat Service — No Placeholder Writes (admin_chat_service.dart)
- `sendAdminMessage` now only writes `user_name` to Firestore if it's a real (non-empty, non-'User') name

### D. User Support Chat Service — Proper Name Handling (user_support_chat_service.dart)
- `getOrCreateThread`: saves empty string `''` instead of `'User'` as fallback name
- `sendUserMessage`: accepts optional `userName` parameter, and updates `user_name` in the thread doc — BUT only if it's a real name (guarded)

### E. Provider — Thread userName Through (user_support_chat_provider.dart)
- `SupportChatParams` now includes optional `userName` field
- `SupportChatNotifier` accepts and passes `userName` to `getOrCreateThread` and `sendUserMessage`
- `initializeFromEscalation` also passes `userName`

### F. User Chat Screen — Pass displayName (user_support_chat_screen.dart)
- When creating `SupportChatParams`, passes `user.displayName` from Firebase Auth user

## Key Principle

The fundamental fix: **never write `'User'` as a user name to Firestore**. Only write real, resolved display names. When the current name is a placeholder, resolve it from the `users/{userId}` document at the point of use rather than at write time.

## Files Modified
- `lib/features/admin/screens/mood_feed_screen.dart`
- `lib/features/admin/screens/admin_chat_detail_screen.dart`
- `lib/features/admin/services/admin_chat_service.dart`
- `lib/features/chat/services/user_support_chat_service.dart`
- `lib/features/chat/providers/user_support_chat_provider.dart`
- `lib/features/chat/screens/user_support_chat_screen.dart`
