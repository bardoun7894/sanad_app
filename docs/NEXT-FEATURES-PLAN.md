# Sanad App - Next Features Implementation Plan

**Version**: 1.0
**Date**: February 27, 2026
**Scope**: High & Critical Priority Features (Research-Backed)
**Status**: Planning

---

## Overview

Three new features based on 2025-2026 mental health app research and market analysis. These features build on Sanad's existing Flutter/Riverpod/Firebase architecture and address the biggest gaps: **user safety**, **user retention**, and **clinical differentiation**.

| Feature                         | Priority     | Est. Effort | Target Milestone |
| ------------------------------- | ------------ | ----------- | ---------------- |
| Crisis & Emergency Detection    | **Critical** | 2 weeks     | M1               |
| Hybrid Human + AI Therapy       | **High**     | 3 weeks     | M2               |
| Gamified Mental Health Journeys | **High**     | 4 weeks     | M3               |

**Total Timeline**: ~9 weeks (sequential) or ~6 weeks (with overlap)

---

## Milestone 1: Crisis & Emergency Detection System

**Timeline**: Weeks 1-2
**Why Critical**: Sanad uses AI chat for mental health topics. Without crisis detection, the AI could inadvertently validate dangerous thoughts. This is a medical and legal requirement before production launch.

### Architecture

```
User sends message in AI Chat
  |
  v
Cloud Function: chatWithGemini()
  |
  v
Crisis Classifier (keyword + Gemini analysis)
  |
  +--[No Risk]--> Normal AI response
  |
  +--[Risk Detected]--> Crisis Protocol:
       |
       +-- 1. Write to /risk_alerts collection
       +-- 2. FCM alert to assigned therapist + admin
       +-- 3. Return safety response (hotlines, safety plan)
       +-- 4. Flag user in Admin Dashboard Risk Alerts panel
       +-- 5. Disable AI auto-responses, switch to human-only mode
```

### Firestore Schema

**New Collection: `/risk_alerts`**

```typescript
{
  user_id: string;
  user_name: string;
  alert_type: 'suicidal_ideation' | 'self_harm' | 'crisis' | 'severe_distress';
  severity: 'high' | 'critical';
  trigger_message: string;
  trigger_source: 'ai_chat' | 'mood_entry' | 'community_post';
  status: 'active' | 'acknowledged' | 'resolved';
  acknowledged_by?: string;
  acknowledged_at?: timestamp;
  resolved_by?: string;
  resolved_at?: timestamp;
  resolution_notes?: string;
  created_at: timestamp;
}
```

**Updated: `/users` document**

```typescript
{
  // Existing fields...
  crisis_mode: boolean;           // When true, AI chat disabled
  assigned_therapist_id?: string; // For crisis handoff
  last_risk_alert_at?: timestamp;
}
```

### Tasks

#### Week 1: Backend + Detection

| #   | Task                                                         | Files                                        | Est. |
| --- | ------------------------------------------------------------ | -------------------------------------------- | ---- |
| 1.1 | Create crisis keyword dictionary (Arabic + English + French) | `functions/crisis_keywords.json`             | 2h   |
| 1.2 | Add crisis classifier to `chatWithGemini` Cloud Function     | `functions/index.js`                         | 4h   |
| 1.3 | Create `/risk_alerts` Firestore collection + security rules  | `firestore.rules`                            | 1h   |
| 1.4 | Add FCM notification trigger on risk alert creation          | `functions/index.js`                         | 2h   |
| 1.5 | Create emergency hotlines data (Morocco, MENA region)        | `lib/core/constants/emergency_contacts.dart` | 1h   |

#### Week 2: Flutter UI + Admin Integration

| #    | Task                                                              | Files                                                      | Est. |
| ---- | ----------------------------------------------------------------- | ---------------------------------------------------------- | ---- |
| 1.6  | Create `CrisisResponseScreen` with safety plan + hotlines         | `lib/features/chat/screens/crisis_response_screen.dart`    | 4h   |
| 1.7  | Add crisis detection interceptor in AI chat provider              | `lib/features/chat/providers/chat_provider.dart`           | 3h   |
| 1.8  | Update Admin Risk Alerts panel with new `/risk_alerts` data       | `lib/features/admin/widgets/risk_alerts_widget.dart`       | 2h   |
| 1.9  | Add crisis alert actions (Acknowledge, Assign Therapist, Resolve) | `lib/features/admin/screens/risk_alert_detail_screen.dart` | 3h   |
| 1.10 | Add crisis mode flag to user profile + gate AI responses          | `lib/features/chat/providers/chat_provider.dart`           | 2h   |
| 1.11 | Localize all crisis strings (AR, EN, FR)                          | `lib/core/l10n/`                                           | 2h   |
| 1.12 | Write test cases for crisis detection flow                        | `test/crisis/`                                             | 2h   |

