# Crisis Detection & Emergency System - Implementation Doc

**Date**: 2026-02-28
**Milestone**: 1 of 3 (NEXT-FEATURES-PLAN)
**Status**: Complete
**Priority**: CRITICAL

## Overview

The Crisis Detection & Emergency System prevents the AI assistant (Sanad) from validating dangerous thoughts by detecting crisis-related messages across Arabic, English, and French, and triggering appropriate interventions.

## Architecture

### Two-Tier Detection System

**Tier 1 (Critical/Immediate)**

- Explicit self-harm keywords in AR/EN/FR
- Bypasses AI confirmation
- Instantly: blocks chat + shows CrisisResponseScreen + writes `/risk_alerts` doc + sends FCM to admins + sets `crisis_mode` on user
- Keywords: suicide, kill myself, self-harm, overdose, etc. (~50 keywords across 3 languages)

**Tier 2 (High/Needs Confirmation)**

- Ambiguous distress indicators (hopelessness, despair, wanting to disappear)
- Message sent normally to AI
- Background Gemini call confirms crisis context using structured JSON prompt
- If confirmed: writes alert with severity `high` to `/risk_alerts`
- Keywords: hopeless, no point in living, can't take it anymore, etc. (~40 keywords across 3 languages)

### Detection Flow

```
User sends message
  -> CrisisKeywords.analyze(message)
    -> Tier 1 match? -> BLOCK chat + CrisisResponseScreen + alert + FCM + crisis_mode
    -> Tier 2 match? -> Send normally + background AI confirmation
    -> No match -> Send normally
```

## Firestore Schema

### New Collection: `/risk_alerts/{alertId}`

| Field                   | Type       | Description                                               |
| ----------------------- | ---------- | --------------------------------------------------------- |
| user_id                 | string     | User who triggered the alert                              |
| user_name               | string     | Denormalized user name                                    |
| alert_type              | string     | crisisKeyword, moodTrend, aiFlagged, communityPost        |
| source                  | string     | aiChat, community, moodLog                                |
| severity                | string     | critical, high, moderate                                  |
| status                  | string     | newAlert, acknowledged, assigned, resolved, falsePositive |
| triggered_text          | string     | The message that triggered detection                      |
| matched_keywords        | string[]   | Keywords that matched                                     |
| ai_confirmed            | bool       | Whether AI confirmed crisis context                       |
| language                | string     | ar, en, fr                                                |
| assigned_therapist_id   | string?    | Therapist assigned to handle                              |
| assigned_therapist_name | string?    | Therapist name                                            |
| acknowledged_by         | string?    | Admin who acknowledged                                    |
| acknowledged_at         | timestamp? | When acknowledged                                         |
| resolved_by             | string?    | Who resolved                                              |
| resolved_at             | timestamp? | When resolved                                             |
| resolution_notes        | string?    | Resolution notes                                          |
| created_at              | timestamp  | Alert creation time                                       |
| updated_at              | timestamp  | Last update time                                          |

### Updated: `/users/{userId}`

Added fields:

- `crisis_mode` (bool) - Whether user is in crisis mode
- `crisis_mode_set_at` (timestamp) - When crisis mode was set
- `crisis_mode_set_by` (string) - Who set it (system/admin)

### Firestore Rules

```
match /risk_alerts/{alertId} {
  allow read: if isAdmin() || isTherapist();
  allow create: if isAuthenticated();
  allow update: if isAdmin();
  allow delete: if isAdmin();
}
```

## New Files Created (17)

### Models (3)

- `lib/features/crisis/models/crisis_alert.dart` - CrisisAlert model + enums
- `lib/features/crisis/models/emergency_contact.dart` - Regional hotline data
- `lib/features/crisis/models/crisis_keywords.dart` - Keyword dictionaries + analyze()

### Services (2)

- `lib/features/crisis/services/crisis_detection_service.dart` - Detection + CRUD + crisis mode
- `lib/features/crisis/services/crisis_notification_service.dart` - Admin/therapist notifications

