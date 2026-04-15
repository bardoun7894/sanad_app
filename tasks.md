# Sanad Admin Milestones

## M1 - Stabilize Premium + Profile [DONE]
- [x] Fix subscription cache init (late Box → nullable) — `subscription_storage_service.dart`
- [x] Fix repository fallback (split try blocks) — `subscription_repository.dart`
- [x] Add loading guard before paywall — `feature_gating_provider.dart`, `chat_screen.dart`
- [x] Fix profile-completion false redirect — `auth_provider.dart`
- [x] Fix subscription init for profileIncomplete users — `subscription_provider.dart`

---

## M2 - Unify Data Contract

### 2.1 Define shared field contract
- [ ] Create `docs/data-contract.md` listing canonical field names, types, and enums for: user, subscription, payment, therapist, booking
- [ ] Resolve naming conflicts: `phone_number` vs `phone`, `display_name` vs `name`, `inPerson` vs `in_person`
- [ ] Resolve collection conflicts: `therapists` vs `therapist_profiles`

### 2.2 Standardize timestamps
- [ ] Laravel `EditUser.php:109` — change `now()->toDateTimeString()` to Firestore native timestamp
- [ ] Laravel `PaymentVerification.php:85,98,103,106,123` — change string dates to native timestamps
- [ ] Laravel `FirestoreService.php` — add helper to always write Firestore `Timestamp` type
- [ ] Verify Flutter side already uses `Timestamp.fromDate()` / `FieldValue.serverTimestamp()` consistently

### 2.3 Standardize enums
- [ ] Session types: pick one of `inPerson`/`in_person`, update `WeeklyAgendaWidget.php:67`, `BookingResource.php:67`, `admin_analytics_service.dart:217`
- [ ] Subscription status: confirm `active|cancelled|expired|free|suspended` used identically in both stacks

---

## M3 - Align Critical Workflows

### 3.1 Payment verification approval
- [ ] Compare Flutter `admin_provider.dart:251-298` vs Laravel `PaymentVerification.php:70-142`
- [ ] Unify fields written on approval: add missing `payment_gateway`, `auto_renew`, `productId` to Laravel
- [ ] Unify expiry calculation: Flutter uses `productId.contains('yearly')`, Laravel hardcodes 30 days
- [ ] Unify payment record fields written to `payments` collection

### 3.2 Subscription assign/revoke
- [ ] Compare Flutter `admin_users_provider.dart:230-320` vs Laravel `ViewUser.php:91-143`
- [ ] Laravel assign missing fields: `auto_renew`, `productId` (for Flutter compat)
- [ ] Laravel revoke missing fields: `subscription_revoked_at`, `subscription_revoked_by`
- [ ] Flutter assign: add `subscription_product_title` (Laravel writes it)
- [ ] EditUser.php:104 — changing `subscription_status` alone is insufficient; must also set `is_premium`

### 3.3 Therapist approval
- [ ] Compare Flutter `admin_therapist_provider.dart:85-110` vs Laravel `ListTherapists.php`
- [ ] Flutter sets `users.role=therapist` + `therapists.is_active=true`; ensure Laravel does the same
- [ ] Ensure both create therapist profile doc if missing on promote

---

## M4 - Harden Admin Writes

### 4.1 Audit trail consistency
- [ ] Add `actor_uid` field to all admin write operations (both stacks)
- [ ] Fix Laravel `EditUser.php:113` wrong activity type `userRegistered` → `userUpdated`
- [ ] Fix Laravel `EditUser.php:63` wrong activity type for suspend action
- [ ] Ensure Flutter `admin_provider.dart` logs all mutations (currently some are silent)

### 4.2 Permission enforcement
- [ ] Unify admin role check: Flutter uses `authProvider.isAdmin` + `adminProvider.isAdmin` separately
- [ ] Pick single source of truth for admin role (prefer Firebase custom claims)
- [ ] Ensure `firestore.rules` covers all admin-write paths consistently

---

## M5 - Remove UX Gaps

### 5.1 Disable/remove placeholder actions
- [ ] Flutter `payments_overview_screen.dart:463` — approve/reject/refund show only snackbar, no mutation
- [ ] Flutter `users_list_screen.dart:598` — export "coming soon"
- [ ] Flutter `analytics_screen.dart:349` — export TODO
- [ ] Flutter `bookings_list_screen.dart:734` — new booking "coming soon"
- [ ] Flutter `moderation_dashboard.dart:943` — approve/flag no-op handlers
- [ ] Flutter `data_management_screen.dart` — informational only, no actions

### 5.2 Fix routing
- [ ] Flutter `global_search_bar.dart:182` — therapist search navigates to `/admin/therapists/{id}` but router expects `/admin/therapists/detail` with `extra`
- [ ] Laravel `QuickActionsWidget.php:24-43` — hardcoded `/admin/...` paths; use `Resource::getUrl()`
- [ ] Laravel `Notification.php:142-148` — hardcoded action URLs

### 5.3 Localization
- [ ] Flutter admin screens with hardcoded English: `users_list_screen.dart:144`, `bookings_list_screen.dart:189`, `therapists_list_screen.dart:168`, `reports_screen.dart:24`, `verification_list_screen.dart:234`

---

## M6 - Scale Dashboard

### 6.1 Replace full-collection scans
- [ ] Flutter `admin_provider.dart:359` — dashboard stats fetch all users/payments/assessments
- [ ] Flutter `admin_booking_provider.dart:55` — loads all bookings
- [ ] Flutter `admin_therapist_provider.dart:57` — loads all therapists
- [ ] Flutter `admin_chat_service.dart:211` — broadcast pulls all users
- [ ] Add pagination/cursor to Flutter admin list providers

### 6.2 Optimize analytics
- [ ] Flutter `admin_analytics_service.dart:199` — repeated full scans
- [ ] Flutter `risk_alerts_provider.dart:82` — N+1 user fetch per mood entry
- [ ] Laravel `FirestoreService.php:525` — `countDocuments()` fetches all then counts
- [ ] Laravel `UserInsightsService.php:68-78` — N+1 per user insights

### 6.3 Fix Laravel pagination
- [ ] `FirestoreService.php:376` — fake cursor pagination (fetches all, filters in memory)
- [ ] Implement real Firestore `startAfter` cursor pagination

### 6.4 KPI parity
- [ ] Align no-show rate formula between Flutter and Laravel analytics
- [ ] Align therapist rating source (`therapists` vs `therapist_profiles`)
- [ ] Align risk alert classification rules between stacks
