# Tasks: Laravel Admin Dashboard Conversion

**Input**: Design documents from `/specs/005-laravel-admin-dashboard/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/routes.md, quickstart.md

**Tests**: Not explicitly requested in spec. Tests are omitted from task phases. Add test tasks per story if TDD is desired.

**Organization**: Tasks grouped by user story (12 stories) to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1-US12)
- File paths are relative to `sanad-admin/` project root

## Path Conventions

This is a single Laravel 11 web application:
- `app/` — PHP application code
- `config/` — Configuration files
- `resources/` — Blade views, CSS, JS
- `lang/` — Translation files
- `routes/` — Route definitions
- `tests/` — Test files

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create Laravel project, install all dependencies, configure environment

- [x] T001 Create Laravel 11 project via `composer create-project laravel/laravel sanad-admin` and initialize git repository
- [x] T002 Install Filament v3.3 via `composer require filament/filament:"^3.3"` and run `php artisan filament:install --panels`
- [x] T003 [P] Install Firebase SDK via `composer require kreait/firebase-php:"^7.0"`
- [x] T004 [P] Install export packages via `composer require maatwebsite/excel:"^3.1" barryvdh/laravel-dompdf:"^3.0"`
- [x] T005 [P] Create `config/firebase.php` with `project_id` and `credentials` env bindings
- [x] T006 [P] Create `.env.example` with Firebase credentials template (FIREBASE_PROJECT_ID, FIREBASE_CREDENTIALS, GEMINI_API_KEY, APP_LOCALE)
- [x] T007 Configure SQLite database for sessions/cache in `.env` and run `php artisan migrate`
- [x] T008 [P] Configure `tailwind.config.js` with RTL plugin, dark theme colors matching Flutter AppColors (primary blue, glass bg-white/5 backdrop-blur-xl, success green, warning orange, danger red)
- [x] T009 [P] Create `resources/css/admin.css` with Roobin Mood dark theme glassmorphism overrides (backdrop-filter: blur, semi-transparent backgrounds)
- [x] T010 Configure `vite.config.js` to include admin.css and run `npm install && npm run build`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can begin

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T011 Create `app/Services/FirestoreService.php` — base Firestore CRUD wrapper using kreait/firebase-php: getDocument, setDocument, updateDocument, deleteDocument, queryCollection, queryCollectionGroup, paginateCollection
- [x] T012 Create `app/Providers/FirebaseServiceProvider.php` — register Firebase Factory singleton, bind FirestoreService, bind Firebase Auth in service container
- [x] T013 [P] Create `app/Models/FirestoreModel.php` — base model implementing Arrayable, JsonSerializable with getAttribute, setAttribute, toArray, getKey, fill, exists, getTable (returns collection name)
- [x] T014 [P] Create `app/Auth/FirebaseGuard.php` — custom Laravel auth guard: verify email/password via Firebase Auth REST API, fetch user document from Firestore `users` collection, check `role == 'admin'`, create session with Firebase UID
- [x] T015 [P] Create `app/Auth/FirebaseUserProvider.php` — custom user provider: retrieveById fetches from Firestore `users/{uid}`, retrieveByCredentials calls Firebase Auth verifyPassword
- [x] T016 Register custom auth guard and provider in `config/auth.php` — add `firebase` guard (driver: firebase, provider: firebase_users) and `firebase_users` provider (driver: firebase)
- [x] T017 Register FirebaseGuard via `Auth::extend('firebase')` and FirebaseUserProvider via `Auth::provider('firebase_users')` in `app/Providers/FirebaseServiceProvider.php` (moved from AppServiceProvider for better organization)
- [x] T018 [P] Create `app/Http/Middleware/VerifyAdminRole.php` — check authenticated user has `role == 'admin'`, redirect to login with error if not
- [x] T019 [P] Create `app/Services/ActivityLogService.php` — log admin actions to Firestore `activity_logs` collection with type, user_id, user_name, description, timestamp, metadata fields
- [x] T020 Configure Filament AdminPanelProvider in `app/Providers/Filament/AdminPanelProvider.php` — set panel ID 'admin', path '/admin', auth guard 'firebase', default dark mode (class-based), primary color, navigation groups (MAIN, COMMUNICATION, INSIGHTS, SYSTEM), sidebar labels per FR-025, breadcrumbs enabled (FR-026)
- [x] T021 [P] Create base translation files: `lang/en.json`, `lang/ar.json`, `lang/fr.json` with admin panel strings ported from Flutter's app_strings_en.dart / app_strings_ar.dart / app_strings_fr.dart (FR-012)
- [x] T022 [P] Configure locale switching in Filament panel (FR-012) and RTL HTML dir attribute for Arabic in base layout

**Checkpoint**: Foundation ready — Firebase connected, auth working, Filament panel accessible, dark theme applied, i18n configured. User story implementation can now begin.

---

## Phase 3: User Story 1 — Admin Logs In and Views Dashboard (Priority: P1) — MVP

**Goal**: Admin authenticates with Firebase credentials and sees the clinic overview dashboard with KPIs, quick actions, weekly agenda, risk alerts, and recent activity.

**Independent Test**: Log in with admin Firebase account → verify 4 KPI cards display data, weekly agenda shows bookings, risk alerts list patients, recent activity shows 5 latest actions, quick actions navigate correctly.

**FRs**: FR-001, FR-002, FR-003, FR-004, FR-005, FR-027

### Models

- [x] T023 [P] [US1] Create `app/Models/User.php` extending FirestoreModel — map to `users` collection with all fields from data-model E1 (email, display_name, role, is_premium, subscription_status, created_at, last_login, etc.)
- [x] T024 [P] [US1] Create `app/Models/Booking.php` extending FirestoreModel — map to `bookings` collection with fields from data-model E3 (therapist_id, client_id, client_name, scheduled_time, duration_minutes, session_type, status, amount)
- [x] T025 [P] [US1] Create `app/Models/ActivityLog.php` extending FirestoreModel — map to `activity_logs` collection with fields from data-model E6 (type, user_id, user_name, description, timestamp, metadata)
- [x] T026 [P] [US1] Create `app/Models/MoodEntry.php` extending FirestoreModel — map to `users/{userId}/mood_entries` subcollection (collectionGroup) with fields from data-model E11 (mood, date, note)

### Services

- [x] T027 [US1] Create `app/Services/AnalyticsService.php` — KPI calculations: countActiveUsers (last_login within 30 days), countCriticalFlags (assessments with risk_level in ['high','critical']), countTodaySessions (bookings today), calculateEarnings (payments completed this month) with trend percentages
- [x] T028 [US1] Create `app/Services/RiskAlertService.php` — mood decline detection: query last 7 days of mood_entries via collectionGroup, group by user, calculate average mood score, assign risk levels (critical >= 3.5, high >= 2.5, moderate >= 1.5, low < 1.5)

### Widgets

- [x] T029 [P] [US1] Create `app/Filament/Widgets/KpiStatsWidget.php` — 4 stat cards (Active Users, Critical Flags, Today's Sessions, Earnings) using AnalyticsService, display count + trend percentage (FR-002)
- [x] T030 [P] [US1] Create `app/Filament/Widgets/QuickActionsWidget.php` — 4 action buttons: New Patient → /admin/users, Schedule Session → /admin/appointments, Add Clinician → /admin/clinicians, Create Invoice → /admin/billing (FR-027)
- [x] T031 [P] [US1] Create `app/Filament/Widgets/WeeklyAgendaWidget.php` — query bookings for current week, group by day, display time + client name + therapist + session type icon (FR-003)
- [x] T032 [P] [US1] Create `app/Filament/Widgets/RiskAlertsWidget.php` — display risk level patient list using RiskAlertService, wire:poll.30s for near-real-time updates, "All clear" empty state (FR-004)
- [x] T033 [P] [US1] Create `app/Filament/Widgets/RecentActivityWidget.php` — query latest 5 activity_logs ordered by timestamp DESC, display type icon + user name + description + time ago (FR-005)

### Pages

- [x] T034 [US1] Create `app/Filament/Pages/Dashboard.php` — custom dashboard page registering all 5 widgets (KpiStats, QuickActions, WeeklyAgenda, RiskAlerts, RecentActivity) in a responsive grid layout
- [x] T035 [US1] Customize Filament login page to use FirebaseGuard for authentication with email/password form (FR-001)

**Checkpoint**: MVP complete — admin can log in, view dashboard with live Firestore data, navigate via quick actions.

---

## Phase 4: User Story 2 — Admin Manages Users (Priority: P1)

**Goal**: Searchable/filterable user list, tabbed user profile (Overview/Sessions/Assessments/Billing), role editing, subscription management.

**Independent Test**: Navigate to Users → search by name → filter by role → open user profile → switch tabs → assign subscription with 30d duration → revoke subscription.

**FRs**: FR-006, FR-011, FR-018, FR-022, FR-030

### Models

- [x] T036 [P] [US2] Create `app/Models/Payment.php` extending FirestoreModel — map to `payments` collection with fields from data-model E4
- [x] T037 [P] [US2] Create `app/Models/SubscriptionProduct.php` extending FirestoreModel — map to `subscription_products` collection with fields from data-model E13
- [x] T037b [P] [US2] Create `app/Models/Assessment.php` extending FirestoreModel — map to `assessments` collection with fields from data-model E12 (needed by ViewUser Assessments tab)

### Services

- [x] T038 [US2] Create `app/Services/ExportService.php` — generic export service using maatwebsite/excel for CSV and barryvdh/laravel-dompdf for PDF, accepts collection name + data array + column mapping (FR-030)

### Resource

- [x] T039 [US2] Create `app/Filament/Resources/UserResource.php` — configure table columns (name, email, role, subscription_status, created_at), search by name/email, filters (role, subscription_status), navigation group 'MAIN', label 'Users'
- [x] T040 [US2] Create `app/Filament/Resources/UserResource/Pages/ListUsers.php` — list page with Firestore query via FirestoreService, pagination using startAfter cursor, CSV/PDF export actions (FR-030)
- [x] T041 [US2] Create `app/Filament/Resources/UserResource/Pages/ViewUser.php` — tabbed view: Overview (profile data), Sessions (user's bookings), Assessments (user's assessment history from `assessments` collection), Billing (payment history + subscription info) (FR-022)
- [x] T042 [US2] Create `app/Filament/Resources/UserResource/Pages/EditUser.php` — edit form for role and status fields, plus header actions: Suspend Account (sets status to 'suspended' + logs activity) and Delete Account (confirmation modal + soft-delete or hard-delete from Firestore + logs activity)
- [x] T043 [US2] Implement subscription management actions on ViewUser: Assign Subscription modal (plan dropdown from subscription_products + duration select 7d/30d/90d/365d) and Revoke Subscription action — both update user document + create payment record + log to activity_logs (FR-018)

### Header Components

- [x] T044 [US2] Create `app/Http/Livewire/GlobalSearch.php` + `resources/views/livewire/global-search.blade.php` — search across users, therapists, bookings collections with debounced input, result grouping by entity type, click to navigate (FR-011)
- [x] T045 [US2] Register GlobalSearch as Filament header widget in AdminPanelProvider

**Checkpoint**: User management fully functional — CRUD, search, filters, tabbed profile, subscription management, exports.

---

## Phase 5: User Story 3 — Admin Manages Therapists (Priority: P1)

**Goal**: Therapist list with Pending/Approved/Rejected tabs, approve/reject actions, detail view.

**Independent Test**: Navigate to Clinicians → view Pending tab → approve a therapist → verify status changed → switch to Rejected tab → reject a therapist with reason.

**FRs**: FR-006, FR-020, FR-030

### Models

- [x] T046 [P] [US3] Create `app/Models/TherapistProfile.php` extending FirestoreModel — map to `therapists` collection with fields from data-model E2 (specialties, approval_status, rating, rejection_reason, etc.)

### Resource

- [x] T047 [US3] Create `app/Filament/Resources/TherapistResource.php` — table columns (name, title, specialties badges, rating, session_price, approval_status), filter by specialty, navigation group 'MAIN', label 'Clinicians', slug 'clinicians'
- [x] T048 [US3] Create `app/Filament/Resources/TherapistResource/Pages/ListTherapists.php` — three tabs (Pending Review, Approved, Rejected) filtering by approval_status, approve action (sets approved_at, approved_by, updates users doc therapist_status), reject action with reason modal (sets rejection_reason), CSV/PDF export (FR-020, FR-030)
- [x] T049 [US3] Create `app/Filament/Resources/TherapistResource/Pages/ViewTherapist.php` — detail view showing all therapist fields, qualifications, languages, session types, review stats

**Checkpoint**: Therapist management fully functional — tabbed workflow, approve/reject actions, exports.

---

## Phase 6: User Story 4 — Admin Manages Bookings (Priority: P1)

**Goal**: Booking list with status/session type tabs, date range filter, cancel with reason.

**Independent Test**: Navigate to Appointments → filter by Upcoming tab → filter by Video session type → set date range → cancel a booking with reason → verify Firestore updated.

**FRs**: FR-006, FR-021, FR-030

### Resource

- [x] T050 [US4] Create `app/Filament/Resources/BookingResource.php` — table columns (client_name, therapist, scheduled_time, duration, session_type icon, status badge, amount), navigation group 'MAIN', label 'Appointments', slug 'appointments'
- [x] T051 [US4] Create `app/Filament/Resources/BookingResource/Pages/ListBookings.php` — four status tabs (All, Upcoming, Completed, Cancelled), session type filter (Video/Chat/Audio/In Person) (FR-021), date range filter, search by client name, cancel action with reason modal (updates status + cancellation_reason + cancelled_at + logs to activity_logs), CSV/PDF export (FR-030)
- [x] T052 [US4] Create `app/Filament/Resources/BookingResource/Pages/ViewBooking.php` — detail view with all booking fields, client info, therapist info, session type, status timeline

**Checkpoint**: Booking management fully functional — status tabs, session type filtering, cancellation workflow, exports.

---

## Phase 7: User Story 5 — Admin Manages Payments and Verifications (Priority: P2)

**Goal**: Payments Overview with 6 stat cards + transaction list. Separate Payment Verification page with approve/reject workflow.

**Independent Test**: Navigate to Billing → verify 6 stat cards → filter transactions by Pending → navigate to Verification → approve a payment → confirm user subscription activated.

**FRs**: FR-006, FR-007, FR-030

### Models

- [x] T053 [P] [US5] Create `app/Models/PaymentVerification.php` extending FirestoreModel — map to `payment_verifications` collection with fields from data-model E5

### Resource & Page

- [x] T054 [US5] Create `app/Filament/Resources/PaymentResource.php` — table columns (user_email, amount, currency, status badge, payment_method, created_at, gateway_transaction_id), navigation group 'SYSTEM', label 'Billing', slug 'billing'
- [x] T055 [US5] Create `app/Filament/Resources/PaymentResource/Pages/ListPayments.php` — 6 stat cards header (Total Revenue, This Month Revenue, Average Transaction, Free-to-Premium Conversion Rate, Payment Success Rate, Verification Approval Rate), four tabs (All, Completed, Pending, Failed), CSV/PDF export (FR-030)
- [x] T056 [US5] Create `app/Filament/Pages/PaymentVerification.php` — custom Filament page listing pending payment_verifications with receipt image viewer (Firebase Storage signed URL), approve action (updates verification status + activates user subscription + creates payment record + logs activity), reject action with reason modal (FR-007)

**Checkpoint**: Payment management fully functional — overview stats, transaction list, verification workflow with subscription activation.

---

## Phase 8: User Story 6 — Admin Manages CMS Content (Priority: P2)

**Goal**: Full CRUD for articles/exercises/videos, daily quotes, and daily challenges.

**Independent Test**: Navigate to Content → create a new article → edit it → navigate to Quotes → create a quote → navigate to Challenges → delete a challenge → verify all changes in Firestore.

**FRs**: FR-006

### Models

- [x] T057 [P] [US6] Create `app/Models/AppContent.php` extending FirestoreModel — map to `content` collection with fields from data-model E10b
- [x] T058 [P] [US6] Create `app/Models/DailyQuote.php` extending FirestoreModel — map to `daily_quotes` collection with fields from data-model E10a
- [x] T059 [P] [US6] Create `app/Models/DailyChallenge.php` extending FirestoreModel — map to `daily_challenges` collection with fields from data-model E10c

### Resources

- [x] T060 [P] [US6] Create `app/Filament/Resources/ContentResource.php` — CRUD for articles/exercises/videos, form fields (title, category, type select, content_text richtext, media_url, link_url, is_published toggle), table columns (title, category, type badge, is_published), navigation group 'SYSTEM' under 'Content'
- [x] T061 [P] [US6] Create `app/Filament/Resources/QuoteResource.php` — CRUD for daily quotes, form fields (text textarea, author, category, publish_date datepicker, is_active toggle), table columns (text truncated, author, category, is_active), navigation group 'SYSTEM' under 'Content'
- [x] T062 [P] [US6] Create `app/Filament/Resources/ChallengeResource.php` — CRUD for daily challenges, form fields (title, title_en, description, description_en, type select from ChallengeType enum, duration_minutes, order, publish_date, is_active toggle), table columns (title, type badge, duration, order, is_active), navigation group 'SYSTEM' under 'Content'

**Checkpoint**: CMS management fully functional — all 3 content types with full CRUD.

---

## Phase 9: User Story 7 — Admin Uses Chat Support with Broadcast (Priority: P2)

**Goal**: Chat thread list with stats, message detail with real-time polling, send replies, new chat, broadcast to all.

**Independent Test**: Navigate to Support Chat → view stats header → open a conversation → send a reply → verify in Firestore → start new chat by searching user → send broadcast message.

**FRs**: FR-008, FR-019

### Models

- [x] T063 [P] [US7] Create `app/Models/ChatThread.php` extending FirestoreModel — map to `support_chats` collection with fields from data-model E7

### Services

- [x] T064 [US7] Create `app/Services/ChatService.php` — getThreads (ordered by last_message_time), getMessages (subcollection query), sendMessage (create in messages subcollection + update thread last_message/timestamp + increment unread_count_user), createThread (create support_chats doc for user), broadcastMessage (iterate all threads + send message with is_broadcast: true) (FR-019)

### Page & Components

- [x] T065 [US7] Create `app/Http/Livewire/ChatPanel.php` + `resources/views/livewire/chat-panel.blade.php` — split view: thread list (left) + message detail (right), wire:poll.5s for real-time updates, message input with send button, stats header (total conversations, unread, urgent, avg response time)
- [x] T066 [US7] Create `app/Filament/Pages/ChatSupport.php` — custom Filament page embedding ChatPanel Livewire component, actions for New Chat (user search modal) and Broadcast All (message input modal with confirmation)

**Checkpoint**: Chat support fully functional — thread list, real-time messaging, new chat, broadcast.

---

## Phase 10: User Story 8 — Admin Moderates Community (Priority: P2)

**Goal**: View flagged community posts, take moderation actions (approve, remove, warn).

**Independent Test**: Navigate to Community → view flagged posts (report_count > 0) → remove a flagged post → verify in Firestore.

**FRs**: FR-009

### Models

- [x] T067 [P] [US8] Create `app/Models/CommunityPost.php` extending FirestoreModel — map to `posts` collection with fields from data-model E14

### Page

- [x] T068 [US8] Create `app/Filament/Pages/CommunityModeration.php` — custom Filament page querying posts with report_count > 0 ordered by report_count DESC, display post content + author + category + report count + reactions, actions: Approve (reset report_count to 0), Remove (delete or mark removed), Warn User (send notification to author)

**Checkpoint**: Community moderation fully functional — flagged post list, moderation actions.

---

## Phase 11: User Story 11 — Admin Receives and Manages Notifications (Priority: P2)

**Goal**: Notification bell in header with unread badge, dropdown with typed notifications, mark read, mark all read, navigate to action routes.

**Independent Test**: Verify bell shows unread count badge → open dropdown → click notification to mark read and navigate → use Mark All Read.

**FRs**: FR-017

### Models

- [x] T069 [P] [US11] Create `app/Models/Notification.php` extending FirestoreModel — map to `notifications` collection with fields from data-model E8

### Components

- [x] T070 [US11] Create `app/Http/Livewire/NotificationBell.php` + `resources/views/livewire/notification-bell.blade.php` — bell icon with unread count badge (capped at 9+), wire:poll.10s, dropdown panel showing recent notifications grouped by type (booking, message, community, mood, therapist, payment, system), click to mark read + navigate to action_route, Mark All Read button
- [x] T071 [US11] Register NotificationBell as Filament header widget in AdminPanelProvider

**Checkpoint**: Notification system fully functional — real-time badge, dropdown, mark read, navigation.

---

## Phase 12: User Story 9 — Admin Views Analytics and Generates Reports (Priority: P3)

**Goal**: Analytics dashboards with charts. Report generation from 6 templates with PDF/CSV download.

**Independent Test**: Navigate to Analytics → verify charts display → navigate to Reports → generate Monthly Summary → download PDF → verify data accuracy.

**FRs**: FR-010, FR-028, FR-029

### Models

- [x] T071b [P] [US9] Create `app/Models/Review.php` extending FirestoreModel — map to `reviews` collection with fields from data-model E16 (needed by AnalyticsService.getTherapistRatings). Also reads aggregated data from `therapist_profiles` collection for rating summaries.

### Services

- [x] T072 [P] [US9] Extend `app/Services/AnalyticsService.php` — add methods: getTherapistRatings (from reviews + therapist_profiles collections), getSessionVolume (bookings over time), getRevenueTrends (payments over time), getNoShowRate (bookings with no_show status), getSessionTypeDistribution, getClinicianPerformance (bookings + ratings per therapist)
- [x] T073 [P] [US9] Create `app/Services/ReportService.php` — 6 report templates: Monthly Summary (KPIs + trends), Patient Activity (user engagement metrics), Clinician Report (therapist performance), Financial Report (revenue + payments), Risk Assessment (mood analysis + risk levels), Custom Report (configurable parameters). Generate PDF via DomPDF and CSV via Laravel Excel.

### Pages

- [x] T074 [US9] Create `app/Filament/Pages/Analytics.php` — custom Filament page with Chart.js charts: therapist ratings distribution, session volume over time, revenue trends, no-show rates, session type distribution, clinician performance comparison (FR-010)
- [x] T075 [US9] Create `app/Filament/Pages/Reports.php` — custom Filament page showing 6 report template cards with Generate button, Recent Reports list (stored locally or in Firestore) with download (PDF/CSV) and preview actions (FR-028, FR-029)

**Checkpoint**: Analytics and reports fully functional — 6 chart types, 6 report templates, download in PDF/CSV.

---

## Phase 13: User Story 10 — Admin Configures Settings and Manages Data (Priority: P3)

**Goal**: Settings page with 4 specific controls (Maintenance Mode, Therapist Applications, Min App Version, Support Email). Data management for export/cleanup.

**Independent Test**: Navigate to Settings → toggle Maintenance Mode → edit Min App Version to "2.0.0" → verify in Firestore. Navigate to Data Management → export data.

**FRs**: FR-016, FR-024

### Models

- [x] T076 [P] [US10] Create `app/Models/SystemSetting.php` extending FirestoreModel — map to `system_settings/config` single document with fields from data-model E9 (maintenance_mode, enable_therapist_application, min_app_version, contact_email)

### Pages

- [x] T077 [US10] Create `app/Filament/Pages/Settings.php` — custom Filament page (or Filament Settings Plugin) with form: Maintenance Mode toggle, Therapist Applications toggle, Minimum App Version text input with semver validation, Support Email text input with email validation. Save action writes to `system_settings/config` document + logs to activity_logs (FR-016)
- [x] T078 [US10] Create `app/Filament/Pages/DataManagement.php` — custom Filament page with export actions (export users CSV/PDF, export bookings, export payments) and cleanup operations (archive old data) using ExportService (FR-024)

**Checkpoint**: Settings and data management fully functional — 4 system settings persisted, data export working.

---

## Phase 14: User Story 12 — Admin Uses AI Assistant (Priority: P3)

**Goal**: AI assistant panel on dashboard right side that generates clinic data summaries with insights and supports follow-up questions.

**Independent Test**: Toggle AI panel → click Generate Summary → read insights → ask follow-up question → verify contextual response.

**FRs**: FR-023

### Models

- [x] T079 [P] [US12] Create `app/Models/AdminAIChat.php` extending FirestoreModel — map to `admin_ai_chats` collection with subcollection `messages` per data-model E15

### Services

- [x] T080 [US12] Create `app/Services/GeminiService.php` — call Gemini API via HTTP (port prompt structure from Flutter's gemini_service.dart), accept dashboard context (KPIs, risk alerts, session data, revenue) as prompt context, maintain conversation history from Firestore subcollection, stream response for better UX (FR-023)

### Components

- [x] T081 [US12] Create `app/Http/Livewire/AiAssistantPanel.php` + `resources/views/livewire/ai-assistant.blade.php` — right panel toggle, Generate Summary button that injects current dashboard data as AI context, conversation interface with message history, follow-up question input
- [x] T082 [US12] Create `app/Filament/Widgets/AiAssistantWidget.php` — dashboard widget that toggles the AI assistant panel (right side), registered in Dashboard page

**Checkpoint**: AI assistant fully functional — summary generation, contextual follow-up, conversation persistence.

---

## Phase 15: Polish & Cross-Cutting Concerns

**Purpose**: Improvements affecting multiple user stories

### Error Handling & Edge Cases

- [x] T083 [P] Add Firestore connection failure handling with user-friendly retry message across all services (SC-O01)
- [x] T084 [P] Add session expiry handling — redirect to login with "session expired" message
- [x] T085 [P] Handle concurrent payment verification — check status before approve/reject, show "already processed" if conflict (SC-O03)
- [x] T086 [P] Handle malformed Firestore data — graceful fallbacks with "N/A" or "-" for missing fields
- [x] T087 [P] Add empty state messages: "No results found" for search, "All clear" for risk alerts, "No flagged posts" for moderation

### Responsiveness

- [x] T088 Configure responsive breakpoints in Filament: desktop (1024px+), tablet (768-1023px), mobile (<768px) (FR-014)

### Localization Completion

- [x] T089 [P] Complete all translation strings in `lang/en.json` for all 12 screens + widgets + actions
- [x] T090 [P] Complete all translation strings in `lang/ar.json` (Arabic) with RTL-aware labels
- [x] T091 [P] Complete all translation strings in `lang/fr.json` (French)
- [x] T092 Verify RTL layout for Arabic — test sidebar, tables, forms, modals, breadcrumbs (FR-012)

### Performance & Optimization

- [x] T093 [P] Add Firestore query pagination on all list pages with cursor-based pagination using startAfter (SC-P02)
- [x] T094 [P] Optimize dashboard queries — parallel Firestore requests for KPIs, cache results for 60s (SC-P01)
- [x] T095 Add required Firestore composite indexes per data-model.md index table (13 indexes)

### Documentation & Compliance

- [x] T096 [P] Create `docs/CHANGELOG-2026-02.md` with Laravel admin dashboard changes
- [x] T097 [P] Update `docs/FEATURES-STATUS.md` to note Laravel admin dashboard as new project
- [x] T098 Update `composer.json` version to 1.0.0 following SemVer

### Code Quality

- [x] T099 Run `./vendor/bin/pint` for code style fixes across all PHP files (85 files, 73 style issues fixed via Docker)
- [x] T100 Verify all Blade templates compile without errors (`php artisan view:cache` — PASSED via Docker)
- [x] T101 Final smoke test — route:list (36 routes), config:cache, view:cache, artisan about — all PASSED via Docker

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup ──────────────────────► (no dependencies)
Phase 2: Foundational ──────────────► depends on Phase 1
Phase 3-14: User Stories ───────────► ALL depend on Phase 2 completion
Phase 15: Polish ───────────────────► depends on all desired stories complete
```

