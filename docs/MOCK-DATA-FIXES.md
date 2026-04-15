# Mock Data Elimination - Implementation Guide

**Date**: 2026-01-08
**Status**: Ready for Implementation
**Priority**: High (blocks accurate "brownfield reality" claim)

---

## Overview

This document provides **exact code changes** to eliminate all mock data from the Sanad app. Organized by priority (P1 = Critical, P2 = Medium, P3 = Low).

---

## P1: Critical Fixes (Always Mock Data)

### Fix 1: Admin Dashboard - Remove Recent Activity Panel

**File**: `lib/features/admin/screens/admin_dashboard_screen.dart`
**Lines to Remove**: 185-210
**Action**: Delete the hardcoded activities list

**Before** (lines 174-213):
```dart
// Recent Activity Card
_buildCard(
  title: 'Recent Activity',
  child: _buildRecentActivity(isDark),
  isDark: isDark,
),

// Inside _buildRecentActivity method
final activities = [
  {'user': 'Dr. Sarah Smith', 'action': 'completed a session', 'time': '5 mins ago'},
  // ... 3 more hardcoded entries
];
```

**After**:
```dart
// Remove the entire Recent Activity card OR replace with:
_buildCard(
  title: 'Recent Activity',
  child: Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(Icons.access_time_outlined, size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('Activity tracking coming soon', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    ),
  ),
  isDark: isDark,
),
```

**Estimated Time**: 5 minutes
**Testing**: Check admin dashboard still loads without errors

---

### Fix 2: Risk Alerts Panel - Show Empty State

**File**: `lib/features/admin/widgets/dashboard/risk_alerts_panel.dart`
**Lines to Replace**: 33-55
**Action**: Replace mock alerts with real query or empty state

**Before** (lines 32-55):
```dart
// TODO: Connect to actual risk provider
final mockAlerts = [
  RiskAlert(patientId: '1', patientName: 'Sarah Johnson', ...),
  // ... 2 more mock alerts
];

return _buildAlertsList(mockAlerts, isDark);
```

**After** (Option 1 - Empty State):
```dart
// Show empty state until risk algorithm is implemented
return Center(
  child: Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 48, color: AppColors.textMuted),
        SizedBox(height: 12),
        Text('No risk alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text(
          'Risk detection system is being configured',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
);
```

**After** (Option 2 - Real Implementation):
```dart
// Query Firestore for patients with concerning patterns
return StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('mood_entries')
      .where('mood', isEqualTo: 'very_sad')  // Example: very sad for 7 days
      .orderBy('date', descending: true)
      .limit(10)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    final alerts = _calculateRiskAlertsFromMoodData(snapshot.data?.docs ?? []);

    if (alerts.isEmpty) {
      return Center(child: Text('No risk alerts'));
    }

    return _buildAlertsList(alerts, isDark);
  },
);
```

**Estimated Time**: 15 minutes (empty state) or 2 hours (real implementation)
**Testing**: Check risk panel shows empty state or real data

---

### Fix 3: Admin Analytics - Response Speed

**File**: `lib/features/admin/services/admin_analytics_service.dart`
**Lines to Replace**: 39-43
**Action**: Calculate real average or return null

**Before**:
```dart
Future<String> fetchResponseSpeed() async {
  await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
  return '5m 23s'; // Mock
}
```

**After** (Option 1 - Remove metric):
```dart
Future<String?> fetchResponseSpeed() async {
  // Return null until real calculation is implemented
  return null;
}
```

**After** (Option 2 - Real calculation):
```dart
Future<String?> fetchResponseSpeed() async {
  try {
    final chatThreadsSnapshot = await _firestore.collection('chat_threads').get();

    if (chatThreadsSnapshot.docs.isEmpty) return null;

    int totalResponseTimeSeconds = 0;
    int responseCount = 0;

    for (final threadDoc in chatThreadsSnapshot.docs) {
      final messagesSnapshot = await threadDoc.reference
          .collection('messages')
          .orderBy('timestamp')
          .get();

      final messages = messagesSnapshot.docs;
      for (int i = 0; i < messages.length - 1; i++) {
        final currentMsg = messages[i].data();
        final nextMsg = messages[i + 1].data();

        // If user message followed by admin response
        if (currentMsg['sender_role'] == 'user' && nextMsg['sender_role'] == 'admin') {
          final userTime = (currentMsg['timestamp'] as Timestamp).toDate();
          final adminTime = (nextMsg['timestamp'] as Timestamp).toDate();
          final diff = adminTime.difference(userTime).inSeconds;

          totalResponseTimeSeconds += diff;
          responseCount++;
        }
      }
    }

    if (responseCount == 0) return null;

    final avgSeconds = totalResponseTimeSeconds / responseCount;
    final minutes = (avgSeconds / 60).floor();
    final seconds = (avgSeconds % 60).floor();

    return '${minutes}m ${seconds}s';
  } catch (e) {
    debugPrint('Error calculating response speed: $e');
    return null;
  }
}
```

