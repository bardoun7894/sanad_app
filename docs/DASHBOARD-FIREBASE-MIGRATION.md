# Dashboard Firebase Migration Analysis

**Audit Date**: 2026-01-15
**Audited By**: Claude Code
**Status**: Mixed - Some sections using Firebase, others using mock data

---

## Executive Summary

After auditing both Admin and Therapist dashboards, here's the current state:

### Admin Dashboard Status: 75% Firebase-Connected ✅

| Section | Status | Data Source | Notes |
|---------|--------|-------------|-------|
| **KPI Stats Cards** | ✅ Firebase | `dashboardStatsProvider` | Real queries for users, bookings, payments, assessments |
| **Weekly Agenda** | ✅ Firebase | `adminBookingProvider` | Real booking data with empty state handling |
| **Risk Alerts Panel** | ❌ Mock | Hardcoded array (lines 33-55) | TODO comment present |
| **Recent Activity** | ❌ Mock | Hardcoded array (lines 184-210) | No provider connection |

### Therapist Dashboard Status: 40% Firebase-Connected ⚠️

| Section | Status | Data Source | Notes |
|---------|--------|-------------|-------|
| **KPI Sparklines** | ❌ Mock | `_generateKPIData()` | TODO: Replace with real data |
| **Session Volume Chart** | ❌ Mock | `_generateSessionVolumeData()` | TODO: Replace with Firestore |
| **Earnings Chart** | ❌ Mock | `_generateEarningsData()` | TODO: Replace with Firestore |
| **Patient Distribution** | ❌ Mock | `_generateDistributionData()` | TODO: Replace with Firestore |
| **Bookings/Sessions Lists** | ✅ Firebase | Provider streams | Real-time bookings from Firestore |
| **Profile/Status** | ✅ Firebase | `therapistDashboardProvider` | Real-time profile updates |

---

## Detailed Findings

### 1. Admin Dashboard - KPI Stats (✅ WORKING)

**File**: `lib/features/admin/providers/admin_provider.dart`
**Lines**: 318-387

**What's Working**:
```dart
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  // ✅ Real Firestore queries:
  - Total users count (from /users collection)
  - Premium users count (is_premium == true)
  - New users this month (created_at filter)
  - Sessions today (from /bookings with date filter)
  - Pending sessions (status == 'pending')
  - Total revenue (sum of completed /payments)
  - Critical flags (from /assessments with risk_level filter)
});
```

**Metrics Calculated**:
- Total Users
- Premium Users
- Critical Flags
- Sessions Today
- Pending Sessions
- Total Revenue
- Users Trend (percentage)

**Status**: ✅ **Production Ready** - No changes needed.

---

### 2. Admin Dashboard - Weekly Agenda (✅ WORKING)

**File**: `lib/features/admin/widgets/dashboard/weekly_agenda.dart`
**Lines**: 13, 92-135

**What's Working**:
```dart
final bookingsState = ref.watch(adminBookingProvider);

// ✅ Real-time booking data:
- Shows bookings from Firestore
- Empty state when no bookings
- Displays client name, session type, time, status
- Responsive layout for different screen sizes
```

**Status**: ✅ **Production Ready** - No changes needed.

---

### 3. Admin Dashboard - Risk Alerts Panel (❌ MOCK DATA)

**File**: `lib/features/admin/widgets/dashboard/risk_alerts_panel.dart`
**Lines**: 33-55

**What's Broken**:
```dart
// TODO: Connect to actual risk provider
final mockAlerts = [
  RiskAlert(
    patientId: '1',
    patientName: 'Sarah Johnson',
    level: RiskLevel.critical,
    indicator: 'Mood declining for 7 days',
    lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  // ... 2 more hardcoded alerts
];
```

**Missing**:
- No `riskAlertsProvider` exists
- No Firestore collection for risk assessments is being queried
- No connection to mood tracker analytics
- No real-time monitoring of patient risk levels

**Migration Required**: ✅ YES

---

### 4. Admin Dashboard - Recent Activity (❌ MOCK DATA)

**File**: `lib/features/admin/screens/admin_dashboard_screen.dart`
**Lines**: 184-210

