# Implementation Plan: Dashboard Real Data Completion

## Proposed Changes

### 1. Fix Session Counting Bug
#### [MODIFY] `lib/features/admin/providers/admin_provider.dart`
- Update `dashboardStatsProvider`.
- Change `.where('date', ...)` to query range on `scheduled_time`.

### 2. Implement Response Speed Logic
#### [MODIFY] `lib/features/admin/services/admin_analytics_service.dart`
- Implement `fetchResponseSpeed()`.
- Query `therapist_chats` for recent messages.
- Calculate delta between last user message and therapist response.

### 3. Implement Reviews Logic
#### [NEW] `lib/features/ratings/services/review_service.dart`
- Create service to handle adding reviews.
- Transactional update: Add to `reviews` collection AND update `therapist_profiles` aggregate fields.

#### [MODIFY] `lib/features/therapist_portal/providers/therapist_analytics_provider.dart`
- Ensure it consumes the real aggregated data.

### 4. Firestore Configuration
#### [MODIFY] `firestore.indexes.json`
- Add missing indexes for `payment_verifications` (Status + CreatedAt, Status + ReviewedAt).

## Verification Plan

### Automated Tests
- n/a (Manual verification preferred for UI/Firebase integration)

### Manual Verification
1. **Sessions**: Create a booking for "today". Verify Admin Dashboard "Sessions Today" = 1.
2. **Ratings**: Submit a review for a therapist. Verify Therapist Dashboard rating changes.
3. **Speed**: Send a chat message -> Reply as therapist. Verify "Response Speed" updates (or shows non-mock value).
