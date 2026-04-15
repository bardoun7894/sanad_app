# Research: Laravel Admin Dashboard Conversion

**Date**: 2026-02-05
**Branch**: `005-laravel-admin-dashboard`

## Research Items

### R1: Filament v3 with Non-Eloquent Data Sources (Firestore)

**Decision**: Create a `FirestoreModel` base class that implements enough of Laravel's Model contract to satisfy Filament's Resource expectations, plus override `getEloquentQuery()` and `using()` hooks in each Resource.

**Rationale**: Filament v3 is deeply coupled to Eloquent. Rather than fighting this, we create a thin adapter layer:
1. `FirestoreModel` extends a minimal base (not `Illuminate\Database\Eloquent\Model`) but implements `Arrayable`, `JsonSerializable`, and key attribute methods (`getAttribute`, `setAttribute`, `toArray`, `getKey`)
2. Each Filament Resource overrides `getEloquentQuery()` — but since we can't return a real Builder, we instead use Filament's **Custom Pages** approach for complex screens (Chat, Analytics, Moderation) and the **Table Builder** with manual data arrays for list views
3. For CRUD Resources (Users, Therapists, Bookings, etc.), use Filament's `using()` callback on Create/Edit actions to route data through `FirestoreService`

**Alternatives Considered**:
- **Full Eloquent with MySQL sync**: Rejected — adds complexity of bidirectional sync, defeats purpose of "no data migration"
- **Filament v4 beta**: Rejected — still beta, not production-ready
- **Custom non-Filament admin**: Rejected — would lose Filament's built-in tables, forms, widgets, exports

### R2: Firebase Authentication in Laravel

**Decision**: Custom auth guard (`FirebaseGuard`) + custom user provider (`FirebaseUserProvider`) registered via `Auth::extend()` and `Auth::provider()`.

**Rationale**: Laravel's auth system is extensible by design. The flow:
1. Admin submits email/password on login form
2. `FirebaseGuard` calls Firebase Auth REST API to verify credentials
3. On success, fetches user document from Firestore `users` collection
4. Checks `isAdmin: true` field
5. Creates Laravel session with Firebase UID as identifier
6. Subsequent requests use session + Firebase UID to resolve user

**Alternatives Considered**:
- **Firebase Auth JWT tokens**: Rejected — requires client-side Firebase SDK, adds complexity for server-rendered app
- **Duplicate users in MySQL**: Rejected — creates sync burden, violates "no data migration"
- **OAuth2 with Firebase as provider**: Overkill for ~15 admin users with email/password

### R3: Real-time Features (Chat, Notifications, Risk Alerts)

**Decision**: Livewire polling at configurable intervals (5s for chat, 10s for notifications, 30s for risk alerts).

**Rationale**: Firestore real-time listeners are not available in PHP server-side. For ~15 concurrent admin users, polling is efficient and simple:
- Chat: `wire:poll.5s` on the chat panel component
- Notifications: `wire:poll.10s` on the notification bell
- Risk alerts: `wire:poll.30s` on the dashboard widget
- Dashboard KPIs: Loaded on page request, no polling needed (refresh button available)

**Alternatives Considered**:
- **WebSockets (Pusher/Soketi)**: Rejected — requires additional infrastructure for minimal benefit with ~15 users
- **Server-Sent Events (SSE)**: Rejected — PHP not ideal for long-lived connections
- **Firebase Cloud Functions + Webhooks**: Complex setup, adds latency

### R4: Firestore PHP SDK (kreait/firebase-php)

**Decision**: Use `kreait/firebase-php` v7.x for all Firestore and Auth operations.

**Rationale**: This is the most maintained Firebase Admin SDK for PHP:
- Supports Firestore CRUD: `getDocument`, `setDocument`, `updateDocument`, `deleteDocument`
- Supports Firestore queries: `where`, `orderBy`, `limit`, `startAfter` (pagination)
- Supports collection groups (needed for `mood_entries` risk alerts)
- Supports Firebase Auth: `verifyPassword`, `getUser`, `updateUser`
- Supports Firebase Storage: `getSignedUrl` (for receipt images)

**Limitations to Work Around**:
- No real-time listeners (mitigated by Livewire polling)
- Collection group queries may need Firestore composite indexes
- Batch operations limited to 500 per batch

### R5: Export Functionality (CSV/PDF)

**Decision**: Use `maatwebsite/laravel-excel` for CSV exports and `barryvdh/laravel-dompdf` for PDF exports.

**Rationale**: Both are mature Laravel packages with Filament integration:
- Filament has built-in export action support via `ExportAction`
- Laravel Excel handles CSV/XLSX with streaming for large datasets
- DomPDF handles PDF generation for reports
- All data fetched from Firestore → transformed → exported

**Alternatives Considered**:
- **Spatie Laravel Export**: Less flexible for custom Firestore data
- **PhpSpreadsheet directly**: Lower-level, more code needed
- **Browsershot for PDF**: Requires Node.js/Puppeteer, heavier dependency

### R6: Dark Theme (Roobin Mood)

**Decision**: Customize Filament's built-in dark mode via Tailwind CSS configuration and a custom CSS file.

**Rationale**: Filament v3 has native dark mode support. Customization approach:
1. Set `darkMode: 'class'` in Filament panel config (default to dark)
2. Override Filament's color palette in `tailwind.config.js` to match Flutter's `AppColors`
3. Add glassmorphism effects via custom CSS (`backdrop-filter: blur()`, semi-transparent backgrounds)
4. Use Filament's `->color()` method on components for status colors

**Key Color Mappings** (Flutter → Tailwind):
- `AppColors.primary` → `primary` (blue)
- `AppColors.adminGlass` → Custom glass class with `bg-white/5 backdrop-blur-xl`
- `AppColors.statusSuccess` → `success` (green)
- `AppColors.statusWarning` → `warning` (orange)
- `AppColors.statusDanger` → `danger` (red)

### R7: Localization (EN/AR/FR) with RTL

**Decision**: Use Laravel's built-in JSON translation files + Tailwind CSS RTL plugin.

**Rationale**:
1. Create `lang/en.json`, `lang/ar.json`, `lang/fr.json` with all admin panel strings
2. Port translation keys from Flutter's `app_strings_en.dart` / `app_strings_ar.dart` / `app_strings_fr.dart`
3. Use `__('key')` helper in Blade templates
4. Filament supports locale switching natively
5. Tailwind CSS `rtl:` variant for Arabic layout (mirrors padding, margins, flex direction)
6. Set `<html dir="rtl" lang="ar">` dynamically based on selected locale

### R8: AI Assistant (Gemini API)

**Decision**: Create a `GeminiService` that calls the Gemini API directly via HTTP, wrapped in a Livewire component.

**Rationale**:
1. The Flutter app uses `gemini_service.dart` to call Gemini API
2. Port the same prompt structure to PHP
3. Livewire component maintains conversation state in session
4. Dashboard data (KPIs, risk alerts) injected as context for the AI prompt
5. Use `google/generative-ai` PHP client or direct REST API calls

**Alternatives Considered**:
- **OpenAI instead of Gemini**: Rejected — Flutter app already uses Gemini, maintain consistency
- **Pre-computed summaries**: Less interactive, wouldn't support follow-up questions