### User Story Dependencies

| Story | Phase | Priority | Depends On | Can Parallel With |
|-------|-------|----------|------------|-------------------|
| US1: Dashboard | Phase 3 | P1 | Phase 2 only | — (MVP, do first) |
| US2: Users | Phase 4 | P1 | Phase 2 | US3, US4 |
| US3: Therapists | Phase 5 | P1 | Phase 2 | US2, US4 |
| US4: Bookings | Phase 6 | P1 | Phase 2 | US2, US3 |
| US5: Payments | Phase 7 | P2 | Phase 2 | US6, US7, US8, US11 |
| US6: CMS | Phase 8 | P2 | Phase 2 | US5, US7, US8, US11 |
| US7: Chat | Phase 9 | P2 | Phase 2 | US5, US6, US8, US11 |
| US8: Community | Phase 10 | P2 | Phase 2 | US5, US6, US7, US11 |
| US11: Notifications | Phase 11 | P2 | Phase 2 | US5, US6, US7, US8 |
| US9: Analytics | Phase 12 | P3 | Phase 2 (uses same Firestore data) | US10, US12 |
| US10: Settings | Phase 13 | P3 | Phase 2 | US9, US12 |
| US12: AI Assistant | Phase 14 | P3 | Phase 2 | US9, US10 |