**File to Update**: `lib/features/admin/providers/admin_analytics_provider.dart`
**Change line 54**: Handle null response speed
```dart
final speed = await _service.fetchResponseSpeed();
// ...
responseSpeed: speed ?? 'N/A',  // Show N/A instead of mock
```

**Estimated Time**: 10 minutes (remove) or 1 hour (real calculation)
**Testing**: Check analytics screen shows N/A or real average

---

### Fix 4: Admin Chat - Average Response Time

**File**: `lib/features/admin/screens/admin_chat_list_screen.dart`
**Line to Remove**: 164
**Action**: Calculate from real data or show N/A

**Before** (line 164):
```dart
final avgResponseTime = '< 2h'; // Mock data
```

**After**:
```dart
final avgResponseTime = 'N/A'; // Until real calculation is implemented
```

**Or** calculate from actual thread response times (similar to Fix 3).

**Estimated Time**: 2 minutes
**Testing**: Check chat list screen shows N/A in stats row

---

### Fix 5-10: Patient Detail Screen - All Mock Stats

**File**: `lib/features/admin/screens/patient_detail_screen.dart`
**Action**: Query real Firestore data for patient

**Overview**: Create a new `PatientStatsService` to centralize all patient data queries.

**Step 1**: Create `lib/features/admin/services/patient_stats_service.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getPatientStats(String patientId) async {
    final bookingsSnapshot = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: patientId)
        .get();

    final totalSessions = bookingsSnapshot.docs.length;
    final completed = bookingsSnapshot.docs.where((d) => d.data()['status'] == 'completed').length;
    final cancelled = bookingsSnapshot.docs.where((d) => d.data()['status'] == 'cancelled').length;

    // Calculate balance from payments
    final paymentsSnapshot = await _firestore
        .collection('payments')
        .where('user_id', isEqualTo: patientId)
        .get();

    double balance = 0;
    for (final doc in paymentsSnapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'pending') {
        balance += (data['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    return {
      'total_sessions': totalSessions,
      'completed': completed,
      'cancelled': cancelled,
      'balance': balance,
    };
  }

  Future<List<Map<String, dynamic>>> getUpcomingSessions(String patientId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: patientId)
        .where('date', isGreaterThanOrEqualTo: DateTime.now())
        .orderBy('date')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getSessionHistory(String patientId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: patientId)
        .where('date', isLessThan: DateTime.now())
        .orderBy('date', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentActivity(String patientId) async {
    final activities = <Map<String, dynamic>>[];

    // Fetch recent mood entries
    final moodSnapshot = await _firestore
        .collection('mood_entries')
        .where('user_id', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .limit(5)
        .get();

    for (final doc in moodSnapshot.docs) {
      final data = doc.data();
      activities.add({
        'icon': Icons.mood_outlined,
        'title': 'Mood logged',
        'subtitle': 'Feeling ${data['mood']}',
        'time': data['date'],
        'color': AppColors.statusInfo,
      });
    }

    // Fetch recent bookings
    final bookingSnapshot = await _firestore
        .collection('bookings')
        .where('user_id', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .limit(5)
        .get();

    for (final doc in bookingSnapshot.docs) {
      final data = doc.data();
      activities.add({
        'icon': Icons.video_camera_front_outlined,
        'title': 'Session ${data['status']}',
        'subtitle': 'With ${data['therapist_name'] ?? 'therapist'}',
        'time': data['date'],
        'color': data['status'] == 'completed' ? AppColors.statusSuccess : AppColors.statusWarning,
      });
    }

    // Sort by time
    activities.sort((a, b) => (b['time'] as Timestamp).compareTo(a['time'] as Timestamp));

    return activities.take(10).toList();
  }

  Future<List<Map<String, dynamic>>> getAssessmentScores(String patientId) async {
    final snapshot = await _firestore
        .collection('assessments')
        .where('user_id', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .limit(1)  // Get latest for each type
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getAssessmentHistory(String patientId) async {
    final snapshot = await _firestore
        .collection('assessments')
        .where('user_id', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
```

