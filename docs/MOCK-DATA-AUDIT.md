# Mock Data Audit Report

**Date**: 2026-01-08
**Status**: Complete Codebase Audit
**Finding**: Multiple features use mock/demo data when Firestore is empty or on error

---

## Executive Summary

The app currently works with **MIXED DATA SOURCES**:
- ✅ **Real Data**: Admin dashboard stats, payment history, chat threads, mood entries
- ⚠️ **Mock Data When Empty**: Therapist dashboard, therapist directory, recommendations, challenges
- ❌ **Always Mock**: Recent activity, risk alerts, patient detail stats, response speed

**Total Mock Locations Found**: 11 categories across 14 files

---

## P1: Always Shows Mock Data (CRITICAL)

These locations **ALWAYS** show hardcoded data, never query Firestore:

### 1. Admin Dashboard - Recent Activity
**File**: `lib/features/admin/screens/admin_dashboard_screen.dart`
**Lines**: 185-210
**Mock Data**:
```dart
final activities = [
  {'user': 'Dr. Sarah Smith', 'action': 'completed a session', 'time': '5 mins ago'},
  {'user': 'Ahmed Ali', 'action': 'booked a new appointment', 'time': '12 mins ago'},
  {'user': 'System', 'action': 'sent reminder notifications', 'time': '25 mins ago'},
  {'user': 'Fatima', 'action': 'updated her profile', 'time': '1 hour ago'},
];
```
**Impact**: Admin never sees real recent activity
**Fix**: Query Firestore `activity_log` collection or remove this panel

---

### 2. Admin Dashboard - Risk Alerts Panel
**File**: `lib/features/admin/widgets/dashboard/risk_alerts_panel.dart`
**Lines**: 33-55
**Mock Data**:
```dart
// TODO: Connect to actual risk provider
final mockAlerts = [
  RiskAlert(patientId: '1', patientName: 'Sarah Johnson', level: RiskLevel.critical, indicator: 'Mood declining for 7 days'),
  RiskAlert(patientId: '2', patientName: 'Ahmed Hassan', level: RiskLevel.high, indicator: '3 missed sessions'),
  RiskAlert(patientId: '3', patientName: 'Maria Garcia', level: RiskLevel.moderate, indicator: 'Increased anxiety scores'),
];
```
**Impact**: Admin never sees real patient risk alerts
**Fix**: Implement actual risk calculation from mood entries and session data

---

### 3. Admin Analytics - Response Speed
**File**: `lib/features/admin/services/admin_analytics_service.dart`
**Lines**: 39-43
**Mock Data**:
```dart
Future<String> fetchResponseSpeed() async {
  await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
  return '5m 23s'; // Mock
}
```
**Impact**: Always shows same response time
**Fix**: Calculate real average response time from chat messages

---

### 4. Admin Chat List - Average Response Time
**File**: `lib/features/admin/screens/admin_chat_list_screen.dart`
**Line**: 164
**Mock Data**:
```dart
final avgResponseTime = '< 2h'; // Mock data
```
**Impact**: Always shows "< 2h" regardless of real data
**Fix**: Calculate from actual chat message timestamps

---

### 5. Patient Detail Screen - Session Stats
**File**: `lib/features/admin/screens/patient_detail_screen.dart`
**Lines**: 318-354
**Mock Data**:
```dart
_StatCard(title: 'Total Sessions', value: '12', ...)
_StatCard(title: 'Completed', value: '10', ...)
_StatCard(title: 'Cancelled', value: '2', ...)
_StatCard(title: 'Balance', value: 'SAR 150', ...)
```
**Impact**: All patients show same fake stats
**Fix**: Query Firestore `bookings` collection for real patient stats

---

### 6. Patient Detail Screen - Upcoming Sessions
**File**: `lib/features/admin/screens/patient_detail_screen.dart`
**Lines**: 484-498 (`_getMockUpcomingSessions()`)
**Mock Data**:
```dart
return [
  {'date': DateTime.now().add(const Duration(days: 2)), 'therapist': 'Dr. Sarah Wilson', 'status': 'confirmed'},
  {'date': DateTime.now().add(const Duration(days: 7)), 'therapist': 'Dr. Sarah Wilson', 'status': 'pending'},
];
```
**Impact**: All patients show same fake upcoming sessions
**Fix**: Query Firestore `bookings` where `user_id == patientId` and `date >= now`

---

### 7. Patient Detail Screen - Session History
**File**: `lib/features/admin/screens/patient_detail_screen.dart`
**Lines**: 501-524 (`_getMockSessionHistory()`)
**Mock Data**:
```dart
return [
  {'date': DateTime.now().subtract(const Duration(days: 7)), 'therapist': 'Dr. Sarah Wilson', 'status': 'completed', 'duration': 50},
  {'date': DateTime.now().subtract(const Duration(days: 14)), 'therapist': 'Dr. Sarah Wilson', 'status': 'completed', 'duration': 45},
  {'date': DateTime.now().subtract(const Duration(days: 21)), 'therapist': 'Dr. Sarah Wilson', 'status': 'cancelled'},
];
```
**Impact**: All patients show same fake session history
**Fix**: Query Firestore `bookings` where `user_id == patientId` and `date < now`