### Providers (2)

- `lib/features/crisis/providers/crisis_detection_provider.dart` - Service provider + crisis mode stream
- `lib/features/crisis/providers/crisis_alerts_provider.dart` - Alert streams + action handler

### Screens (2)

- `lib/features/crisis/screens/crisis_response_screen.dart` - Safety plan + hotlines
- `lib/features/admin/screens/crisis_alerts_screen.dart` - Admin alert management

### Widgets (4)

- `lib/features/crisis/widgets/crisis_banner.dart` - Chat warning banner
- `lib/features/crisis/widgets/crisis_alert_card.dart` - Alert list item (pulsing for critical)
- `lib/features/crisis/widgets/crisis_alert_action_sheet.dart` - Admin actions bottom sheet
- `lib/features/admin/widgets/dashboard/crisis_alerts_panel.dart` - Dashboard panel

### Tests (2)

- `test/features/crisis/crisis_detection_service_test.dart` - Keyword detection tests
- `test/features/crisis/crisis_alert_model_test.dart` - Model serialization tests

## Existing Files Modified (14)

| File                          | Changes                                                                                       |
| ----------------------------- | --------------------------------------------------------------------------------------------- |
| `chat_provider.dart`          | Two-tier detection in sendMessage(), \_handleCriticalCrisis(), \_handleHighCrisisBackground() |
| `message.dart`                | Added crisisSeverity, crisisKeywordsMatched to MessageMetadata; isCrisisMode to ChatState     |
| `gemini_service.dart`         | Added buildCrisisAssessmentPrompt()                                                           |
| `user_profile.dart`           | Added crisisMode, crisisModeSetAt, crisisModeSetBy fields                                     |
| `profile_service.dart`        | Read/write crisis mode fields in Firestore conversion                                         |
| `app_notification.dart`       | Added crisis to NotificationType enum                                                         |
| `fcm_service.dart`            | Added crisis notification type + navigation handling                                          |
| `chat_screen.dart`            | Shows CrisisBanner, disables input in crisis mode                                             |
| `admin_dashboard_screen.dart` | Added CrisisAlertsPanel                                                                       |
| `app_router.dart`             | Added /crisis-response, /admin/crisis-alerts routes                                           |
| `app_routes.dart`             | Added crisisResponse, adminCrisisAlerts constants                                             |
| `firestore.rules`             | Added /risk_alerts collection rules                                                           |
| `app_strings*.dart` (4 files) | ~26 new crisis strings across AR/EN/FR                                                        |
| `language_provider.dart`      | Added crisis string getters to S class                                                        |

## Emergency Contacts

Regional hotlines configured:

- **Morocco**: SOS Psychiatrie (0522-293-030), SAMU (141)
- **Saudi Arabia**: Mental Health Hotline (920033360), Emergency (911)
- **UAE**: Hope Line (800-4673), Emergency (999)
- **International**: Crisis Text Line (741741), Emergency (112)

## Crisis Keyword Languages

| Language | Tier 1 (Critical) | Tier 2 (High) |
| -------- | ----------------- | ------------- |
| Arabic   | 21 keywords       | 16 keywords   |
| English  | 19 keywords       | 16 keywords   |
| French   | 14 keywords       | 13 keywords   |

## Admin Workflow

1. Alert appears in CrisisAlertsPanel on dashboard (pulsing red for critical)
2. Admin clicks -> CrisisAlertActionSheet opens
3. Actions: Acknowledge -> Assign Therapist -> Resolve / False Positive
4. Each action updates `/risk_alerts/{alertId}` status
5. Assigning a therapist sends FCM notification to them

## Integration Points

- **ChatProvider**: Entry point for all crisis detection in AI chat
- **GeminiService**: Provides AI confirmation prompts for Tier 2
- **FCMService**: Routes crisis notifications to admin/therapist screens
- **ProfileService**: Reads/writes crisis_mode flag
- **Admin Dashboard**: CrisisAlertsPanel shows real-time active alerts
