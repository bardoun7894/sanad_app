# Hybrid Human + AI Therapy Model - Implementation Doc

**Date**: 2026-02-28
**Milestone**: 2 of 3 (NEXT-FEATURES-PLAN)
**Status**: Complete
**Depends on**: Milestone 1 (Crisis Detection)

## Overview

The Hybrid Therapy system enables seamless AI-to-therapist transitions within the chat, providing users continuous care by detecting when professional intervention is needed and smoothly handing off the conversation with full context.

## Architecture

### 4 Handoff Triggers (evaluated after each AI response)

1. **Crisis** (highest priority): Checks `/risk_alerts` for active alerts for the user (M1 integration)
2. **User Request**: `GeminiService.shouldSuggestEscalation()` + explicit phrases in AR/EN/FR ("I want a real therapist")
3. **Mood Pattern**: `consecutiveLowDays >= 3` OR `riskLevel in [high, critical]` OR declining trend with avg < 2.5
4. **Low AI Confidence**: Fallback model used, or very short AI responses (< 50 chars)

### Handoff Flow

```
AI responds to user
  -> HandoffTriggerService.evaluate()
    -> Trigger found? -> Show RequestTherapistButton
      -> User accepts -> HandoffService.initiateHandoff()
        -> Creates /chat_handoffs doc with mood snapshot + AI summary
        -> Status: pending -> Admin/system assigns therapist
        -> Therapist accepts -> HandoffTransition overlay
        -> HybridChatScreen switches to therapist mode
```

## Firestore Schema

### New Collection: `/chat_handoffs/{handoffId}`

| Field                                             | Type       | Description                                                  |
| ------------------------------------------------- | ---------- | ------------------------------------------------------------ |
| user_id                                           | string     | User requesting handoff                                      |
| user_name                                         | string     | Denormalized user name                                       |
| from_mode                                         | string     | 'ai' or 'therapist'                                          |
| to_mode                                           | string     | 'therapist' or 'ai'                                          |
| therapist_id                                      | string?    | Assigned therapist                                           |
| therapist_name                                    | string?    | Therapist name                                               |
| trigger_reason                                    | string     | crisis, userRequest, moodPattern, aiLowConfidence            |
| trigger_details                                   | string?    | Additional context                                           |
| ai_summary                                        | string     | Last 10 AI messages summarized                               |
| mood_snapshot                                     | map        | {dates, moods, average_score, trend, consecutive_low_days}   |
| chat_history_ref                                  | string?    | Reference to AI chat                                         |
| risk_level                                        | string?    | From UserContextService                                      |
| therapist_chat_id                                 | string?    | Linked therapist chat                                        |
| risk_alert_id                                     | string?    | Linked crisis alert                                          |
| status                                            | string     | pending, accepted, inProgress, completed, expired, cancelled |
| created_at, accepted_at, completed_at, expires_at | timestamps | Lifecycle timestamps                                         |

### Updated: `/therapist_chats/{chatId}`

Added fields:

- `handoff_id` (string?) - Linked handoff document
- `mood_context` (map?) - Mood snapshot from handoff

## New Files Created (18)

### Models (2)

- `lib/features/chat/models/chat_handoff.dart` - ChatHandoff + HandoffTrigger/Status + MoodSnapshot
- `lib/features/chat/models/hybrid_message.dart` - Unified message wrapper for AI + therapist

### Repository (1)

- `lib/features/chat/repositories/chat_handoff_repository.dart` - CRUD, streams, active handoff lookup

### Services (2)

- `lib/features/chat/services/handoff_service.dart` - Orchestrator: initiate, accept, complete, build mood snapshot
- `lib/features/chat/services/handoff_trigger_service.dart` - Evaluate 4 triggers after AI responses

### Providers (2)

- `lib/features/chat/providers/handoff_provider.dart` - HandoffNotifier + stream providers
- `lib/features/chat/providers/hybrid_chat_provider.dart` - HybridChatNotifier managing mode switching

### Screens (1)

- `lib/features/chat/screens/hybrid_chat_screen.dart` - Unified chat with mode switching

### Widgets (7)

- `lib/features/chat/widgets/chat_mode_indicator.dart` - AI/Therapist mode banner
- `lib/features/chat/widgets/request_therapist_button.dart` - Floating suggestion pill
- `lib/features/chat/widgets/handoff_transition.dart` - Full-screen transition overlay
- `lib/features/chat/widgets/handoff_system_message.dart` - System bubble for handoff events
- `lib/features/therapist_chat/widgets/ai_summary_card.dart` - Expandable AI context card
- `lib/features/therapist_chat/widgets/mood_context_chart.dart` - 7-day fl_chart mood trend
- `lib/features/admin/widgets/handoff_queue_widget.dart` - Admin pending handoffs widget

## Existing Files Modified

| File                          | Changes                                      |
| ----------------------------- | -------------------------------------------- |
| `therapist_chat.dart`         | Added handoffId, moodContext fields          |
| `message.dart`                | Added handoff to MessageType enum            |
| `fcm_service.dart`            | Added handoff notification type + navigation |
| `admin_dashboard_screen.dart` | Added HandoffQueueWidget                     |
| `app_router.dart`             | Added /chat/hybrid route                     |
| `app_routes.dart`             | Added hybridChat constant                    |
| `firestore.rules`             | Added /chat_handoffs collection rules        |

## Key Reused Infrastructure

- `TherapistChatThread.aiContext` field (already existed)
- `ChatSource.aiEscalation` enum value (already existed)
- `AiChatService.getConversationSummary()` (already existed)
- `UserContextService.buildContext()` for mood/risk data
- `fl_chart` for mood trend visualization
- Existing FCM notification pipeline
