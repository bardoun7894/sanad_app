# Tasks: Dashboard Real Data Completion

## Phase 1: Setup & Data Prep
- [x] **FR-1.1**: Fix Admin Dashboard "Sessions Today" count query.
    - [x] Modify `lib/features/admin/providers/admin_provider.dart` to use `scheduled_time` range.
- [x] **FR-3.1**: Add composite indexes for `bookings` collection.
    - [x] Update `firestore.indexes.json`.

## Phase 2: Response Speed Logic
- [x] **FR-1.2**: Implement dynamic Response Speed calculation.
    - [x] Update `lib/features/admin/services/admin_analytics_service.dart`.
    - [x] Create `fetchResponseSpeed` method to analyze `therapist_chats`.

## Phase 3: Therapist Reviews & Ratings
- [x] **FR-2.1**: Create `reviews` collection schema (if not exists).
- [x] **FR-2.2**: Implement `ReviewService` for transactional updates.
    - [x] Create `lib/features/ratings/services/review_service.dart`.
    - [x] Handle therapist aggregate updates (`average_rating`, `review_count`).
- [x] **FR-2.3**: Update `TherapistAnalyticsProvider` to use real ratings data.

## Phase 4: Activity Log & UI Polish
- [x] **FR-1.3**: Populate Admin Activity Log with real events.
- [x] **FR-3.1**: Verify empty states across all dashboard widgets.
- [x] Cleanup: Remove hardcoded mock data in `AdminAnalyticsProvider`.