---

### 8. Patient Detail Screen - Recent Activity
**File**: `lib/features/admin/screens/patient_detail_screen.dart`
**Lines**: 1009-1031 (`_RecentActivityList`)
**Mock Data**:
```dart
final activities = [
  {'icon': Icons.video_camera_front_outlined, 'title': 'Video session completed', 'subtitle': 'With Dr. Sarah Wilson', 'time': '2 days ago'},
  {'icon': Icons.mood_outlined, 'title': 'Mood logged', 'subtitle': 'Feeling good', 'time': '3 days ago'},
  {'icon': Icons.assignment_outlined, 'title': 'Assessment completed', 'subtitle': 'PHQ-9 Score: 8', 'time': '1 week ago'},
];
```
**Impact**: All patients show same fake activity timeline
**Fix**: Query patient's mood entries, bookings, and assessments

---

### 9. Patient Detail Screen - Assessment Scores
**File**: `lib/features/admin/screens/patient_detail_screen.dart`
**Lines**: 1259-1263 (`_AssessmentScoresList`)
**Mock Data**:
```dart
final assessments = [
  {'name': 'PHQ-9', 'score': 8, 'maxScore': 27, 'level': 'Mild'},
  {'name': 'GAD-7', 'score': 5, 'maxScore': 21, 'level': 'Mild'},
  {'name': 'PSS-10', 'score': 14, 'maxScore': 40, 'level': 'Low'},
];
```
**Impact**: All patients show same fake assessment scores
**Fix**: Query Firestore `assessments` collection for patient

---

### 10. Patient Detail Screen - Assessment History
**File**: `lib/features/admin/screens/patient_detail_screen.dart`
**Lines**: 1342-1358 (`_AssessmentHistoryList`)
**Mock Data**:
```dart
final history = [
  {'name': 'PHQ-9', 'date': DateTime.now().subtract(const Duration(days: 7)), 'score': 8},
  {'name': 'GAD-7', 'date': DateTime.now().subtract(const Duration(days: 14)), 'score': 5},
  {'name': 'PHQ-9', 'date': DateTime.now().subtract(const Duration(days: 30)), 'score': 12},
];
```
**Impact**: All patients show same fake assessment timeline
**Fix**: Query Firestore `assessments` collection ordered by date

---

## P2: Shows Mock When Firestore Empty (MEDIUM)

These locations query Firestore first, but fall back to mock data if empty:

### 11. Therapist Dashboard - Stats (when DB empty)
**File**: `lib/features/therapist_portal/providers/therapist_dashboard_provider.dart`
**Lines**: 228-244, 81-112
**Logic**:
```dart
final shouldUseMock = completedBookings == 0 && activeChats.isEmpty && pendingBookings.isEmpty && todaysBookings.isEmpty;
state = state.copyWith(useMockData: shouldUseMock);
```
**Mock Getters**:
```dart
int get activeChatsCount => useMockData && activeChats.isEmpty ? 3 : activeChats.length;
int get pendingCount => useMockData && pendingBookings.isEmpty ? 2 : pendingBookings.length;
int get displayTotalSessions => useMockData && totalSessions == 0 ? 47 : totalSessions;
double get displayTotalEarnings => useMockData && totalEarnings == 0 ? 1250.0 : totalEarnings;
```
**Impact**: New therapists see fake stats instead of "0 sessions" empty state
**Fix**: Show "Getting Started" UI instead of fake data

---

### 12. Therapist Directory - Demo Therapists
**File**: `lib/features/therapists/repositories/therapist_repository.dart`
**Lines**: 12-114
**Logic**: Returns 4 demo therapists when Firestore `/therapists` collection is empty
**Mock Data**:
```dart
static final List<TherapistProfile> _demoTherapists = [
  TherapistProfile(id: 'demo_therapist_1', name: 'Dr. Sarah Ahmed', title: 'Clinical Psychologist', sessionPrice: 200.0, rating: 4.9, reviewCount: 127),
  TherapistProfile(id: 'demo_therapist_2', name: 'Dr. Omar Hassan', title: 'Psychiatrist', sessionPrice: 300.0, rating: 4.8, reviewCount: 89),
  TherapistProfile(id: 'demo_therapist_3', name: 'Dr. Layla Mansour', title: 'Family Therapist', sessionPrice: 180.0, rating: 4.7, reviewCount: 156),
  TherapistProfile(id: 'demo_therapist_4', name: 'Dr. Khalid Al-Rashid', title: 'CBT Specialist', sessionPrice: 220.0, rating: 4.9, reviewCount: 201),
];
```
**Impact**: Users see fake therapists they can't actually book
**Fix**: Show "No therapists available" empty state or seed real therapist data