**Milestone 1 Deliverables**:

- Crisis keywords detected in AI chat, community posts, and mood entries
- Automatic safety response with localized emergency hotlines
- Real-time admin alerts with acknowledge/resolve workflow
- AI chat disabled for flagged users until therapist reviews
- 3 language support for all crisis content

---

## Milestone 2: Hybrid Human + AI Therapy Model

**Timeline**: Weeks 3-5
**Why High**: Sanad already has separate AI Chat and Therapist Chat. Bridging them into a seamless hybrid model creates a massive competitive advantage and improves clinical outcomes.

### Architecture

```
                    AI Chat Mode
                    (24/7, Free/Premium)
                         |
    +--------------------+--------------------+
    |                    |                    |
  Check-ins        Psychoeducation      Pattern Analysis
  "How are you?"   CBT exercises        Mood trend alerts
    |                    |                    |
    +--------------------+--------------------+
                         |
                   Handoff Triggers:
                   - Crisis detected (M1)
                   - User requests therapist
                   - AI confidence < threshold
                   - 3+ negative moods in a row
                         |
                         v
              +---------------------+
              |  Handoff Protocol   |
              |  1. Summarize context|
              |  2. Package mood data|
              |  3. Alert therapist  |
              |  4. Transition UI    |
              +---------------------+
                         |
                         v
                  Therapist Chat Mode
                  (Scheduled/On-demand)
                  Receives: AI summary + mood chart + chat history
```

### Firestore Schema

**New Collection: `/chat_handoffs`**

```typescript
{
  user_id: string;
  from_mode: 'ai' | 'therapist';
  to_mode: 'ai' | 'therapist';
  therapist_id?: string;
  trigger_reason: 'crisis' | 'user_request' | 'ai_low_confidence' | 'mood_pattern' | 'scheduled';
  ai_summary: string;              // AI-generated context summary
  mood_snapshot: {                  // Last 7 days mood data
    dates: timestamp[];
    moods: string[];
    average_score: number;
  };
  chat_history_ref: string;        // Reference to chat thread
  status: 'pending' | 'accepted' | 'completed';
  created_at: timestamp;
  accepted_at?: timestamp;
  completed_at?: timestamp;
}
```

**Updated: `/therapist_chats/{chatId}`**

```typescript
{
  // Existing fields...
  handoff_id?: string;             // Links to /chat_handoffs
  ai_summary?: string;             // Context from AI session
  mood_context?: map;              // Mood snapshot for therapist
}
```

### Tasks

#### Week 3: Handoff Engine + Cloud Functions

| #   | Task                                                  | Files                                                         | Est. |
| --- | ----------------------------------------------------- | ------------------------------------------------------------- | ---- |
| 2.1 | Create `ChatHandoff` model                            | `lib/features/chat/models/chat_handoff.dart`                  | 2h   |
| 2.2 | Create `ChatHandoffRepository` (CRUD to Firestore)    | `lib/features/chat/repositories/chat_handoff_repository.dart` | 3h   |
| 2.3 | Build AI summary generator Cloud Function             | `functions/index.js` (new: `generateSessionSummary`)          | 4h   |
| 2.4 | Build mood snapshot aggregator (last 7 days)          | `functions/index.js` (new: `getMoodSnapshot`)                 | 2h   |
| 2.5 | Create handoff trigger logic (mood pattern detection) | `functions/index.js` (new: `checkHandoffTriggers`)            | 4h   |
| 2.6 | Create `/chat_handoffs` collection + security rules   | `firestore.rules`, `firestore.indexes.json`                   | 1h   |

#### Week 4: Flutter UI - Chat Transition

