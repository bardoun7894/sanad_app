---
name: MoodFeedScreen
description: "Admin dashboard screen showing a feed of mood alerts (all colors, filtered by polarity) with a \"Message\" button per entry."
type: entity
tags: [chat]
sources: [sources/admin-chat-name-fix]
created: "2026-06-25"
updated: "2026-06-25"
---
# MoodFeedScreen

## What it is

A real-time admin dashboard screen (`lib/features/admin/screens/mood_feed_screen.dart`) displaying all user mood entries — positive (green), negative (red), neutral (gray) — grouped by user, with color-coded emotion chips and a "Message" button per entry that navigates to the admin chat detail screen.

## Key facts

- Uses `allMoodFeedProvider` which already resolves user names via `resolveDisplayNameFromUserDoc()`
- `MoodAlert.userName` is the real display name (never `'User'`)
- **Bug:** The "Message" button originally navigated to `/admin/chat/detail/${entry.userId}` via `context.go()` without passing a `ChatThread` in `state.extra`
- **Fix:** Now constructs a `ChatThread` with `entry.userName` (real name) and passes it as `extra`

## See also

- [[entities/admin-chat-detail-screen]]
- [[concepts/admin-chat-display-name]]
- [[sources/admin-chat-name-fix]]
