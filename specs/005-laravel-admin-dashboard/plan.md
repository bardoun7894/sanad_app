# Implementation Plan: Laravel Admin Dashboard Conversion

**Branch**: `005-laravel-admin-dashboard` | **Date**: 2026-02-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-laravel-admin-dashboard/spec.md`

## Summary

Convert the Sanad App Flutter web admin dashboard to a Laravel 11 + Filament v3 application. The Laravel app connects to the **same Firebase/Firestore backend** via `kreait/firebase-php` Admin SDK, providing full parity with all 30 functional requirements. Filament v3 provides the admin panel framework with custom Firestore-backed Resources, Pages, and Widgets. No data migration required — mobile app unchanged.

## Technical Context

**Language/Version**: PHP 8.2+ / Laravel 11.x
**Primary Dependencies**: Filament v3.3, kreait/firebase-php ^7.0, Livewire 3, Tailwind CSS 3, Chart.js (via Filament Charts), DomPDF/Laravel-Excel (exports)
**Storage**: Firebase Firestore (existing — no MySQL for app data; SQLite for Laravel sessions/cache only)
**Testing**: Pest PHP, Laravel Dusk (browser tests), Firebase Emulator Suite
**Target Platform**: Web (server-rendered, PHP 8.2+, Apache/Nginx)
**Project Type**: Web application (separate repository from Flutter app)
**Performance Goals**: Dashboard <3s load, list pages <2s, chat polling 5-10s interval
**Constraints**: Must use same Firestore collections as Flutter app, no schema changes, RTL support for Arabic
**Scale/Scope**: ~15 admin users, same data volume as existing app, 12 screens + dashboard

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Prime Directive**: This is a NEW separate project (Laravel). Does NOT modify any Flutter code. Zero risk to existing 31 working features.
- [x] **Documentation**: Will update `FEATURES-STATUS.md` and create `CHANGELOG` for the Laravel project.
- [x] **Localization**: Laravel i18n with EN/AR/FR JSON translation files. RTL via Tailwind CSS `rtl:` variants.
- [x] **Security**: Firebase Admin SDK uses service account (bypasses client rules). Admin role verified via `isAdmin: true` field. CSRF protection via Laravel.
- [x] **State Management**: N/A — This is Laravel (server-side), not Flutter. State managed via Livewire/sessions.
- [x] **Routing**: N/A — Laravel uses Filament panel routing, not GoRouter. Named routes maintained.
- [x] **Testing**: Pest PHP for unit/feature tests. Laravel Dusk for critical admin flows. Firebase Emulator for data layer.
- [x] **Performance**: Server-rendered pages load fast. Firestore queries optimized with indexes. Pagination on all list views.
- [x] **Quality Gates**: `php artisan test` passes. `pint` for code style. No Blade compilation errors.
- [x] **Versioning**: Separate `composer.json` version. SemVer from 1.0.0.
- [x] **Error Handling**: All Firestore operations wrapped in try/catch. User-friendly error pages. Logging via Laravel Log.

**Violations Justification**:
- State Management (Riverpod): NOT APPLICABLE — This is a Laravel project, not Flutter. Riverpod doesn't apply.
- Routing (GoRouter): NOT APPLICABLE — Laravel uses its own routing system via Filament panels.
- These are expected divergences since we're building a separate technology stack for the same functionality.

## Project Structure

### Documentation (this feature)

```text
specs/005-laravel-admin-dashboard/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── routes.md        # Route definitions (Filament doesn't use REST API)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (new repository)