**Step 2**: Update `patient_detail_screen.dart` to use `PatientStatsService`

**Replace lines 318-354** (_OverviewTab stats cards):
```dart
// Instead of hardcoded values, use FutureBuilder:
FutureBuilder<Map<String, dynamic>>(
  future: PatientStatsService().getPatientStats(patient.id),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    final stats = snapshot.data ?? {};

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Sessions',
            value: '${stats['total_sessions'] ?? 0}',
            icon: Icons.video_camera_front_outlined,
            color: AppColors.statusInfo,
            isDark: isDark,
          ),
        ),
        // ... similar for completed, cancelled, balance
      ],
    );
  },
),
```

**Replace lines 484-524** (Mock session methods):
```dart
// Delete _getMockUpcomingSessions() and _getMockSessionHistory()
// Replace with:
Widget _buildUpcomingSessions(String patientId, bool isDark) {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: PatientStatsService().getUpcomingSessions(patientId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      final sessions = snapshot.data ?? [];
      return _SessionList(sessions: sessions, isDark: isDark, emptyMessage: 'No upcoming sessions');
    },
  );
}
```

**Estimated Time**: 2-3 hours (complete implementation)
**Testing**: Open patient detail page, verify real data from Firestore

---

## P2: Medium Priority Fixes (Mock When Empty)

### Fix 11: Therapist Dashboard - Replace Mock with Empty State

**File**: `lib/features/therapist_portal/providers/therapist_dashboard_provider.dart`
**Lines to Modify**: 228-244, 81-112
**Action**: Remove `useMockData` flag, show 0 instead of fake numbers

**Before** (lines 228-244):
```dart
final shouldUseMock = completedBookings == 0 && activeChats.isEmpty && ...;
state = state.copyWith(useMockData: shouldUseMock);
```

**After**:
```dart
// Remove useMockData logic completely
state = state.copyWith(
  totalSessions: completedBookings,
  totalEarnings: earnings,
  // No useMockData flag
);
```

**Before** (lines 81-112 - mock getters):
```dart
int get activeChatsCount => useMockData && activeChats.isEmpty ? 3 : activeChats.length;
int get pendingCount => useMockData && pendingBookings.isEmpty ? 2 : pendingBookings.length;
// ...
```

**After**:
```dart
int get activeChatsCount => activeChats.length;  // Show real 0 if empty
int get pendingCount => pendingBookings.length;
int get displayTotalSessions => totalSessions;
double get displayTotalEarnings => totalEarnings;
```

**UI Improvement**: Update dashboard screen to show "Getting Started" tips when stats are 0.

**Estimated Time**: 30 minutes
**Testing**: Login as therapist with no bookings, verify shows "0" instead of "47"

---

### Fix 12: Therapist Directory - Remove Demo Therapists

**File**: `lib/features/therapists/repositories/therapist_repository.dart`
**Lines to Remove**: 12-114
**Action**: Remove `_demoTherapists`, return empty list

**Before**:
```dart
static final List<TherapistProfile> _demoTherapists = [
  TherapistProfile(...), // 4 demo therapists
];

Future<List<TherapistProfile>> getApprovedTherapists() async {
  // ... query Firestore
  if (profiles.isEmpty) {
    return _demoTherapists;  // ❌ Fallback to demo
  }
  return profiles;
}
```

**After**:
```dart
// Delete _demoTherapists completely

Future<List<TherapistProfile>> getApprovedTherapists() async {
  // ... query Firestore
  return profiles;  // Return empty list if none found
}
```

**UI Improvement**: Update `therapist_list_screen.dart` to show:
```dart
if (therapists.isEmpty) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.people_outline, size: 64),
        SizedBox(height: 16),
        Text('No therapists available yet'),
        SizedBox(height: 8),
        Text('Check back soon!', style: TextStyle(color: AppColors.textMuted)),
      ],
    ),
  );
}
```

**Estimated Time**: 15 minutes
**Testing**: Clear Firestore therapists, verify shows empty state

---

### Fix 13: Recommendations - Remove Demo Content

**File**: `lib/features/home/providers/recommendation_provider.dart`
**Lines to Remove**: 67-94
**Action**: Delete `_getDemoRecommendations()`, show empty state

**Before**:
```dart
if (results.isEmpty) {
  return _getDemoRecommendations(moodTag);
}
```

