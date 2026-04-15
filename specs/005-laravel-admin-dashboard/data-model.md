# Data Model: Laravel Admin Dashboard Conversion

**Branch**: `005-laravel-admin-dashboard` | **Date**: 2026-02-05 | **Spec**: [spec.md](./spec.md)
**Source**: Extracted from Flutter Dart models, Riverpod providers, services, and Firestore rules

## Overview

The Laravel admin dashboard reads from and writes to the **same Firestore database** used by the Flutter mobile app. No data migration is needed. The `FirestoreModel` base class in PHP maps 1:1 to these Firestore collections.

**Total collections used by admin**: 17 primary collections + 6 subcollections

---

## Entity Definitions

### E1: User

**Firestore Collection**: `users`
**Document ID**: Firebase Auth UID
**Admin Operations**: List, View (tabbed), Edit (role/status/subscription), Search
**Filament Resource**: `UserResource`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `email` | string | yes | — | Firebase Auth email |
| `display_name` | string | no | — | Also fallback: `name`, `full_name` |
| `name` | string | no | — | Alternative name field |
| `role` | string | yes | `'user'` | Enum: `user`, `therapist`, `admin` |
| `is_premium` | bool | yes | `false` | Premium subscription active |
| `subscription_status` | string | yes | `'free'` | Enum: `free`, `active`, `cancelled`, `expired`, `pending` |
| `subscription_plan` | string | no | — | Product ID (e.g., `'premium'`) |
| `subscription_expiry_date` | timestamp | no | — | When subscription expires |
| `subscription_product_title` | string | no | — | Human-readable plan name |
| `subscription_start_date` | timestamp | no | — | Subscription activation date |
| `subscription_assigned_by` | string | no | — | `'admin'` if admin-granted |
| `subscription_assigned_at` | timestamp | no | — | When admin granted subscription |
| `subscription_revoked_at` | timestamp | no | — | When admin revoked subscription |
| `subscription_revoked_by` | string | no | — | Admin UID who revoked |
| `payment_gateway` | string | no | — | `admin_grant`, `bank_transfer`, `paypal` |
| `auto_renew` | bool | no | — | Auto-renewal flag |
| `premium_updated_at` | timestamp | no | — | Last premium status change |
| `phone_number` | string | no | — | Also `phone` in some access |
| `date_of_birth` | timestamp | no | — | |
| `last_login` | timestamp | no | — | Used for active user counting |
| `therapist_status` | string | no | — | `'approved'`; removed when demoted |
| `created_at` | timestamp | yes | — | Account creation time |
| `updated_at` | timestamp | no | — | Server timestamp on updates |