| #    | Task                                                       | Files                                                     | Est. |
| ---- | ---------------------------------------------------------- | --------------------------------------------------------- | ---- |
| 2.7  | Create unified `HybridChatScreen` (AI + Therapist modes)   | `lib/features/chat/screens/hybrid_chat_screen.dart`       | 6h   |
| 2.8  | Build `ChatModeIndicator` widget (shows AI/Therapist mode) | `lib/features/chat/widgets/chat_mode_indicator.dart`      | 2h   |
| 2.9  | Build "Request Therapist" button in AI chat                | `lib/features/chat/widgets/request_therapist_button.dart` | 2h   |
| 2.10 | Build handoff transition animation (AI -> Therapist)       | `lib/features/chat/widgets/handoff_transition.dart`       | 3h   |
| 2.11 | Create `HandoffProvider` (Riverpod StateNotifier)          | `lib/features/chat/providers/handoff_provider.dart`       | 3h   |

#### Week 5: Therapist Side + Integration

| #    | Task                                                   | Files                                                           | Est. |
| ---- | ------------------------------------------------------ | --------------------------------------------------------------- | ---- |
| 2.12 | Show AI summary card in therapist chat view            | `lib/features/therapist_portal/widgets/ai_summary_card.dart`    | 3h   |
| 2.13 | Show mood snapshot chart in therapist chat             | `lib/features/therapist_portal/widgets/mood_context_chart.dart` | 3h   |
| 2.14 | Add handoff notifications (FCM to therapist)           | `functions/index.js`                                            | 2h   |
| 2.15 | Add handoff management to Admin Dashboard              | `lib/features/admin/widgets/handoff_queue_widget.dart`          | 3h   |
| 2.16 | Localize all handoff strings (AR, EN, FR)              | `lib/core/l10n/`                                                | 2h   |
| 2.17 | Integration testing: full AI -> Therapist handoff flow | `test/handoff/`                                                 | 3h   |

**Milestone 2 Deliverables**:

- Seamless AI-to-therapist chat transition within the same screen
- AI generates context summary + mood snapshot for therapist
- 4 automatic handoff triggers (crisis, user request, low confidence, mood pattern)
- Therapist receives rich context card before responding
- Admin can view/manage handoff queue

---

## Milestone 3: Gamified Mental Health Journeys

**Timeline**: Weeks 6-9
**Why High**: 60% of mental health app users drop out. Gamification retains 42% more users (RCT-proven). This directly drives Free->Premium conversions, which is Sanad's primary revenue model.

### Architecture

```
User Profile
  |
  +-- Gamification State (Riverpod + Hive cache)
       |
       +-- XP Points (earned from daily activities)
       +-- Level (1-50, unlocks new content)
       +-- Streak (consecutive daily logins)
       +-- Achievements (badges for milestones)
       +-- Journey Progress (CBT module chapters)
       |
       +-- Synced to: /users/{userId}/gamification
```

### Firestore Schema

**New Subcollection: `/users/{userId}/gamification`**

```typescript
// Single document: "progress"
{
  xp_total: number;
  level: number;                    // 1-50
  streak_current: number;           // Current consecutive days
  streak_longest: number;           // All-time record
  streak_last_date: timestamp;      // Last activity date

  // Achievements
  achievements: [{
    id: string;                     // e.g., 'first_mood', 'week_streak_7'
    title_ar: string;
    title_en: string;
    unlocked_at: timestamp;
  }];

  // Journey Progress
  active_journey_id?: string;
  journeys_completed: string[];
  chapters_unlocked: number;

  updated_at: timestamp;
}
```

**New Collection: `/journeys`**

```typescript
{
  title_ar: string;
  title_en: string;
  title_fr: string;
  description_ar: string;
  description_en: string;
  description_fr: string;
  category: 'anxiety' | 'depression' | 'stress' | 'self_esteem' | 'resilience' | 'mindfulness';
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  chapters: [{
    id: string;
    title_ar: string;
    title_en: string;
    content_type: 'lesson' | 'exercise' | 'quiz' | 'reflection';
    xp_reward: number;
    unlock_level: number;            // Minimum level required
  }];
  total_xp: number;
  estimated_days: number;
  icon: string;
  is_premium: boolean;               // Feature-gated
  is_active: boolean;
  display_order: number;
  created_at: timestamp;
}
```

### XP Reward System

| Action                     | XP Earned     | Frequency     |
| -------------------------- | ------------- | ------------- |
| Log daily mood             | +10 XP        | 1x/day        |
| Complete a journey chapter | +25 XP        | Per chapter   |
| 7-day streak               | +50 XP bonus  | Weekly        |
| 30-day streak              | +200 XP bonus | Monthly       |
| Leave a review             | +15 XP        | Per review    |
| Community post             | +10 XP        | Per post      |
| Complete a challenge       | +20 XP        | Per challenge |
| Book a therapy session     | +30 XP        | Per booking   |
| First mood log ever        | +50 XP        | One-time      |