```text
sanad-admin/                              # NEW Laravel 11 project
├── app/
│   ├── Filament/
│   │   ├── Pages/
│   │   │   ├── Dashboard.php             # Custom dashboard (KPIs, agenda, alerts, activity)
│   │   │   ├── Analytics.php             # Analytics charts page
│   │   │   ├── Reports.php               # Report templates + recent reports
│   │   │   ├── ChatSupport.php           # Chat list + detail + broadcast
│   │   │   ├── CommunityModeration.php   # Flagged posts moderation
│   │   │   ├── DataManagement.php        # Export/cleanup operations
│   │   │   └── PaymentVerification.php   # Receipt review + approve/reject
│   │   ├── Resources/
│   │   │   ├── UserResource.php          # Users CRUD + subscription management
│   │   │   ├── UserResource/
│   │   │   │   └── Pages/
│   │   │   │       ├── ListUsers.php
│   │   │   │       ├── ViewUser.php      # Tabbed: Overview/Sessions/Assessments/Billing
│   │   │   │       └── EditUser.php
│   │   │   ├── TherapistResource.php     # Therapists with Pending/Approved/Rejected tabs
│   │   │   ├── BookingResource.php       # Bookings with session types + status filters
│   │   │   ├── PaymentResource.php       # Payments overview with stats
│   │   │   ├── ContentResource.php       # CMS articles
│   │   │   ├── QuoteResource.php         # CMS daily quotes
│   │   │   └── ChallengeResource.php     # CMS challenges
│   │   └── Widgets/
│   │       ├── KpiStatsWidget.php        # 4 KPI stat cards with trends
│   │       ├── QuickActionsWidget.php    # 4 shortcut buttons
│   │       ├── WeeklyAgendaWidget.php    # Week view with bookings
│   │       ├── RiskAlertsWidget.php      # Risk level patient list
│   │       ├── RecentActivityWidget.php  # Latest 5 actions
│   │       └── AiAssistantWidget.php     # Gemini-powered insights panel
│   ├── Models/
│   │   ├── FirestoreModel.php            # Base model (Firestore adapter)
│   │   ├── User.php                      # Firestore users collection
│   │   ├── TherapistProfile.php          # Firestore therapist_profiles
│   │   ├── Booking.php                   # Firestore bookings
│   │   ├── Payment.php                   # Firestore payments
│   │   ├── PaymentVerification.php       # Firestore payment_verifications
│   │   ├── ActivityLog.php               # Firestore activity_logs
│   │   ├── ChatThread.php                # Firestore support_chats
│   │   ├── Notification.php              # Firestore notifications
│   │   ├── SystemSetting.php             # Firestore system_settings
│   │   └── MoodEntry.php                 # Firestore mood_entries (read-only)
│   ├── Services/
│   │   ├── FirestoreService.php          # Base Firestore CRUD operations
│   │   ├── FirebaseAuthService.php       # Firebase Auth admin operations
│   │   ├── RiskAlertService.php          # Mood decline detection algorithm
│   │   ├── AnalyticsService.php          # KPI calculations
│   │   ├── ActivityLogService.php        # Admin action logging
│   │   ├── ChatService.php              # Chat thread/message operations
│   │   ├── ReportService.php            # Report generation (PDF/CSV)
│   │   ├── ExportService.php            # List page export (CSV/PDF)
│   │   └── GeminiService.php            # AI assistant (Gemini API)
│   ├── Auth/
│   │   ├── FirebaseGuard.php            # Custom Laravel auth guard
│   │   └── FirebaseUserProvider.php     # Custom user provider for Firebase Auth
│   ├── Http/
│   │   ├── Middleware/
│   │   │   └── VerifyAdminRole.php      # isAdmin: true check
│   │   └── Livewire/
│   │       ├── ChatPanel.php            # Real-time chat component
│   │       ├── NotificationBell.php     # Header notification dropdown
│   │       ├── GlobalSearch.php         # Cross-entity search overlay
│   │       └── AiAssistantPanel.php     # AI chat interface
│   └── Providers/
│       ├── AppServiceProvider.php
│       ├── FilamentServiceProvider.php   # Panel configuration
│       └── FirebaseServiceProvider.php   # Firebase SDK binding
├── config/
│   ├── firebase.php                     # Firebase project config
│   └── filament.php                     # Filament panel config
├── lang/
│   ├── en/                              # English translations
│   ├── ar/                              # Arabic translations
│   └── fr/                              # French translations
├── resources/
│   ├── views/
│   │   ├── filament/
│   │   │   └── pages/                   # Custom Blade views
│   │   └── livewire/
│   │       ├── chat-panel.blade.php
│   │       ├── notification-bell.blade.php
│   │       └── ai-assistant.blade.php
│   └── css/
│       └── admin.css                    # Custom dark theme (Roobin Mood)
├── routes/
│   └── web.php                          # Minimal (Filament handles admin routes)
├── tests/
│   ├── Feature/
│   │   ├── Auth/
│   │   │   └── FirebaseAuthTest.php
│   │   ├── Resources/
│   │   │   ├── UserResourceTest.php
│   │   │   ├── TherapistResourceTest.php
│   │   │   └── BookingResourceTest.php
│   │   └── Pages/
│   │       ├── DashboardTest.php
│   │       └── ChatSupportTest.php
│   └── Unit/
│       ├── Services/
│       │   ├── FirestoreServiceTest.php
│       │   ├── RiskAlertServiceTest.php
│       │   └── AnalyticsServiceTest.php
│       └── Models/
│           └── FirestoreModelTest.php
├── database/
│   └── migrations/                      # Only for sessions/cache tables (SQLite)
├── .env.example                         # Firebase credentials template
├── composer.json
├── tailwind.config.js                   # RTL + dark theme config
└── vite.config.js
```

**Structure Decision**: Single web application project. Filament v3 handles all admin panel routing, resources, and pages. No separate API layer needed — Filament pages interact directly with Firestore via service classes. SQLite used only for Laravel's session/cache storage (no MySQL needed).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| FirestoreModel adapter | Filament v3 expects Eloquent models | Direct Firestore queries in each Resource would duplicate CRUD logic across 7+ resources |
| Custom Auth Guard | Firebase Auth not native to Laravel | Standard Eloquent auth would require duplicating user data in MySQL |
| Livewire polling for chat | Firestore real-time streams not available in PHP | WebSockets would add infrastructure complexity (Pusher/Soketi) for ~15 admin users |