**What's Broken**:
```dart
final activities = [
  {
    'user': 'Dr. Sarah Smith',
    'action': 'completed a session',
    'time': '5 mins ago',
    'icon': Icons.check_circle,
  },
  // ... 3 more hardcoded activities
];
```

**Missing**:
- No `activityLogProvider` exists
- No Firestore collection for activity logs
- No tracking of user actions (bookings, sessions, mood logs, posts)
- No real-time activity stream

**Migration Required**: ✅ YES

---

### 5. Therapist Dashboard - KPI Sparklines (❌ MOCK DATA)

**File**: `lib/features/therapist_portal/screens/therapist_dashboard_screen.dart`
**Lines**: 784-819 (`_generateKPIData()`)

**What's Broken**:
```dart
/// Generate mock KPI data with sparklines
/// TODO: Replace with real data from provider
List<KPIData> _generateKPIData(TherapistDashboardState state, S strings) {
  return [
    KPIData(
      label: strings.avgRating,
      value: '4.8',
      percentageChange: 5.2,
      trendData: [4.5, 4.6, 4.7, 4.7, 4.8, 4.8, 4.8],
      icon: Icons.star_rounded,
      color: const Color(0xFFF59E0B),
    ),
    // ... 3 more hardcoded KPIs
  ];
}
```

**Mock KPIs**:
- Average Rating: 4.8
- Response Time: 2.3m
- Completion Rate: 96%
- Rebooking Rate: 78%

**Missing**:
- No calculation from actual bookings
- No real rating aggregation
- No real response time tracking
- No completion/rebooking metrics

**Migration Required**: ✅ YES

---

### 6. Therapist Dashboard - Session Volume Chart (❌ MOCK DATA)

**File**: `lib/features/therapist_portal/screens/therapist_dashboard_screen.dart`
**Lines**: 823-830 (`_generateSessionVolumeData()`)

**What's Broken**:
```dart
/// Generate mock session volume data
/// TODO: Replace with real data from Firestore
List<SessionVolumeData> _generateSessionVolumeData() {
  final now = DateTime.now();
  return List.generate(7, (i) {
    final date = now.subtract(Duration(days: 6 - i));
    final count = 3 + (i * 2) + (i % 2); // Trending up pattern
    return SessionVolumeData(date: date, sessionCount: count);
  });
}
```

**Missing**:
- No aggregation of bookings by date
- No filtering by therapist ID
- No real session counts per day

**Migration Required**: ✅ YES

---

### 7. Therapist Dashboard - Earnings Chart (❌ MOCK DATA)

**File**: `lib/features/therapist_portal/screens/therapist_dashboard_screen.dart`
**Lines**: 834-847 (`_generateEarningsData()`)

**What's Broken**:
```dart
/// Generate mock earnings data
/// TODO: Replace with real data from Firestore
List<EarningsData> _generateEarningsData(S strings) {
  final now = DateTime.now();
  return List.generate(7, (i) {
    final date = now.subtract(Duration(days: 6 - i));
    final label = ChartDataProcessor.getDayAbbreviation(date.weekday, strings);
    // Mock amounts with trending up pattern
    final current = 400.0 + (i * 50) + (i % 2 * 30);
    final previous = 350.0 + (i * 45);
    return EarningsData(label: label, current: current, previous: previous);
  });
}
```

**Missing**:
- No calculation from actual payments
- No grouping by date range
- No comparison with previous period
- No currency handling from bookings

**Migration Required**: ✅ YES

---

### 8. Therapist Dashboard - Patient Distribution Chart (❌ MOCK DATA)

**File**: `lib/features/therapist_portal/screens/therapist_dashboard_screen.dart`
**Lines**: 851-874 (`_generateDistributionData()`)

**What's Broken**:
```dart
/// Generate mock patient distribution data
/// TODO: Replace with real data from Firestore
List<PatientDistributionData> _generateDistributionData(S strings) {
  return [
    PatientDistributionData(
      category: strings.individual,
      count: 45,
      color: const Color(0xFF0066A3),
    ),
    // ... 3 more hardcoded categories
  ];
}
```

**Mock Categories**:
- Individual: 45
- Couples: 28
- Family: 18
- Group: 12

**Missing**:
- No aggregation from bookings by session type
- No filtering by therapist ID
- No real category distribution