### Within Each User Story

1. Models (parallelizable with [P])
2. Services (depend on models)
3. Resources/Pages/Widgets (depend on services)
4. Integration & actions (depend on resources)

### Parallel Opportunities

**Phase 1**: T003, T004, T005, T006 can run in parallel after T002
**Phase 2**: T013, T014, T015, T018, T019, T021, T022 can run in parallel after T011, T012
**Phase 3 models**: T023, T024, T025, T026 all in parallel
**Phase 3 widgets**: T029, T030, T031, T032, T033 all in parallel (after services)
**P1 stories**: US2, US3, US4 can run fully in parallel after US1 (MVP)
**P2 stories**: US5, US6, US7, US8, US11 all fully parallel
**P3 stories**: US9, US10, US12 all fully parallel
**Phase 15**: Most polish tasks are parallelizable

---

## Parallel Example: Phase 3 (User Story 1 — Dashboard MVP)

```bash
# Launch all models in parallel:
Task: "Create User model in app/Models/User.php"
Task: "Create Booking model in app/Models/Booking.php"
Task: "Create ActivityLog model in app/Models/ActivityLog.php"
Task: "Create MoodEntry model in app/Models/MoodEntry.php"

# Then services (sequentially, depend on models):
Task: "Create AnalyticsService in app/Services/AnalyticsService.php"
Task: "Create RiskAlertService in app/Services/RiskAlertService.php"

# Then all widgets in parallel:
Task: "Create KpiStatsWidget in app/Filament/Widgets/KpiStatsWidget.php"
Task: "Create QuickActionsWidget in app/Filament/Widgets/QuickActionsWidget.php"
Task: "Create WeeklyAgendaWidget in app/Filament/Widgets/WeeklyAgendaWidget.php"
Task: "Create RiskAlertsWidget in app/Filament/Widgets/RiskAlertsWidget.php"
Task: "Create RecentActivityWidget in app/Filament/Widgets/RecentActivityWidget.php"

# Then Dashboard page (depends on widgets):
Task: "Create Dashboard page in app/Filament/Pages/Dashboard.php"
```