### Level Thresholds

| Level | XP Required | Unlocks                            |
| ----- | ----------- | ---------------------------------- |
| 1     | 0           | Basic mood tracking                |
| 5     | 200         | Anxiety journey (beginner)         |
| 10    | 500         | Achievement badges, streak rewards |
| 15    | 1,000       | Depression journey                 |
| 20    | 2,000       | Advanced exercises                 |
| 30    | 5,000       | All free journeys                  |
| 40    | 10,000      | Premium badge, leaderboard         |
| 50    | 20,000      | Master badge, all content          |

### Tasks

#### Week 6: Core Gamification Engine

| #   | Task                                                                  | Files                                                                 | Est. |
| --- | --------------------------------------------------------------------- | --------------------------------------------------------------------- | ---- |
| 3.1 | Create `GamificationState` model                                      | `lib/features/gamification/models/gamification_state.dart`            | 2h   |
| 3.2 | Create `Achievement` model + predefined list                          | `lib/features/gamification/models/achievement.dart`                   | 2h   |
| 3.3 | Create `Journey` + `Chapter` models                                   | `lib/features/gamification/models/journey.dart`                       | 2h   |
| 3.4 | Create `GamificationRepository` (Firestore CRUD)                      | `lib/features/gamification/repositories/gamification_repository.dart` | 4h   |
| 3.5 | Create `GamificationProvider` (Riverpod StateNotifier)                | `lib/features/gamification/providers/gamification_provider.dart`      | 4h   |
| 3.6 | Create Hive offline cache for gamification state                      | `lib/features/gamification/services/gamification_cache.dart`          | 2h   |
| 3.7 | Add XP earning hooks to existing providers (mood, community, booking) | Multiple providers                                                    | 4h   |
| 3.8 | Create Firestore subcollection + security rules                       | `firestore.rules`                                                     | 1h   |

#### Week 7: Journey System

| #    | Task                                                        | Files                                                            | Est. |
| ---- | ----------------------------------------------------------- | ---------------------------------------------------------------- | ---- |
| 3.9  | Create `JourneyListScreen` (browse available journeys)      | `lib/features/gamification/screens/journey_list_screen.dart`     | 4h   |
| 3.10 | Create `JourneyDetailScreen` (chapters list + progress)     | `lib/features/gamification/screens/journey_detail_screen.dart`   | 4h   |
| 3.11 | Create `ChapterScreen` (lesson/exercise/quiz content)       | `lib/features/gamification/screens/chapter_screen.dart`          | 6h   |
| 3.12 | Create `JourneyRepository` (Firestore CRUD)                 | `lib/features/gamification/repositories/journey_repository.dart` | 3h   |
| 3.13 | Seed initial journeys (Anxiety Beginner, Stress Management) | `functions/seed_journeys.js` or Firestore console                | 4h   |
| 3.14 | Add journey feature gating (free vs premium journeys)       | `lib/features/gamification/providers/journey_provider.dart`      | 2h   |

#### Week 8: UI Widgets + Animations

| #    | Task                                             | Files                                                        | Est. |
| ---- | ------------------------------------------------ | ------------------------------------------------------------ | ---- |
| 3.15 | Create `XPProgressBar` widget (animated fill)    | `lib/features/gamification/widgets/xp_progress_bar.dart`     | 3h   |
| 3.16 | Create `StreakCounter` widget (fire icon + days) | `lib/features/gamification/widgets/streak_counter.dart`      | 2h   |
| 3.17 | Create `LevelUpAnimation` (celebration overlay)  | `lib/features/gamification/widgets/level_up_animation.dart`  | 3h   |
| 3.18 | Create `AchievementBadge` widget                 | `lib/features/gamification/widgets/achievement_badge.dart`   | 2h   |
| 3.19 | Create `AchievementsScreen` (all badges grid)    | `lib/features/gamification/screens/achievements_screen.dart` | 3h   |
| 3.20 | Add gamification summary card to Home Screen     | `lib/features/home/widgets/gamification_card.dart`           | 3h   |
| 3.21 | Add XP indicator to bottom nav bar or app bar    | `lib/core/widgets/xp_indicator.dart`                         | 2h   |

#### Week 9: Integration + CMS + Polish