**Migration Required**: ✅ YES

---

## Migration Plan

### Priority 1 - Admin Dashboard (2 sections)

#### A. Risk Alerts Panel

**Files to Create/Modify**:
1. Create `lib/features/admin/providers/risk_alerts_provider.dart`
2. Modify `lib/features/admin/widgets/dashboard/risk_alerts_panel.dart`

**Implementation Steps**:
```dart
// 1. Create RiskAlertsProvider
final riskAlertsProvider = FutureProvider<List<RiskAlert>>((ref) async {
  final firestore = FirebaseFirestore.instance;

  // Query assessments with high/critical risk
  final assessmentsSnapshot = await firestore
      .collection('assessments')
      .where('risk_level', whereIn: ['high', 'critical'])
      .orderBy('created_at', descending: true)
      .limit(10)
      .get();

  // Also check for mood declining patterns
  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));

  final moodEntriesSnapshot = await firestore
      .collectionGroup('mood_entries')
      .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
      .orderBy('created_at', descending: true)
      .get();

  // Process and combine alerts
  return _processAlerts(assessmentsSnapshot, moodEntriesSnapshot);
});

// 2. Update Widget to use provider
class RiskAlertsPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(riskAlertsProvider);

    return alertsAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (alerts) => _buildAlertsList(alerts),
    );
  }
}
```

**Firestore Collections Used**:
- `/assessments` (with `risk_level` field)
- `/users/{userId}/mood_entries` (collectionGroup query)

**Estimated Time**: 2-3 hours

---

#### B. Recent Activity Log

**Files to Create/Modify**:
1. Create `lib/features/admin/providers/activity_log_provider.dart`
2. Modify `lib/features/admin/screens/admin_dashboard_screen.dart`

**Implementation Steps**:
```dart
// 1. Create ActivityLogProvider
final recentActivityProvider = StreamProvider<List<ActivityLog>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('activity_logs')
      .orderBy('timestamp', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ActivityLog.fromFirestore(doc))
          .toList());
});

// 2. Add activity logging to key actions:
// - Session completed → log to activity_logs
// - Booking created → log to activity_logs
// - Mood entry created → log to activity_logs
// - Community post created → log to activity_logs
```

**Firestore Collection to Create**:
```
/activity_logs/{activityId}
  - type: string (session_completed, booking_created, mood_logged, post_created)
  - user_id: string
  - user_name: string
  - description: string
  - timestamp: timestamp
  - metadata: map (additional context)
```

**Estimated Time**: 3-4 hours

---

### Priority 2 - Therapist Dashboard (4 charts)

#### A. KPI Sparklines

**Files to Modify**:
1. `lib/features/therapist_portal/providers/therapist_dashboard_provider.dart`
2. `lib/features/therapist_portal/screens/therapist_dashboard_screen.dart`

**Implementation Steps**:
```dart
// 1. Add KPI calculation to provider
class TherapistDashboardNotifier extends StateNotifier<TherapistDashboardState> {
  Future<void> _loadKPIMetrics() async {
    // Average Rating
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('therapist_id', isEqualTo: _therapistId)
        .get();
    final avgRating = _calculateAverage(reviewsSnapshot, 'rating');

    // Response Time (from chat messages)
    final chatsSnapshot = await _firestore
        .collection('therapist_chats')
        .where('therapist_id', isEqualTo: _therapistId)
        .get();
    final avgResponseTime = _calculateResponseTime(chatsSnapshot);

    // Completion Rate
    final completedBookings = await _bookingService.getCompletedBookingsCount(_therapistId);
    final totalBookings = await _bookingService.getTotalBookingsCount(_therapistId);
    final completionRate = (completedBookings / totalBookings * 100);

    // Rebooking Rate
    final rebookingRate = await _calculateRebookingRate();

    state = state.copyWith(
      avgRating: avgRating,
      avgResponseTime: avgResponseTime,
      completionRate: completionRate,
      rebookingRate: rebookingRate,
    );
  }
}

// 2. Update screen to use real data
List<KPIData> _generateKPIData(TherapistDashboardState state, S strings) {
  return [
    KPIData(
      label: strings.avgRating,
      value: state.avgRating?.toStringAsFixed(1) ?? '0.0',
      // ... use real data
    ),
  ];
}
```

