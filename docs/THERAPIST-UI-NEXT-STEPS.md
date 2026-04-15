# Therapist UI Redesign - Quick Implementation Guide

**Current Status:** 60% Complete (Phases 1-2 done, Phase 3 partial)
**Remaining:** Phases 3-5 (availability, chat, profile, analytics, localization)

---

## 🚀 Quick Start: Test What's Done

```bash
# 1. Kill existing Flutter process
lsof -ti:5000 | xargs kill -9

# 2. Start the app
flutter run -d chrome --web-port=5000

# 3. Navigate as therapist:
# - Login with therapist credentials
# - Dashboard → See 4 charts + KPI cards
# - Bookings → See analytics header with mini bar chart
```

**Expected Result:**
- ✅ Dashboard shows KPI sparklines, session volume, earnings, and distribution charts
- ✅ Bookings screen shows gradient analytics header with stats
- ✅ All charts are interactive (hover, tap, period toggles)
- ✅ Dark mode works correctly

---

## 📋 Remaining Tasks (Copy-Paste Ready)

### TASK 1: Availability Screen Insights Header (30 min)

**Create:** `lib/features/therapist_portal/widgets/availability_insights_header.dart`

```dart
// Copy pattern from bookings_analytics_header.dart
// 3 stats: Available Slots (green), Booked Slots (blue), Utilization % (amber)
// Sparklines for each metric
// Peak times heatmap (7 days × 10 hours grid)
```

**Modify:** `lib/features/therapist_portal/screens/therapist_availability_screen.dart`

```dart
// Add import
import '../widgets/availability_insights_header.dart';

// In body Column (after AppBar), add:
AvailabilityInsightsHeader(
  data: _generateAvailabilityInsights(),
),

// Add mock data generator:
AvailabilityInsightsData _generateAvailabilityInsights() {
  return AvailabilityInsightsData(
    availableSlots: 42,
    bookedSlots: 28,
    utilizationRate: 67,
    weeklyTrend: [60, 65, 70, 67],
    peakHours: [...], // 7×10 grid of booking density
  );
}
```

---

### TASK 2: Chat List Response Metrics Header (20 min)

**Create:** `lib/features/therapist_chat/widgets/chat_metrics_header.dart`

```dart
// 3 stats: Avg Response Time, Unread Count, Urgent Count
// Sparkline for response time
// Red/amber/green color coding
// Height: 120px
```

**Modify:** `lib/features/therapist_chat/screens/therapist_chat_list_screen.dart`

```dart
// Add import and header above filter tabs
ChatMetricsHeader(
  data: _generateChatMetrics(),
),

// Mock data:
ChatMetricsData _generateChatMetrics() {
  return ChatMetricsData(
    avgResponseMinutes: 2.3,
    unreadCount: 5,
    urgentCount: 2,
    responseTrend: [3.2, 3.0, 2.8, 2.6, 2.5, 2.4, 2.3],
  );
}
```

---

### TASK 3: Profile Completeness Card (15 min)

**Create:** `lib/features/therapist_portal/widgets/profile_completeness_card.dart`

```dart
// Progress bar (LinearProgressIndicator)
// Missing items list (bio, certifications, session types, etc.)
// Color: Green (100%), Amber (50-99%), Red (<50%)
// "Complete Profile" button
```

**Modify:** `lib/features/therapist_portal/screens/therapist_profile_edit_screen.dart`

```dart
// Add at top of form (before first section)
ProfileCompletenessCard(
  completionPercentage: 75,
  missingItems: ['Professional bio', 'Certifications'],
),
```

---

### TASK 4: Chat Detail Patient Context Panel (25 min)

**Modify:** `lib/features/therapist_chat/screens/therapist_chat_detail_screen.dart`

```dart
// Add collapsible panel above messages:
class _PatientContextPanel extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final PatientContextData data;
}

// Data: name, age, session count, last session, primary concern, last mood
// Quick actions: View Sessions, Schedule, Notes buttons
// Gradient background (primary blue)
// Animation: height 140px → 60px
```

---

### TASK 5: Analytics Dashboard Screen (60 min)

**Create:** `lib/features/therapist_portal/screens/therapist_analytics_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../widgets/charts/kpi_sparkline_card.dart';
import '../widgets/charts/session_volume_chart.dart';
import '../widgets/charts/earnings_chart.dart';
import '../widgets/charts/patient_distribution_chart.dart';

class TherapistAnalyticsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Overview'),
        actions: [
          IconButton(icon: Icon(Icons.file_download), onPressed: _exportPDF),
          _buildPeriodSelector(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column([
          // 4 large KPI cards (2×2 grid)
          _buildKPIGrid(),

          // Session trends (multi-line: completed vs cancelled)
          SessionTrendsChart(),

          // Revenue breakdown (stacked bar)
          RevenueBreakdownChart(),

          // Patient insights
          _buildPatientInsights(),
        ]),
      ),
    );
  }
}
```