---

### 13. Home Recommendations - Demo Content
**File**: `lib/features/home/providers/recommendation_provider.dart`
**Lines**: 58-94
**Logic**: Returns demo recommendations if Firestore `content` collection is empty
**Mock Data**:
```dart
List<ContentItem> _getDemoRecommendations(String? mood) {
  return [
    ContentItem(id: 'demo_article_1', title: 'Understanding Your Emotions', type: 'article'),
    ContentItem(id: 'demo_exercise_1', title: '5-Minute Breathing Exercise', type: 'exercise'),
    ContentItem(id: 'demo_podcast_1', title: 'Mindful Moments', type: 'podcast'),
  ];
}
```
**Impact**: Users see content they can't access
**Fix**: Show "Coming soon" or seed real content

---

### 14. Daily Challenge - Demo Challenges
**File**: `lib/features/engagement/providers/challenge_provider.dart`
**Lines**: 54, 81-84, 100-104
**Logic**:
- Guest users always see `DemoChallenges.getToday()`
- Falls back to demo if Firestore `daily_challenges` collection is empty
- Falls back to demo on error

**Impact**: Users see challenges that may not reflect real content
**Fix**: Seed real challenges or show empty state

---

### 15. Admin Analytics - Therapist Ratings (when empty)
**File**: `lib/features/admin/providers/admin_analytics_provider.dart`
**Lines**: 65-70, 80-88
**Logic**:
```dart
if (realTotalReviews == 0) {
  finalAvg = 4.8;
  finalReviews = 124; // Mock count
  usingMock = true;
}
```
**Impact**: Admin sees fake "4.8 rating, 124 reviews" when no reviews exist
**Fix**: Show "No reviews yet" instead of fake data

---

## ✅ P3: Working with Real Data (GOOD)

These locations properly query Firestore and show empty states when no data exists:

1. **Admin Dashboard Stats** (`admin_provider.dart:318-387`)
   - ✅ Queries real `users`, `bookings`, `payments` collections
   - Shows actual counts and revenue

2. **Admin Chat Threads** (`admin_chat_list_screen.dart`)
   - ✅ Streams real chat threads from `AdminChatService().getChatThreads()`
   - Shows actual unread counts and messages

3. **Patient Payment History** (`patient_detail_screen.dart:1507-1556`)
   - ✅ Queries real `payments` collection filtered by `user_id`
   - Shows actual payment transactions

4. **Mood Tracker** (`mood_tracker_provider.dart`)
   - ✅ Queries real mood entries from Firestore
   - No mock data fallback

---

## Recommended Fixes

### Quick Wins (Remove Mock Data)

1. **Admin Dashboard Recent Activity** - Delete the hardcoded list, show "Coming Soon" message
2. **Risk Alerts Panel** - Show "No alerts" empty state with explanation
3. **Patient Detail Stats** - Query real booking counts or show "No data"
4. **Response Speed** - Remove metric until real calculation is implemented

### Medium Priority (Empty States)

5. **Therapist Dashboard** - Replace mock stats with "Getting Started" UI
6. **Therapist Directory** - Show "No therapists available" + admin seeding instructions
7. **Recommendations** - Show "Explore our content library" empty state
8. **Daily Challenges** - Show "Check back tomorrow" empty state
9. **Admin Analytics Ratings** - Show "0 reviews" instead of fake 4.8

### Low Priority (Real Data Queries)

10. **Patient Sessions** - Query `bookings` collection
11. **Patient Activity** - Query mood + bookings + assessments
12. **Patient Assessments** - Query `assessments` collection
13. **Response Speed** - Calculate from chat timestamps

---

## Summary Statistics

| Category | Count | Severity |
|----------|-------|----------|
| **Always Mock** | 10 locations | ❌ Critical |
| **Mock When Empty** | 5 locations | ⚠️ Medium |
| **Real Data** | 4 locations | ✅ Good |
| **Total Files Audited** | 198 Dart files | - |
| **Files with Mock Data** | 14 files | - |

---

## Next Steps

1. ✅ **Complete this audit** - Done
2. ⏳ **Prioritize fixes** - Focus on P1 (always mock) first
3. ⏳ **Implement empty states** - Better UX than fake data
4. ⏳ **Update constitution** - Add guidance on mock data vs empty states
5. ⏳ **Seed real data** - Use admin data management screen to populate Firestore

---

**Audit Completed By**: Claude Sonnet 4.5
**Audit Date**: 2026-01-08
**Files Scanned**: 198 Dart files across 18 feature modules
**Tools Used**: Grep, Read, Manual code review