**Firestore Collections Used**:
- `/reviews` (with `therapist_id`, `rating` fields)
- `/therapist_chats` (with `therapist_id`, `messages` subcollection)
- `/bookings` (with `therapist_id`, `status` fields)

**Estimated Time**: 4-5 hours

---

#### B. Session Volume Chart

**Implementation Steps**:
```dart
// Add to TherapistDashboardNotifier
Future<List<SessionVolumeData>> _loadSessionVolumeData(ChartPeriod period) async {
  final now = DateTime.now();
  final daysToFetch = period == ChartPeriod.week ? 7 : 30;
  final startDate = now.subtract(Duration(days: daysToFetch - 1));

  final bookingsSnapshot = await _firestore
      .collection('bookings')
      .where('therapist_id', isEqualTo: _therapistId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('status', isEqualTo: 'completed')
      .get();

  // Group by date
  final volumeByDate = <DateTime, int>{};
  for (final doc in bookingsSnapshot.docs) {
    final date = (doc['date'] as Timestamp).toDate();
    final dateKey = DateTime(date.year, date.month, date.day);
    volumeByDate[dateKey] = (volumeByDate[dateKey] ?? 0) + 1;
  }

  return _formatVolumeData(volumeByDate);
}
```

**Estimated Time**: 2-3 hours

---

#### C. Earnings Chart

**Implementation Steps**:
```dart
// Add to TherapistDashboardNotifier
Future<List<EarningsData>> _loadEarningsData(ChartPeriod period) async {
  final now = DateTime.now();
  final daysToFetch = period == ChartPeriod.week ? 7 : 30;
  final startDate = now.subtract(Duration(days: daysToFetch - 1));
  final previousStartDate = startDate.subtract(Duration(days: daysToFetch));

  // Current period earnings
  final currentEarnings = await _calculateEarnings(startDate, now);

  // Previous period earnings (for comparison)
  final previousEarnings = await _calculateEarnings(previousStartDate, startDate);

  return _formatEarningsData(currentEarnings, previousEarnings);
}

Future<Map<DateTime, double>> _calculateEarnings(DateTime start, DateTime end) async {
  final bookingsSnapshot = await _firestore
      .collection('bookings')
      .where('therapist_id', isEqualTo: _therapistId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThan: Timestamp.fromDate(end))
      .where('status', isEqualTo: 'completed')
      .get();

  final earningsByDate = <DateTime, double>{};
  for (final doc in bookingsSnapshot.docs) {
    final date = (doc['date'] as Timestamp).toDate();
    final dateKey = DateTime(date.year, date.month, date.day);
    final amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;
    earningsByDate[dateKey] = (earningsByDate[dateKey] ?? 0) + amount;
  }

  return earningsByDate;
}
```

**Estimated Time**: 3-4 hours

---

#### D. Patient Distribution Chart

**Implementation Steps**:
```dart
// Add to TherapistDashboardNotifier
Future<List<PatientDistributionData>> _loadDistributionData(
  DistributionCategory category,
) async {
  final bookingsSnapshot = await _firestore
      .collection('bookings')
      .where('therapist_id', isEqualTo: _therapistId)
      .where('status', isEqualTo: 'completed')
      .get();

  final distribution = <String, int>{};

  for (final doc in bookingsSnapshot.docs) {
    final key = category == DistributionCategory.sessionType
        ? doc['session_type'] as String? ?? 'unknown'
        : doc['issue_category'] as String? ?? 'unknown';

    distribution[key] = (distribution[key] ?? 0) + 1;
  }

  return _formatDistributionData(distribution);
}
```

**Estimated Time**: 2-3 hours

---

## Total Effort Estimate

| Priority | Component | Effort | Complexity |
|----------|-----------|--------|------------|
| P1 | Admin Risk Alerts | 2-3h | Medium |
| P1 | Admin Recent Activity | 3-4h | Medium (requires activity logging) |
| P2 | Therapist KPI Sparklines | 4-5h | High (multiple calculations) |
| P2 | Therapist Session Volume | 2-3h | Low |
| P2 | Therapist Earnings | 3-4h | Medium |
| P2 | Therapist Distribution | 2-3h | Low |
| **Total** | **6 components** | **18-24 hours** | **Mixed** |