**Add route** in `lib/routes/app_router.dart`:

```dart
GoRoute(
  path: '/therapist/analytics',
  name: AppRoutes.therapistAnalytics,
  builder: (context, state) => const TherapistAnalyticsScreen(),
),
```

**Link from dashboard** in quick actions grid.

---

### TASK 6: Localization Strings (45 min)

**File:** `lib/core/l10n/app_strings_en.dart`

```dart
// Add 80 strings:

// Charts
String get sessionVolumeChart => 'Session Volume';
String get earningsChart => 'Earnings';
String get patientDistribution => 'Patient Distribution';
String get performanceMetrics => 'Performance Metrics';
String get averageRating => 'Average Rating';
String get responseTime => 'Response Time';
String get completionRate => 'Completion Rate';
String get rebookingRate => 'Rebooking Rate';

// Dashboard
String get viewDetailedAnalytics => 'View Detailed Analytics';
String get sessionTrends => 'Session Trends';
String get earningsTrends => 'Earnings Trends';
String get weeklyComparison => 'Weekly Comparison';
String get thisWeek => 'This Week';
String get lastWeek => 'Last Week';

// Availability
String get availabilityInsights => 'Availability Insights';
String get availableSlots => 'Available Slots';
String get bookedSlots => 'Booked Slots';
String get utilizationRate => 'Utilization Rate';
String get peakBookingTimes => 'Peak Booking Times';
String get recommendedTimes => 'Recommended Times to Add';

// Chat
String get responseMetrics => 'Response Metrics';
String get avgResponseTime => 'Avg Response Time';
String get unreadMessages => 'Unread Messages';
String get urgentChats => 'Urgent Chats';
String get patientContext => 'Patient Context';
String get primaryConcern => 'Primary Concern';
String get lastMoodEntry => 'Last Mood Entry';
String get viewAllSessions => 'View All Sessions';
String get scheduleNewSession => 'Schedule New Session';

// Profile
String get profileCompleteness => 'Profile Completeness';
String get missingItems => 'Missing Items';
String get completeYourProfile => 'Complete Your Profile';
String get previewProfile => 'Preview Profile';
String get professionalBio => 'Professional Bio';
String get uploadCredentials => 'Upload Credentials';
String get verificationPending => 'Verification Pending';

// Analytics
String get analyticsOverview => 'Analytics Overview';
String get performanceOverview => 'Performance Overview';
String get patientInsights => 'Patient Insights';
String get newPatients => 'New Patients';
String get returningPatients => 'Returning Patients';
String get avgSessionsPerPatient => 'Avg Sessions per Patient';
String get topPresentingIssues => 'Top Presenting Issues';
String get ratingsAndFeedback => 'Ratings & Feedback';
String get exportToPDF => 'Export to PDF';
String get exportToCSV => 'Export to CSV';
String get customPeriod => 'Custom Period';
String get selectDateRange => 'Select Date Range';

// Period labels
String get week => 'Week';
String get month => 'Month';
String get quarter => 'Quarter';
String get year => 'Year';
String get custom => 'Custom';

// Additional
String get lastWeeks(int weeks) => 'Last $weeks Weeks';
String get validUntil => 'Valid Until';
String get trendIndicator => 'Trend';
String get noDataAvailable => 'No data available';
String get loadingAnalytics => 'Loading analytics...';
```

**Copy to Arabic** (`app_strings_ar.dart`):
```dart
String get sessionVolumeChart => 'حجم الجلسات';
String get earningsChart => 'الأرباح';
// ... etc (use Google Translate or professional translation)
```

**Copy to French** (`app_strings_fr.dart`):
```dart
String get sessionVolumeChart => 'Volume de Sessions';
String get earningsChart => 'Revenus';
// ... etc
```

---

### TASK 7: Dark Mode Testing (15 min)

```bash
# 1. Run app
flutter run -d chrome

# 2. Toggle dark mode in browser
# Chrome DevTools → Rendering → Emulate CSS prefers-color-scheme: dark

# 3. Test each screen:
# - Dashboard charts visible?
# - Bookings analytics readable?
# - Text contrast good? (WCAG AA: 4.5:1)
# - Borders visible?
# - Gradients render correctly?

# 4. Fix any issues:
# - Use AppColors.textMuted, borderDark, surfaceDark
# - Check shadow opacity (0.3 for dark, 0.05 for light)
```

