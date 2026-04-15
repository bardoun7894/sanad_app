# Sanad Data Contract

> **Version**: 1.0.0  
> **Last Updated**: 2026-02-26  
> **Scope**: Canonical field names, types, and enums shared between Flutter, Laravel Admin, and Cloud Functions.

## Conventions

| Rule | Detail |
|------|--------|
| **Field names** | `snake_case` everywhere (Firestore, Flutter Firestore maps, Laravel) |
| **Dart model properties** | `camelCase` (Dart convention), mapped to `snake_case` in `fromFirestore`/`toFirestore` |
| **Timestamps** | Firestore native `Timestamp` type. Flutter: `Timestamp.fromDate()` / `FieldValue.serverTimestamp()`. Laravel: pass `\DateTimeInterface` (use `FirestoreService::now()` or `FirestoreService::timestamp()`). **Never** `now()->toDateTimeString()`. |
| **Enums** | `snake_case` string values stored in Firestore (e.g. `in_person`, `no_show`) |
| **Booleans** | Firestore native `boolean` type, never string `"true"/"false"` |
| **IDs** | Firebase Auth UID for users/therapists; auto-generated for other documents |

---

## Collections

### `users`

Primary user document. Document ID = Firebase Auth UID.

| Field | Type | Required | Description | Enum Values |
|-------|------|----------|-------------|-------------|
| `email` | `string` | yes | User email from Firebase Auth | — |
| `name` | `string` | yes | Short name set at registration | — |
| `display_name` | `string` | no | Full display name set during profile completion | — |
| `phone` | `string` | no | Phone number (E.164 format preferred) | — |
| `avatar_url` | `string` | no | Profile photo URL | — |
| `date_of_birth` | `timestamp` | no | Date of birth | — |
| `gender` | `string` | no | User gender | `male`, `female`, `other`, `prefer_not_to_say` |
| `role` | `string` | yes | User role | `user`, `therapist`, `admin` |
| `is_premium` | `boolean` | yes | Quick-check premium flag | — |
| `subscription_status` | `string` | yes | Current subscription state | See [Subscription Status](#subscription-status) |
| `subscription_plan` | `string` | no | Product ID of active plan | — |
| `subscription_product_title` | `string` | no | Human-readable plan title | — |
| `subscription_expiry_date` | `timestamp` | no | When subscription expires | — |
| `subscription_start_date` | `timestamp` | no | When subscription started | — |
| `subscription_assigned_by` | `string` | no | Who assigned the subscription (admin UID or `"admin"`) | — |
| `subscription_assigned_at` | `timestamp` | no | When subscription was assigned | — |
| `subscription_revoked_at` | `timestamp` | no | When subscription was revoked | — |
| `subscription_revoked_by` | `string` | no | Who revoked the subscription | — |
| `payment_gateway` | `string` | no | Payment method used | `google_pay`, `bank_transfer`, `admin_grant`, `paypal` |
| `auto_renew` | `boolean` | no | Whether subscription auto-renews | — |
| `premium_updated_at` | `timestamp` | no | Last premium status change | — |
| `has_complete_profile` | `boolean` | no | Whether profile completion flow is done | — |
| `therapist_status` | `string` | no | Therapist approval status (for role=therapist) | See [Therapist Approval Status](#therapist-approval-status) |
| `whatsapp_number` | `string` | no | WhatsApp contact number | — |
| `whatsapp_ads_consent` | `boolean` | no | Consent for WhatsApp marketing | — |
| `matching_preferences` | `map` | no | Therapist matching preferences | — |
| `last_login` | `timestamp` | no | Last login time | — |
| `created_at` | `timestamp` | yes | Account creation time | — |
| `updated_at` | `timestamp` | yes | Last update time | — |
| `settings` | `map` | no | User preferences (see below) | — |

#### `settings` sub-map

| Field | Type | Default |
|-------|------|---------|
| `notifications_enabled` | `boolean` | `true` |
| `daily_reminders` | `boolean` | `true` |
| `mood_tracking_reminders` | `boolean` | `true` |
| `reminder_time` | `string` | `"09:00"` |
| `dark_mode` | `boolean` | `false` |
| `language` | `string` | `"English"` |
| `anonymous_in_community` | `boolean` | `false` |
| `share_progress` | `boolean` | `false` |

#### Naming Resolution: `display_name` vs `name` vs `phone_number` vs `phone`

| Conflict | Resolution | Rationale |
|----------|-----------|-----------|
| `display_name` vs `name` | **Both kept.** `name` = short name set at registration. `display_name` = full name set during profile completion. Laravel `User::getDisplayName()` falls back: `display_name` → `name` → `email`. | Backward compatible; both fields serve different purposes. |
| `phone_number` vs `phone` | **`phone`** is the canonical field on the `users` collection. `phone_number` is used on the `therapists` collection (therapist-specific contact). | Flutter writes `phone` to users. Therapist profiles use `phone_number`. |

---

### `therapists`

Therapist profile documents. Document ID = Firebase Auth UID.

> **Collection name resolution**: The canonical collection is **`therapists`**, not `therapist_profiles`. All code must use `therapists`. Legacy references to `therapist_profiles` have been migrated.

| Field | Type | Required | Description | Enum Values |
|-------|------|----------|-------------|-------------|
| `email` | `string` | yes | Therapist email | — |
| `name` | `string` | yes | Full name | — |
| `title` | `string` | no | Professional title | — |
| `bio` | `string` | no | Biography text | — |
| `photo_url` | `string` | no | Profile photo URL | — |
| `specialties` | `array<string>` | no | List of specialties | `anxiety`, `depression`, `trauma`, `relationships`, `stress`, `selfEsteem`, `grief`, `addiction` |
| `session_types` | `array<string>` | no | Supported session types | See [Session Type](#session-type) |
| `therapy_types` | `array<string>` | no | Therapy modalities | `individual`, `couples`, `teen` |
| `languages` | `array<string>` | no | Languages spoken | — |
| `qualifications` | `array<string>` | no | Professional qualifications | — |
| `session_price` | `number` | no | Price per session | — |
| `currency` | `string` | no | Currency code (default: `SAR`) | — |
| `years_experience` | `integer` | no | Years of experience | — |
| `approval_status` | `string` | yes | Admin approval state | See [Therapist Approval Status](#therapist-approval-status) |
| `is_active` | `boolean` | yes | Whether therapist is accepting bookings | — |
| `rating` | `number` | no | Average rating (1-5) | — |
| `review_count` | `integer` | no | Total number of reviews | — |
| `phone_number` | `string` | no | Therapist contact phone | — |
| `license_document_url` | `string` | no | Uploaded license document | — |
| `approved_at` | `timestamp` | no | When approved by admin | — |
| `approved_by` | `string` | no | Admin UID who approved | — |
| `rejection_reason` | `string` | no | Reason for rejection | — |
| `created_at` | `timestamp` | yes | Profile creation time | — |
| `updated_at` | `timestamp` | no | Last update time | — |

---

### `bookings`

Session booking records.

| Field | Type | Required | Description | Enum Values |
|-------|------|----------|-------------|-------------|
| `therapist_id` | `string` | yes | Therapist UID | — |
| `client_id` | `string` | yes | Client (user) UID | — |
| `client_name` | `string` | yes | Client display name | — |
| `client_email` | `string` | no | Client email | — |
| `client_photo_url` | `string` | no | Client avatar URL | — |
| `client_age` | `integer` | no | Client age | — |
| `primary_complaint` | `string` | no | Reason for booking | — |
| `scheduled_time` | `timestamp` | yes | Session start time | — |
| `duration_minutes` | `integer` | yes | Session length (default: 60) | — |
| `session_type` | `string` | yes | Type of session | See [Session Type](#session-type) |
| `status` | `string` | yes | Booking status | See [Booking Status](#booking-status) |
| `amount` | `number` | yes | Payment amount | — |
| `currency` | `string` | yes | Currency code (default: `SAR`) | — |
| `notes` | `string` | no | Public/system notes | — |
| `private_notes` | `string` | no | Therapist-only notes | — |
| `cancellation_reason` | `string` | no | Reason for cancellation | — |
| `rejection_reason` | `string` | no | Reason for rejection | — |
| `created_at` | `timestamp` | yes | Booking creation time | — |
| `confirmed_at` | `timestamp` | no | When therapist confirmed | — |
| `completed_at` | `timestamp` | no | When session completed | — |
| `cancelled_at` | `timestamp` | no | When booking was cancelled | — |
| `updated_at` | `timestamp` | no | Last update time | — |

---

### `payments`

Payment transaction records.

| Field | Type | Required | Description | Enum Values |
|-------|------|----------|-------------|-------------|
| `user_id` | `string` | yes | Paying user UID | — |
| `user_email` | `string` | no | User email at time of payment | — |
| `amount` | `number` | yes | Payment amount | — |
| `currency` | `string` | yes | Currency code (default: `SAR`) | — |
| `status` | `string` | yes | Payment status | `pending`, `completed`, `failed`, `refunded` |
| `payment_method` | `string` | yes | How payment was made | `card`, `bank_transfer`, `manual_verification`, `paypal`, `google_pay` |
| `reference_code` | `string` | no | Bank transfer reference | — |
| `gateway_transaction_id` | `string` | no | External gateway ID | — |
| `product_id` | `string` | no | Subscription product ID | — |
| `product_title` | `string` | no | Human-readable product name | — |
| `start_date` | `timestamp` | no | Subscription period start | — |
| `end_date` | `timestamp` | no | Subscription period end | — |
| `notes` | `string` | no | Admin notes | — |
| `created_at` | `timestamp` | yes | Payment creation time | — |
| `updated_at` | `timestamp` | no | Last update time | — |

---

### `payment_verifications`

Bank transfer verification requests.

| Field | Type | Required | Description | Enum Values |
|-------|------|----------|-------------|-------------|
| `user_id` | `string` | yes | Requesting user UID | — |
| `user_name` | `string` | no | User display name | — |
| `user_email` | `string` | no | User email | — |
| `product_id` | `string` | no | Subscription product ID | — |
| `product_title` | `string` | no | Product display name | — |
| `amount` | `number` | yes | Claimed payment amount | — |
| `currency` | `string` | yes | Currency code | — |
| `reference_code` | `string` | no | Bank transfer reference | — |
| `receipt_url` | `string` | no | Uploaded receipt image URL | — |
| `status` | `string` | yes | Verification status | `pending`, `approved`, `rejected` |
| `reviewed_at` | `timestamp` | no | When admin reviewed | — |
| `reviewed_by` | `string` | no | Admin UID who reviewed | — |
| `rejection_reason` | `string` | no | Reason for rejection | — |
| `created_at` | `timestamp` | yes | Request creation time | — |

---

### `subscription_products`

Available subscription plans.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | `string` | yes | Plan name |
| `description` | `string` | no | Plan description |
| `price` | `number` | yes | Price amount |
| `currency_code` | `string` | yes | Currency (default: `SAR`) |
| `billing_period` | `string` | yes | `weekly`, `monthly`, `yearly`, `hourly` |
| `billing_period_days` | `integer` | yes | Duration in days |
| `localized_price` | `string` | no | Formatted price string |
| `is_featured` | `boolean` | no | Whether to highlight in UI |
| `is_active` | `boolean` | no | Whether available for purchase |
| `features` | `array<string>` | no | Feature bullet points |

---

## Enums

### Subscription Status

Stored in `users.subscription_status`.

| Value | Description |
|-------|-------------|
| `free` | No active subscription (default) |
| `active` | Paid subscription currently valid |
| `pending` | Awaiting payment verification |
| `expired` | Subscription period ended |
| `cancelled` | User or admin cancelled |
| `suspended` | Admin suspended account |

> **Note**: Flutter `SubscriptionState` enum also includes `error` for client-side error handling. This value is never written to Firestore.

### Therapist Approval Status

Stored in `therapists.approval_status` and `users.therapist_status`.

| Value | Description |
|-------|-------------|
| `pending` | Awaiting admin review |
| `approved` | Approved — can accept bookings |
| `rejected` | Rejected by admin |
| `suspended` | Temporarily suspended |

### Session Type

Stored in `bookings.session_type` and `therapists.session_types[]`.

| Firestore Value | Dart Enum | Description |
|-----------------|-----------|-------------|
| `audio` | `SessionType.audio` | Audio call session |
| `chat` | `SessionType.chat` | Text chat session |
| `in_person` | `SessionType.inPerson` | In-person session |

> **Migration note**: Legacy data may contain `inPerson` (camelCase). All parsers accept both `in_person` and `inPerson` for backward compatibility. New writes always use `in_person`.

### Booking Status

Stored in `bookings.status`.

| Value | Description |
|-------|-------------|
| `pending` | Awaiting therapist confirmation |
| `confirmed` | Therapist accepted |
| `completed` | Session finished |
| `cancelled` | Cancelled by client, therapist, or admin |
| `rejected` | Therapist declined |
| `no_show` | Client did not attend |

### User Role

Stored in `users.role`.

| Value | Description |
|-------|-------------|
| `user` | Regular user |
| `therapist` | Therapist (also has document in `therapists` collection) |
| `admin` | Administrator |

### Payment Status

Stored in `payments.status`.

| Value | Description |
|-------|-------------|
| `pending` | Payment initiated, not yet confirmed |
| `completed` | Payment successful |
| `failed` | Payment failed |
| `refunded` | Payment refunded |

---

## Cross-Stack Consistency Rules

1. **Timestamps**: Always Firestore native `Timestamp`. Never ISO-8601 strings, never `toDateTimeString()`.
2. **Collection name**: `therapists` (not `therapist_profiles`).
3. **Session type values**: `in_person` (snake_case), never `inPerson`.
4. **Field name `phone`**: Used on `users` collection. `phone_number` on `therapists` collection.
5. **Field name `name`/`display_name`**: Both exist on `users`. `display_name` is the preferred display field; `name` is the fallback.
6. **Currency default**: `SAR` for bookings/therapists, `USD` for subscription products (configurable per product).