---

## Parallel Example: P2 Stories (all independent)

```bash
# After Phase 2 foundation is complete, launch all P2 stories in parallel:
# Developer A: User Story 5 (Payments)
# Developer B: User Story 6 (CMS)
# Developer C: User Story 7 (Chat)
# Developer D: User Story 8 (Community)
# Developer E: User Story 11 (Notifications)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T010)
2. Complete Phase 2: Foundational (T011-T022) — **CRITICAL: blocks all stories**
3. Complete Phase 3: User Story 1 — Dashboard (T023-T035)
4. **STOP and VALIDATE**: Login → Dashboard with live data → Quick actions navigate
5. Deploy/demo if ready — **this is the MVP**

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1 (Dashboard) → Test → Deploy → **MVP!**
3. US2 + US3 + US4 (Users, Therapists, Bookings) → Test → Deploy → **Core CRUD**
4. US5 + US6 + US7 + US8 + US11 (Payments, CMS, Chat, Community, Notifications) → Test → Deploy → **Full P2**
5. US9 + US10 + US12 (Analytics, Settings, AI) → Test → Deploy → **Complete**
6. Polish → Final release → **v1.0.0**

### Suggested MVP Scope

**Phase 1 + Phase 2 + Phase 3 (User Story 1)** = 35 tasks

This gives a working admin dashboard with:
- Firebase authentication
- Dashboard with KPIs, agenda, risk alerts, activity feed
- Quick action navigation
- Dark theme
- 3-language support scaffold

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- All file paths relative to `sanad-admin/` project root
- Each story is independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Total: 101 tasks across 15 phases