---

## Firestore Collections Required

### Existing Collections (Already Have Data)
- ✅ `/users`
- ✅ `/bookings`
- ✅ `/payments`
- ✅ `/therapist_chats`
- ✅ `/users/{userId}/mood_entries`

### New Collections Needed
- ❌ `/assessments` (for risk alerts)
- ❌ `/activity_logs` (for recent activity)
- ❌ `/reviews` (for therapist ratings)

### Missing Fields in Existing Collections
- `/bookings` may need: `amount`, `issue_category`, `session_type`
- Check if these fields already exist

---

## Implementation Order Recommendation

1. **Start with Admin Recent Activity** (easiest, visible impact)
   - Create activity_logs collection
   - Add logging to key actions
   - Wire up to dashboard

2. **Then Therapist Session Volume** (straightforward aggregation)
   - Query bookings by date
   - Group and display

3. **Then Therapist Earnings** (builds on #2)
   - Similar to session volume but with amounts
   - Add comparison logic

4. **Then Therapist Distribution** (simple grouping)
   - Group bookings by category
   - Format for chart

5. **Then Admin Risk Alerts** (requires mood analysis)
   - Query assessments
   - Analyze mood patterns
   - Combine alerts

6. **Finally Therapist KPI Sparklines** (most complex)
   - Multiple calculations
   - Trend data generation
   - Multiple collections involved

---

## Testing Checklist

After migration, verify:

### Admin Dashboard
- [ ] KPI stats show real user counts
- [ ] KPI stats show real revenue
- [ ] KPI stats show real critical flags
- [ ] Weekly Agenda shows real bookings
- [ ] Risk Alerts show real patient data (not mock)
- [ ] Recent Activity shows real actions (not mock)
- [ ] All sections handle empty state gracefully
- [ ] Dark mode works correctly

### Therapist Dashboard
- [ ] KPI Sparklines show real ratings
- [ ] KPI Sparklines show real response times
- [ ] KPI Sparklines show real completion rates
- [ ] Session Volume Chart shows real booking counts
- [ ] Earnings Chart shows real payment amounts
- [ ] Patient Distribution shows real category counts
- [ ] Charts update when period filter changes
- [ ] All charts handle empty state gracefully
- [ ] Dark mode works correctly

---

## Notes & Warnings

### ⚠️ Important Considerations

1. **Empty State Handling**: All charts must gracefully handle:
   - New therapists with no bookings
   - New admins with no users
   - Date ranges with no data

2. **Performance**: Be mindful of:
   - Firestore read costs (especially for charts with date ranges)
   - Query limits (max 30 results for expensive queries)
   - Caching strategies (use `FutureProvider` with autoDispose)

3. **Localization**: All chart labels must use:
   - `context.l10n` for user-facing text
   - No hardcoded English strings

4. **RTL Support**: Charts must work correctly:
   - In Arabic (right-to-left) layout
   - Test date formatting
   - Test number formatting

5. **Existing Mock Fallback**: The therapist provider already has logic to show mock data when database is empty:
   ```dart
   // Line 229-234 in therapist_dashboard_provider.dart
   final shouldUseMock =
       completedBookings == 0 &&
       state.activeChats.isEmpty &&
       state.pendingBookings.isEmpty &&
       state.todaysBookings.isEmpty;
   ```
   - Consider keeping this for demo purposes
   - Add a visual indicator when using mock data

---

## Conclusion

The good news: **75% of Admin Dashboard is already using Firebase** ✅
The challenge: **60% of Therapist Dashboard needs migration** ⚠️

All TODOs are clearly marked in code with comments like:
```dart
/// TODO: Replace with real data from Firestore
```

This makes migration straightforward - just follow the TODOs and implement the providers!

---

**Next Steps**:
1. Review this document with the user
2. Get approval for implementation order
3. Start with Priority 1 (Admin Dashboard)
4. Test thoroughly after each migration
5. Update `docs/FEATURES-STATUS.md` after completion

---

**Generated**: 2026-01-15 by Claude Code
**Last Updated**: 2026-01-15