| #    | Task                                                      | Files                                                    | Est. |
| ---- | --------------------------------------------------------- | -------------------------------------------------------- | ---- |
| 3.22 | Add Journey CMS to Admin Dashboard (create/edit journeys) | `lib/features/admin/screens/journey_cms_screen.dart`     | 4h   |
| 3.23 | Add Journey CMS to Laravel Admin (Filament resource)      | `sanad-admin/app/Filament/Resources/JourneyResource.php` | 4h   |
| 3.24 | Add gamification stats to user profile screen             | `lib/features/profile/widgets/gamification_stats.dart`   | 2h   |
| 3.25 | Localize all gamification strings (AR, EN, FR)            | `lib/core/l10n/`                                         | 3h   |
| 3.26 | Add GoRouter routes for all new screens                   | `lib/routes/app_router.dart`                             | 1h   |
| 3.27 | Integration testing: XP earning, leveling, streaks        | `test/gamification/`                                     | 4h   |
| 3.28 | Performance testing: animations at 60fps                  | Manual testing                                           | 2h   |

**Milestone 3 Deliverables**:

- XP system with 9 earning actions and automatic tracking
- 50-level progression with content unlocks
- Streak system (daily login tracking with bonuses)
- Achievement badges (milestone-based)
- Journey system with chapter-based CBT content
- Animated UI widgets (XP bar, streak counter, level-up celebration)
- Admin CMS for journey management (Flutter + Laravel)
- Feature gating (free vs premium journeys)
- Full localization (AR, EN, FR)

---

## Dependencies & Prerequisites

### Before Starting M1 (Crisis Detection)

- [ ] Existing `chatWithGemini` Cloud Function must be deployed
- [ ] Gemini API key configured in Firebase Functions config
- [ ] FCM working for push notifications

### Before Starting M2 (Hybrid Therapy)

- [ ] M1 (Crisis Detection) complete — crisis is a handoff trigger
- [ ] Therapist Chat system functional
- [ ] At least 1 therapist in Firestore for testing

### Before Starting M3 (Gamification)

- [ ] Mood tracking, community, booking features working
- [ ] M1 complete (XP hooks reference existing providers)

---

## Risk Assessment

| Risk                              | Impact                            | Mitigation                                                                                   |
| --------------------------------- | --------------------------------- | -------------------------------------------------------------------------------------------- |
| Arabic crisis keywords incomplete | Users at risk not detected        | Partner with Arabic-speaking mental health professionals for keyword validation              |
| Gemini false positives on crisis  | Users incorrectly flagged         | Two-tier detection: keywords first, then Gemini confirmation. Admin can dismiss false alerts |
| Gamification feels shallow        | Users disengage                   | Base content on CBT principles (eQuoo model). Focus on meaningful rewards, not just points   |
| Handoff latency                   | User waits too long for therapist | Show estimated wait time. If no therapist available within 15min, offer crisis hotline       |
| XP inflation                      | Levels become meaningless         | Cap daily XP earning at 100 XP. Require diverse actions (not just mood logging)              |

---

## Success Metrics

| Metric                             | Target                                  | Measurement                           |
| ---------------------------------- | --------------------------------------- | ------------------------------------- |
| Crisis response time               | < 5 min from detection to safety screen | Firestore timestamp diff              |
| False positive rate (crisis)       | < 10%                                   | Admin dismissed alerts / total alerts |
| AI-to-Therapist handoff completion | > 80%                                   | Handoffs accepted / handoffs created  |
| User retention (30-day)            | +25% improvement                        | Firebase Analytics                    |
| Daily active users with streaks    | > 40% of active users                   | Firestore gamification collection     |
| Free-to-Premium conversion         | +15% improvement                        | Payment events / total users          |
| Journey completion rate            | > 60% of started journeys               | Chapters completed / chapters total   |

---

## Budget & Resource Estimates

| Item                                     | Cost                                       |
| ---------------------------------------- | ------------------------------------------ |
| Gemini API (crisis + summaries)          | ~$10-30/month (1K users)                   |
| Firebase (new collections)               | Included in existing plan                  |
| Cloud Functions (additional invocations) | ~$5-15/month                               |
| Development time                         | ~9 weeks (1 developer)                     |
| Arabic mental health consultant          | 1-2 sessions for crisis keyword validation |

---

**Document Version**: 1.0
**Created**: February 27, 2026
**Status**: Ready for Implementation
**Next Step**: Begin Milestone 1 (Crisis Detection)