**Subcollections**:
- `users/{userId}/mood_entries` — See [E11: MoodEntry](#e11-moodentry)
- `users/{userId}/engagement/{docId}` — Read-only for analytics
- `users/{userId}/bookmarks/{bookmarkId}` — Not used by admin
- `users/{userId}/challenge_completions/{completionId}` — Not used by admin

**State Transitions (subscription_status)**:
```
free → active (admin assigns subscription)
active → cancelled (admin revokes)
active → expired (auto-expiry)
expired → active (admin re-assigns)
pending → active (payment verified)
```

**State Transitions (role)**:
```
user → therapist (admin promotes + creates therapist profile)
therapist → user (admin demotes + deletes therapist_status)
user → admin (manual)
```

**Relationships**:
- Referenced by: `bookings.client_id`, `payments.user_id`, `payment_verifications.user_id`, `notifications.user_id`, `support_chats` (doc ID), `activity_logs.user_id`, `reviews.user_id`, `posts.author_id`

---

### E2: Therapist

**Firestore Collection**: `therapists` (primary) + `therapist_profiles` (aggregated ratings/reviews — read-only by admin)
**Document ID**: Firebase Auth UID (same as `users` doc ID)
**Admin Operations**: List (tabbed: Pending/Approved/Rejected), View, Approve, Reject
**Filament Resource**: `TherapistResource`
**Note**: Flutter uses two collections — `therapists` for profile data (CRUD) and `therapist_profiles` for aggregated rating stats (read-only). Admin dashboard reads from both.

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `id` | string | yes | — | Same as doc ID / user UID |
| `email` | string | yes | — | |
| `name` | string | yes | — | |
| `title` | string | no | — | e.g., `'Mental Health Specialist'` |
| `bio` | string | no | — | |
| `photo_url` | string | no | — | |
| `specialties` | array\<string\> | yes | `[]` | Enum values from Specialty |
| `session_types` | array\<string\> | yes | `[]` | Enum values from SessionType |
| `therapy_types` | array\<string\> | yes | `[]` | Enum values from TherapyType |
| `languages` | array\<string\> | yes | `[]` | e.g., `['Arabic', 'English']` |
| `qualifications` | array\<string\> | yes | `[]` | |
| `session_price` | number | yes | `150.0` | In currency units |
| `currency` | string | yes | `'SAR'` | |
| `years_experience` | int | yes | `0` | |
| `approval_status` | string | yes | `'pending'` | Enum: `pending`, `approved`, `rejected`, `suspended` |
| `is_active` | bool | yes | `true` | |
| `rating` | number | yes | `5.0` | Average from reviews |
| `review_count` | int | yes | `0` | |
| `created_at` | timestamp | yes | — | |
| `approved_at` | timestamp | no | — | Set on approval |
| `approved_by` | string | no | — | Admin UID |
| `rejection_reason` | string | no | — | Set on rejection |
| `license_document_url` | string | no | — | Uploaded document |
| `phone_number` | string | no | — | |
| `updated_at` | timestamp | no | — | |
| `status` | string | no | `'active'` | Set on creation |

**Enums**:
- `Specialty`: `anxiety`, `depression`, `trauma`, `relationships`, `stress`, `selfEsteem`, `grief`, `addiction`
- `SessionType`: `video`, `audio`, `chat`, `inPerson`
- `TherapyType`: `individual`, `couples`, `teen`
- `TherapistApprovalStatus`: `pending`, `approved`, `rejected`, `suspended`

**State Transitions (approval_status)**:
```
pending → approved (admin approves, sets approved_at, approved_by)
pending → rejected (admin rejects, sets rejection_reason)
approved → suspended (admin suspends)
rejected → pending (therapist re-applies — future)
```

**Relationships**:
- Doc ID = `users/{userId}` (1:1 with user)
- Referenced by: `bookings.therapist_id`, `reviews.therapist_id`, `therapist_chats.therapist_id`

---

### E3: Booking

**Firestore Collection**: `bookings`
**Document ID**: Auto-generated
**Admin Operations**: List (tabbed: All/Upcoming/Completed/Cancelled), View, Cancel with reason
**Filament Resource**: `BookingResource`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `therapist_id` | string | yes | — | FK to `therapists` |
| `client_id` | string | yes | — | FK to `users` |
| `client_name` | string | yes | — | Denormalized |
| `client_email` | string | no | — | Denormalized |
| `client_photo_url` | string | no | — | Denormalized |
| `client_age` | int | no | — | |
| `primary_complaint` | string | no | — | |
| `scheduled_time` | timestamp | yes | — | Session date/time |
| `duration_minutes` | int | yes | `60` | |
| `session_type` | string | yes | — | Enum: `video`, `audio`, `chat` |
| `status` | string | yes | `'pending'` | Enum: `pending`, `confirmed`, `rejected`, `completed`, `cancelled`, `no_show` |
| `amount` | number | yes | — | Session cost |
| `currency` | string | yes | `'SAR'` | |
| `notes` | string | no | — | Public/system notes |
| `private_notes` | string | no | — | Therapist-only (not shown in admin) |
| `cancellation_reason` | string | no | — | Set on cancel |
| `rejection_reason` | string | no | — | Set on reject |
| `created_at` | timestamp | yes | — | |
| `confirmed_at` | timestamp | no | — | |
| `completed_at` | timestamp | no | — | |
| `cancelled_at` | timestamp | no | — | |
| `updated_at` | timestamp | no | — | Set on admin cancel |

**Enums**:
- `BookingStatus`: `pending`, `confirmed`, `rejected`, `completed`, `cancelled`, `no_show`

**State Transitions (status)**:
```
pending → confirmed (therapist confirms)
pending → rejected (therapist rejects)
pending → cancelled (admin/user cancels, sets cancellation_reason)
confirmed → completed (session completed)
confirmed → cancelled (admin/user cancels)
confirmed → no_show (patient didn't attend)
```

**Relationships**:
- `therapist_id` -> `therapists/{id}`
- `client_id` -> `users/{id}`
- Referenced by: `reviews.booking_id`, `therapist_chats.booking_ids`

---

### E4: PaymentTransaction

**Firestore Collection**: `payments`
**Document ID**: Auto-generated
**Admin Operations**: List (tabbed: All/Completed/Pending/Failed), View, Stats
**Filament Resource**: `PaymentResource`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `user_id` | string | yes | — | FK to `users` |
| `user_email` | string | no | — | Denormalized |
| `amount` | number | yes | — | |
| `currency` | string | yes | `'SAR'` | |
| `status` | string | yes | `'pending'` | Enum: `pending`, `completed`, `failed`, `refunded` |
| `payment_method` | string | yes | — | Enum: `card`, `bank_transfer`, `paypal`, `admin_grant` |
| `reference_code` | string | no | — | |
| `gateway_transaction_id` | string | no | — | External gateway ID |
| `created_at` | timestamp | yes | — | |
| `updated_at` | timestamp | no | — | |
| `product_id` | string | no | — | Subscription product ID |
| `product_title` | string | no | — | Denormalized plan name |
| `start_date` | timestamp | no | — | Subscription start |
| `end_date` | timestamp | no | — | Subscription end |
| `notes` | string | no | — | e.g., `'Subscription granted by admin'` |

**Enums**:
- `PaymentStatus`: `pending`, `completed`, `failed`, `refunded`
- `PaymentMethod`: `card`, `bank_transfer`, `paypal`, `admin_grant`

**Relationships**:
- `user_id` -> `users/{id}`

---

### E5: PaymentVerification

**Firestore Collection**: `payment_verifications`
**Document ID**: Auto-generated
**Admin Operations**: List, View receipt, Approve (activates subscription), Reject with reason
**Filament Resource**: `PaymentVerificationResource` (or custom Page)

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `user_id` | string | yes | — | FK to `users` |
| `user_name` | string | yes | — | Denormalized |
| `user_email` | string | yes | — | Denormalized |
| `product_id` | string | yes | — | Subscription product |
| `product_title` | string | yes | — | |
| `amount` | number | yes | — | |
| `currency` | string | yes | `'USD'` | |
| `reference_code` | string | yes | — | Bank transfer reference |
| `receipt_url` | string | no | — | Firebase Storage URL |
| `status` | string | yes | `'pending'` | Enum: `pending`, `approved`, `rejected` |
| `created_at` | timestamp | yes | — | |
| `reviewed_at` | timestamp | no | — | Set on approve/reject |
| `reviewed_by` | string | no | — | Admin UID |
| `rejection_reason` | string | no | — | Set on reject |

**Enums**:
- `VerificationStatus`: `pending`, `approved`, `rejected`

**State Transitions (status)**:
```
pending → approved (admin approves → user subscription activated)
pending → rejected (admin rejects → rejection_reason recorded)
```

**Side Effects on Approve**:
1. Set `status` = `'approved'`, `reviewed_at`, `reviewed_by`
2. Update `users/{user_id}`: `is_premium` = true, `subscription_status` = `'active'`, set expiry date
3. Create `payments` record with `payment_method` = `'bank_transfer'`
4. Log to `activity_logs`

**Relationships**:
- `user_id` -> `users/{id}`
- `reviewed_by` -> `users/{id}` (admin)

---

### E6: ActivityLog

**Firestore Collection**: `activity_logs`
**Document ID**: Auto-generated
**Admin Operations**: Read (dashboard Recent Activity widget, list 5 latest)
**Filament Widget**: `RecentActivityWidget`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `type` | string | yes | — | Enum: ActivityType name |
| `user_id` | string | yes | — | Actor (admin) user ID |
| `user_name` | string | yes | — | Actor display name |
| `description` | string | yes | — | Human-readable action description |
| `timestamp` | timestamp | yes | — | Server timestamp |
| `metadata` | map | no | — | Extra context data |

**Enums**:
- `ActivityType`: `sessionCompleted`, `bookingCreated`, `moodLogged`, `postCreated`, `userRegistered`, `therapistApproved`, `paymentVerified`

**Relationships**:
- `user_id` -> `users/{id}` (the actor)

---

### E7: ChatThread (Support Chat)

**Firestore Collection**: `support_chats`
**Document ID**: User's Firebase Auth UID
**Admin Operations**: List threads, View messages, Send reply, Start new chat, Broadcast
**Filament Page**: `ChatSupport`

#### Thread Document

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `user_email` | string | yes | — | |
| `user_name` | string | yes | — | |
| `user_id` | string | no | — | Used in analytics |
| `last_message` | string | yes | — | Preview text |
| `last_message_time` | timestamp | yes | — | Sort key |
| `unread_count_admin` | int | yes | `0` | Unread by admin |
| `unread_count_user` | int | yes | `0` | Unread by user |

#### Subcollection: `support_chats/{userId}/messages`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `sender_id` | string | yes | — | `'admin'` or user UID |
| `content` | string | yes | — | Message text |
| `timestamp` | timestamp | yes | — | Server timestamp |
| `is_read` | bool | yes | `false` | |
| `is_broadcast` | bool | no | — | `true` for broadcast messages |

**Relationships**:
- Doc ID = `users/{userId}` (1:1 with user)

---

### E8: Notification

**Firestore Collection**: `notifications`
**Document ID**: Auto-generated
**Admin Operations**: List in dropdown, Mark read, Mark all read, Navigate to action route
**Livewire Component**: `NotificationBell`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `user_id` | string | yes | — | Recipient user ID |
| `title` | string | yes | — | |
| `body` | string | yes | — | |
| `type` | string | yes | — | Enum: NotificationType name |
| `created_at` | timestamp | yes | — | |
| `is_read` | bool | yes | `false` | |
| `read_at` | timestamp | no | — | Set when marked read |
| `data` | map | no | — | Context payload |
| `action_route` | string | no | — | Deep link for navigation |

**Enums**:
- `NotificationType`: `booking`, `message`, `community`, `mood`, `system`, `therapist`, `payment`

**Relationships**:
- `user_id` -> `users/{id}`

---

### E9: SystemSetting

**Firestore Collection**: `system_settings`
**Document**: `system_settings/config` (single document)
**Admin Operations**: Read, Update toggles/fields
**Filament Page**: `Settings` (or Filament Settings Plugin)

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `maintenance_mode` | bool | yes | `false` | Toggle |
| `enable_therapist_application` | bool | yes | `true` | Toggle |
| `min_app_version` | string | yes | `'1.0.0'` | Editable text |
| `contact_email` | string | yes | `'support@sanad.sa'` | Editable text |

**Note**: Single document — no listing, no ID field. Always read/write `system_settings/config`.

---

### E10: CMS Content (3 types)

#### E10a: DailyQuote

**Firestore Collection**: `daily_quotes`
**Document ID**: Auto-generated
**Admin Operations**: Full CRUD
**Filament Resource**: `QuoteResource`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `text` | string | yes | — | Quote text |
| `author` | string | no | `''` | Attribution |
| `category` | string | yes | — | e.g., `'Anxiety'`, `'Depression'`, `'General'` |
| `publish_date` | timestamp | no | — | Scheduled publication |
| `is_active` | bool | yes | `true` | |

#### E10b: AppContent (Articles/Exercises/Videos)

**Firestore Collection**: `content`
**Document ID**: Auto-generated
**Admin Operations**: Full CRUD
**Filament Resource**: `ContentResource`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `title` | string | yes | — | |
| `category` | string | yes | — | e.g., `'Anxiety'`, `'Sleep'` |
| `type` | string | yes | — | Enum: `article`, `exercise`, `video` |
| `content_text` | string | no | — | For articles |
| `media_url` | string | no | — | For videos/images |
| `link_url` | string | no | — | External link |
| `is_published` | bool | yes | `false` | |
| `created_at` | timestamp | yes | — | |

**Enums**:
- `ContentType`: `article`, `exercise`, `video`

#### E10c: DailyChallenge

**Firestore Collection**: `daily_challenges`
**Document ID**: Auto-generated
**Admin Operations**: Full CRUD
**Filament Resource**: `ChallengeResource`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `title` | string | yes | — | Arabic |
| `title_en` | string | yes | — | English |
| `description` | string | yes | — | Arabic |
| `description_en` | string | yes | — | English |
| `type` | string | yes | — | Enum: ChallengeType name |
| `duration_minutes` | int | yes | `5` | |
| `order` | int | yes | — | Sort order |
| `publish_date` | timestamp | no | — | Scheduled date |
| `is_active` | bool | yes | `true` | |

**Enums**:
- `ChallengeType`: `breathing`, `gratitude`, `mindfulness`, `exercise`, `journaling`, `social`, `selfCare`, `general`

---

### E11: MoodEntry (Read-Only)

**Firestore Collection**: `users/{userId}/mood_entries` (subcollection, accessed via collectionGroup)
**Document ID**: Auto-generated
**Admin Operations**: Read-only via collectionGroup query for risk detection
**Filament Widget**: `RiskAlertsWidget`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `mood` | int | yes | — | Index into MoodType enum (0-5) |
| `date` | timestamp | yes | — | Entry date |
| `note` | string | no | — | Optional note |

**Enums**:
- `MoodType` (by index): `happy` (0), `calm` (1), `anxious` (2), `sad` (3), `angry` (4), `tired` (5)

**Risk Detection Algorithm** (from `risk_alerts_provider.dart`):
- Query last 7 days of mood_entries via collectionGroup
- Group by user (from document parent path)
- Calculate average mood score
- Risk levels: `critical` (avg >= 3.5), `high` (avg >= 2.5), `moderate` (avg >= 1.5), `low` (avg < 1.5)
- Higher mood index = more negative mood

---

### E12: Assessment (Read-Only)

**Firestore Collection**: `assessments`
**Document ID**: Auto-generated
**Admin Operations**: Read-only for dashboard stats (critical flags count) and user profile tabs
**Used by**: Dashboard KPI (`criticalFlags`), User detail Assessments tab

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `risk_level` | string | yes | — | Queried: `'high'`, `'critical'` |
| `user_id` | string | yes | — | FK to `users` |

**Note**: Minimal model — only `risk_level` and `user_id` are queried by admin. Full assessment fields exist but are read-only.

---

### E13: SubscriptionProduct (Read-Only)

**Firestore Collection**: `subscription_products`
**Document ID**: Auto-generated
**Admin Operations**: Read-only (used in subscription assignment dropdown)
**Used by**: User subscription management

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `title` | string | yes | — | Plan display name |
| `description` | string | yes | — | Plan description |
| `price` | number | yes | — | |
| `currency_code` | string | yes | `'SAR'` | |
| `billing_period` | string | yes | — | `weekly`, `monthly`, `hourly`, `pay_per_minute` |
| `billing_period_days` | int | yes | — | e.g., 7, 30 |
| `localized_price` | string | no | — | Formatted price |
| `is_featured` | bool | yes | `false` | |
| `features` | array\<string\> | yes | `[]` | Feature descriptions |

---

### E14: CommunityPost

**Firestore Collection**: `posts`
**Document ID**: Auto-generated
**Admin Operations**: List flagged posts, Moderate (approve/remove/warn)
**Filament Page**: `CommunityModeration`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `author_id` | string | yes | — | FK to `users` |
| `author_name` | string | yes | — | Denormalized |
| `author_avatar` | string | no | — | |
| `is_anonymous` | bool | yes | — | |
| `content` | string | yes | — | Post body |
| `category` | string | yes | — | Enum: PostCategory name |
| `created_at` | timestamp | yes | — | |
| `report_count` | int | yes | `0` | Flag counter |
| `reactions` | map | yes | `{}` | e.g., `{'heart': 5, 'hug': 2}` |
| `comments_count` | int | no | — | |
| `updated_at` | timestamp | no | — | |

**Enums**:
- `PostCategory`: `general`, `anxiety`, `depression`, `relationships`, `selfCare`, `motivation`
- `ReactionType`: `heart`, `support`, `hug`, `strength`, `relate`

**Subcollections**:
- `posts/{postId}/comments` — `{id, author: {id, name, avatar_url, is_anonymous}, content, created_at}`
- `posts/{postId}/user_reactions/{userId}` — Per-user reaction data

**Relationships**:
- `author_id` -> `users/{id}`

---

### E15: AdminAIChat

**Firestore Collection**: `admin_ai_chats`
**Document ID**: Admin's Firebase Auth UID
**Admin Operations**: Send prompts, Receive AI responses, View history
**Filament Widget**: `AiAssistantWidget` (or Livewire component)

#### Thread Document

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `admin_id` | string | yes | — | |
| `last_message` | string | yes | — | Truncated to 100 chars |
| `last_message_time` | timestamp | yes | — | |
| `updated_at` | timestamp | yes | — | |

#### Subcollection: `admin_ai_chats/{adminId}/messages`

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `role` | string | yes | — | `'user'` or `'assistant'` |
| `content` | string | yes | — | Message text |
| `timestamp` | timestamp | yes | — | Server timestamp |

---

### E16: Review (Read-Only)

**Firestore Collection**: `reviews`
**Document ID**: Auto-generated
**Admin Operations**: Read-only (analytics, therapist detail)
**Used by**: Analytics (therapist ratings), Therapist detail page

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `therapist_id` | string | yes | — | FK to `therapists` |
| `user_id` | string | yes | — | FK to `users` |
| `booking_id` | string | yes | — | FK to `bookings` |
| `rating` | number | yes | — | 1.0 to 5.0 |
| `comment` | string | no | — | |
| `created_at` | timestamp | yes | — | Server timestamp |
| `updated_at` | timestamp | no | — | |

**Relationships**:
- `therapist_id` -> `therapists/{id}`
- `user_id` -> `users/{id}`
- `booking_id` -> `bookings/{id}`

---

## Entity Relationship Diagram

```
                    ┌──────────────────┐
                    │   users (E1)     │
                    │   PK: uid        │
                    └──────┬───────────┘
                           │
        ┌──────────────────┼──────────────────────────┐
        │                  │                           │
        │ 1:1              │ 1:N                       │ 1:N
        ▼                  ▼                           ▼
┌───────────────┐  ┌───────────────┐          ┌──────────────────┐
│ therapists(E2)│  │ bookings (E3) │          │  payments (E4)   │
│ PK: uid       │  │ FK: client_id │          │  FK: user_id     │
│               │  │ FK: therapist │          └──────────────────┘
└───────┬───────┘  └───────────────┘
        │                  │                   ┌──────────────────────┐
        │ 1:N              │ 1:N               │ payment_verifications│
        ▼                  ▼                   │ (E5)                 │
┌───────────────┐  ┌───────────────┐          │ FK: user_id          │
│ reviews (E16) │  │ reviews (E16) │          │ FK: reviewed_by      │
│ FK: therapist │  │ FK: booking_id│          └──────────────────────┘
└───────────────┘  └───────────────┘

users 1:N ──→ mood_entries (E11, subcollection)
users 1:N ──→ notifications (E8)
users 1:1 ──→ support_chats (E7, doc ID = user UID)
users 1:N ──→ posts (E14, via author_id)
users 1:N ──→ activity_logs (E6, via user_id)
admin  1:1 ──→ admin_ai_chats (E15, doc ID = admin UID)
```

---

## Firestore Indexes Required

The following composite indexes will be needed for admin queries:

| Collection | Fields | Order | Purpose |
|-----------|--------|-------|---------|
| `bookings` | `status`, `scheduled_time` | ASC | Status-filtered booking list |
| `bookings` | `session_type`, `scheduled_time` | ASC | Session type filter |
| `bookings` | `scheduled_time` | DESC | Default booking list sort |
| `payments` | `status`, `created_at` | DESC | Status-filtered payment list |
| `payment_verifications` | `status`, `created_at` | DESC | Pending verifications first |
| `notifications` | `user_id`, `is_read`, `created_at` | DESC | Unread notifications for admin |
| `activity_logs` | `timestamp` | DESC | Recent activity feed |
| `mood_entries` (collectionGroup) | `date` | DESC | Risk detection (last 7 days) |
| `assessments` | `risk_level` | — | Critical flag counting |
| `posts` | `report_count`, `created_at` | DESC | Flagged posts for moderation |
| `support_chats` | `last_message_time` | DESC | Chat list sorted by recency |
| `users` | `role`, `created_at` | DESC | Role-filtered user list |
| `therapists` | `approval_status`, `created_at` | DESC | Status-tabbed therapist list |

---

## Validation Rules (PHP/Laravel)

### User Subscription Assignment
```
product_id: required|string|exists_in:subscription_products
duration: required|in:7,30,90,365
```

### Therapist Approval
```
approval_status: required|in:approved,rejected
rejection_reason: required_if:approval_status,rejected|string|max:500
```

### Booking Cancellation
```
cancellation_reason: required|string|max:500
```

### Payment Verification
```
status: required|in:approved,rejected
rejection_reason: required_if:status,rejected|string|max:500
```

### System Settings
```
maintenance_mode: required|boolean
enable_therapist_application: required|boolean
min_app_version: required|string|regex:/^\d+\.\d+\.\d+$/
contact_email: required|email
```

### CMS - DailyQuote
```
text: required|string|max:500
author: nullable|string|max:100
category: required|string
is_active: required|boolean
```

### CMS - AppContent
```
title: required|string|max:200
category: required|string
type: required|in:article,exercise,video
content_text: required_if:type,article|string
media_url: required_if:type,video|url
is_published: required|boolean
```

### CMS - DailyChallenge
```
title: required|string|max:200
title_en: required|string|max:200
description: required|string|max:1000
description_en: required|string|max:1000
type: required|in:breathing,gratitude,mindfulness,exercise,journaling,social,selfCare,general
duration_minutes: required|integer|min:1|max:120
order: required|integer|min:0
is_active: required|boolean
```

### Chat Message
```
content: required|string|max:2000
```

### Activity Log (auto-generated)
```
type: required|in:sessionCompleted,bookingCreated,moodLogged,postCreated,userRegistered,therapistApproved,paymentVerified
user_id: required|string
user_name: required|string
description: required|string
```