**After**:
```dart
// Just return empty list
return results;
```

**UI Improvement**: Update home screen to handle empty recommendations:
```dart
if (recommendations.isEmpty) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('No recommendations yet. Explore our content library!'),
    ),
  );
}
```

**Estimated Time**: 10 minutes
**Testing**: Clear Firestore content, verify shows empty state

---

### Fix 14: Daily Challenge - Remove Demo Challenges

**File**: `lib/features/engagement/providers/challenge_provider.dart`
**Lines to Modify**: 54, 81-84, 100-104
**Action**: Remove `DemoChallenges.getToday()` fallback

**Before**:
```dart
if (_userId == null) {
  state = DailyChallengeState(challenge: DemoChallenges.getToday());
  return;
}
// ...
if (challengeQuery.docs.isEmpty) {
  challenge = DemoChallenges.getToday();
}
```

**After**:
```dart
if (_userId == null) {
  state = DailyChallengeState(challenge: null);  // No challenge for guests
  return;
}
// ...
if (challengeQuery.docs.isEmpty) {
  challenge = null;  // No challenge available
}
```

**UI Improvement**: Handle null challenge:
```dart
if (challenge == null) {
  return Card(child: Text('No challenge available today. Check back tomorrow!'));
}
```

**Estimated Time**: 15 minutes
**Testing**: Clear daily_challenges collection, verify shows empty state

---

### Fix 15: Admin Analytics - Remove Mock Ratings

**File**: `lib/features/admin/providers/admin_analytics_provider.dart`
**Lines to Remove**: 65-70, 80-88
**Action**: Show real 0.0 rating when no reviews

**Before**:
```dart
if (realTotalReviews == 0) {
  finalAvg = 4.8;   // ❌ Fake
  finalReviews = 124;
  usingMock = true;
}
```

**After**:
```dart
// Just use real data, even if 0
double finalAvg = realAvgRating;
int finalReviews = realTotalReviews;
```

**UI Improvement**: Show "No reviews yet" in analytics screen when rating is 0.

**Estimated Time**: 10 minutes
**Testing**: Clear reviews, verify shows 0.0 instead of 4.8

---

## Implementation Order

### Phase 1: Quick Wins (1-2 hours)
1. ✅ Fix 1: Remove Admin Dashboard Recent Activity
2. ✅ Fix 2: Risk Alerts Empty State
3. ✅ Fix 4: Admin Chat Response Time N/A
4. ✅ Fix 13: Remove Demo Recommendations
5. ✅ Fix 15: Remove Mock Ratings

### Phase 2: Therapist & User Features (2-3 hours)
6. ✅ Fix 11: Therapist Dashboard Empty State
7. ✅ Fix 12: Remove Demo Therapists
8. ✅ Fix 14: Remove Demo Challenges

### Phase 3: Complex Queries (3-4 hours)
9. ✅ Fix 5-10: Patient Detail Real Data (create PatientStatsService)
10. ✅ Fix 3: Real Response Speed Calculation

---

## Testing Checklist

After implementing fixes:

- [ ] Run `flutter analyze` - no errors
- [ ] Test admin dashboard with empty Firestore - shows empty states
- [ ] Test patient detail with real booking data - shows actual stats
- [ ] Test therapist dashboard with no bookings - shows "0" not "47"
- [ ] Test therapist directory with no therapists - shows empty state
- [ ] Test home recommendations with no content - shows empty state
- [ ] Test daily challenges with no challenges - shows empty state
- [ ] Test analytics with no reviews - shows "0.0" not "4.8"
- [ ] Verify all StreamBuilders/FutureBuilders handle loading states
- [ ] Verify all error states are handled gracefully

---

## Constitution Update

After completing fixes, update `.specify/memory/constitution.md`:

**Section VIII (Performance & Optimization)** - Add:
```markdown
**Data Integrity**:
- NEVER show mock/demo/fake data to users
- Show empty states instead of placeholder data
- Use "Coming Soon", "No data yet", or "N/A" for unavailable features
- Only use fallback data for unavoidable errors (network failures)
```

---

## Success Criteria

✅ **Zero mock data** shown to users when Firestore is empty
✅ **Accurate stats** when real data exists
✅ **Clear empty states** that communicate what's missing
✅ **No user confusion** about whether therapists/content/stats are real
✅ **Constitution compliance** - Data integrity maintained

---

**Document Version**: 1.0
**Last Updated**: 2026-01-08
**Implementation Status**: Ready for Developer Review