---

### TASK 8: RTL Testing (10 min)

```bash
# 1. Switch to Arabic language in app settings

# 2. Verify:
# - Charts flip correctly (fl_chart handles this automatically)
# - Legends on correct side (right → left)
# - Icons on correct side
# - Text alignment correct

# 3. Check code uses:
# - EdgeInsetsDirectional (not EdgeInsets)
# - Align.start / Align.end (not left/right)
# - Row with Directionality check
```

---

### TASK 9: Documentation Updates (10 min)

**File:** `docs/FEATURES-STATUS.md`

```markdown
## Therapist Portal (12/13 working) ✅

### Features
- ✅ Dashboard with analytics
  - KPI performance metrics (rating, response time, completion, rebooking)
  - Session volume trends (line chart)
  - Earnings comparison (bar chart)
  - Patient distribution (donut chart)
- ✅ Bookings management with analytics header
- ✅ Availability insights and scheduling
- ✅ Chat response metrics monitoring
- ✅ Profile completeness tracking
...
```

**File:** `docs/CHANGELOG-2026-01-10.md` (CREATE)

```markdown
# Changelog - 2026-01-10

## Therapist UI Redesign - Professional Charts & Analytics

### Added
- Professional chart system with 4 chart types (line, bar, pie, sparkline)
- Therapist dashboard analytics with performance metrics
- Bookings analytics header with weekly trends
- KPI performance tracking (rating, response time, completion, rebooking)
- Session volume visualization with period toggles
- Earnings trend analysis with comparison
- Patient distribution insights by session type
- Availability utilization metrics
- Chat response monitoring

### Enhanced
- Therapist dashboard layout with responsive charts
- Bookings screen UI with gradient analytics card
- Chart interactions (tooltips, period selection)
- Data visualization consistency
- Dark mode support across all charts
- Responsive design (mobile/tablet/desktop)

### Technical
- Reusable chart component system (BaseChartCard)
- Mock data generators with TODO comments
- Consistent design system application
- fl_chart integration (already a dependency)
- Performance optimizations
```

---

## ✅ Final Verification Checklist

Before marking complete:

```bash
# 1. Compilation check
flutter analyze lib/features/therapist_portal/ lib/features/therapist_chat/
# Expected: 0 errors

# 2. Run app
flutter run -d chrome --web-port=5000

# 3. Test flow
# ✅ Login as therapist
# ✅ Dashboard → All charts render
# ✅ Bookings → Analytics header shows
# ✅ Availability → Insights header shows
# ✅ Chat → Metrics header shows
# ✅ Profile → Completeness card shows
# ✅ Analytics → Full dashboard works
# ✅ Toggle dark mode → Everything visible
# ✅ Switch to Arabic → RTL works

# 4. Documentation
# ✅ FEATURES-STATUS.md updated
# ✅ CHANGELOG-2026-01-10.md created
# ✅ All TODO comments in place
```

---

## 📞 Need Help?

**Patterns to Follow:**
- Check `therapist_dashboard_screen.dart` for complete chart integration
- Check `bookings_analytics_header.dart` for analytics header pattern
- Check `chart_utils.dart` for all helper functions
- Check `kpi_sparkline_card.dart` for metric card pattern

**Common Issues:**
1. **Charts not showing:** Check mock data generator returns non-empty list
2. **Dark mode broken:** Use AppColors, not hardcoded colors
3. **Import errors:** Run `flutter pub get`
4. **Layout overflow:** Use Expanded/Flexible in Column/Row

**Quick Reference:**
```dart
// Chart colors
ChartColors.getColor(index)
ChartColors.success / warning / error

// Chart styles
ChartStyles.defaultGrid(isDark)
ChartStyles.defaultBorder(isDark)

// Data formatting
ChartDataProcessor.formatPercentage(value)
ChartDataProcessor.formatCurrency(amount, currency)
ChartDataProcessor.formatLargeNumber(number)
```

---

## 🎯 Estimated Time to Complete

| Task | Time | Difficulty |
|------|------|------------|
| Availability insights | 30 min | Easy |
| Chat metrics | 20 min | Easy |
| Profile completeness | 15 min | Easy |
| Chat detail panel | 25 min | Medium |
| Analytics dashboard | 60 min | Medium |
| Localization (80×3) | 45 min | Easy |
| Dark mode testing | 15 min | Easy |
| RTL testing | 10 min | Easy |
| Documentation | 10 min | Easy |

**Total:** ~3.5 hours remaining work

**Current completion:** 60%
**After completion:** 100%

---

All patterns are established. Just follow the examples and replicate the structure. Good luck! 🚀
