# Feature Specification: Dashboard Real Data Completion

**Feature Branch**: `004-dashboard-completion`
**Created**: 2026-01-15
**Status**: In Progress
**Context**: Derived from `CHANGELOG-2026-01-15.md` and `admin_dashboard_audit.md`.

## Goal
Ensure the Admin and Therapist dashboards are 100% driven by real Firestore data, eliminating all remaining mock data (Response Speed, Recent Activity fallback) and fixing identified data mismatch bugs (Session Counts).

## User Scenarios

### User Story 1: Accurate Admin Oversight
As an Admin, I want to see accurate, real-time metrics for "Sessions Today" and "Response Speed" so that I can make informed operational decisions without being misled by mock or broken data.
- **Gap**: "Sessions Today" currently returns 0 due to field mismatch.
- **Gap**: "Response Speed" is hardcoded to "5m 23s".

### User Story 2: Therapist Performance Tracking
As a Therapist, I want my "Average Rating" and "Review Count" to update automatically when a patient submits a review, allowing me to track my real performance.
- **Gap**: No logic exists to update the `therapist_profile` rating fields when a review is submitted.

### User Story 3: Robust Data Integrity
As a Developer, I want database queries to be backed by proper indexes and schemas so that the dashboard loads reliably without "Missing Index" errors.
- **Gap**: `payment_verifications` queries are missing indexes.

## Requirements

### Functional Requirements

#### FR-1: Admin Dashboard Metrics
- **FR-1.1**: "Sessions Today" MUST query the `bookings` collection using the correct timestamp field (`scheduled_time`) instead of the non-existent `date` field.
- **FR-1.2**: "Response Speed" MUST be calculated dynamically by analyzing timestamps in the `therapist_chats` collection (e.g., average time between User message and Therapist reply).
- **FR-1.3**: Admin Activity Log MUST show real entries for all 5 key events (Session Completed, Mood Logged, Post Created, User Registered, Payment Verified).

#### FR-2: Therapist Reviews
- **FR-2.1**: A `reviews` collection MUST exist to store patient feedback.
- **FR-2.2**: Submitting a review MUST trigger a Cloud Function or Service method to recalculate the therapist's `average_rating` and `review_count` in their `therapist_profile`.

#### FR-3: Data Accuracy
- **FR-3.1**: ALL dashboard widgets MUST handle empty states gracefully without showing mock data (show "0" or "No Data").

### Non-Functional Requirements

- **NFR-1**: Dashboard load time MUST NOT exceed 2 seconds.
- **NFR-2**: Firestore queries MUST rely on composite indexes where required (specifically `payment_verifications`).

## Technical Debt / cleanup
- Remove any remaining `kDebugMode` mock data fallbacks in `AdminAnalyticsProvider`.
