---
name: Therapist Chat ID Convention
description: Patient–therapist chat documents are keyed by the composite `{therapistId}_{userId}`, derived rather than stored
type: concept
tags: [firebase, chat, collection]
sources: [sources/therapist-assignment-review]
created: "2026-07-29"
updated: "2026-07-29"
---
# Therapist Chat ID Convention

## Overview

Patient–therapist chat threads are keyed by a composite identifier built from both participants: `generateChatId(therapistId, userId)` returns `'${therapistId}_$userId'`. The ID is derived on demand rather than stored and looked up, so any screen holding both participant IDs can address the thread without a query.

## Why it is derived, not looked up

Deriving the key means the admin assignment flow, the therapist's patient list, and the chat screen itself all reach the same document without coordinating. The cost is that the convention is duplicated at every call site — `replaceChat()`, `getOrCreateChat()`, and `therapist_assigned_patients_screen.dart` each construct it — so a divergence in any one of them would silently create a second, empty thread rather than raise an error. A 2026-05-02 review verified all three agree.

## Ordering matters

The therapist ID comes first. Because the two IDs are concatenated with a single underscore and Firebase UIDs may themselves contain characters that appear in the separator position, code that splits a chat ID back into its parts must take the first segment as the therapist and rejoin the remainder as the user, not split on every underscore.

## Relationship to the therapist document ID

The key uses whatever ID the rest of the system treats as the therapist's identity. That identity is not always the therapist's Firebase Auth UID — admin-created therapist documents get a generated Firestore ID until they are linked to an auth account — so a thread key can be built from an ID that no signed-in user will ever match.

## Distinction from support chat

This is a different scheme from the admin support inbox, where threads are keyed by user alone at `support_chats/{userId}` because the counterparty is always "admin".

## See also

- [[concepts/support-chat-thread]] — the single-participant keying used for support threads
- [[sources/therapist-assignment-review]] — the review that verified consistency across call sites
