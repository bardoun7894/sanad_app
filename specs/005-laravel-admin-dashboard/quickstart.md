# Quickstart: Laravel Admin Dashboard (Sanad Admin)

**Branch**: `005-laravel-admin-dashboard` | **Date**: 2026-02-05

## Prerequisites

- PHP 8.2+
- Composer 2.x
- Node.js 18+ & npm (for Vite/Tailwind asset compilation)
- Firebase project with service account JSON key
- Access to the existing Sanad App Firestore database

## 1. Create Laravel Project

```bash
# Create new Laravel 11 project (separate from Flutter repo)
composer create-project laravel/laravel sanad-admin
cd sanad-admin
```

## 2. Install Dependencies

```bash
# Filament v3 (admin panel framework)
composer require filament/filament:"^3.3"

# Firebase Admin SDK
composer require kreait/firebase-php:"^7.0"

# Export: CSV/Excel
composer require maatwebsite/excel:"^3.1"

# Export: PDF
composer require barryvdh/laravel-dompdf:"^3.0"

# Install Filament panel
php artisan filament:install --panels
```

## 3. Environment Configuration

Copy `.env.example` to `.env` and configure:

```env
APP_NAME="Sanad Admin"
APP_URL=http://localhost:8000

# Session/Cache via SQLite (no MySQL needed for app data)
DB_CONNECTION=sqlite
DB_DATABASE=/absolute/path/to/sanad-admin/database/database.sqlite

SESSION_DRIVER=file
CACHE_STORE=file

# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CREDENTIALS=/absolute/path/to/service-account.json

# Gemini API (for AI Assistant)
GEMINI_API_KEY=your-gemini-api-key

# Default locale
APP_LOCALE=en
APP_FALLBACK_LOCALE=en
```

## 4. Firebase Service Account

1. Go to Firebase Console > Project Settings > Service Accounts
2. Click "Generate New Private Key"
3. Save the JSON file as `storage/app/firebase-credentials.json`
4. Set `FIREBASE_CREDENTIALS` in `.env` to the absolute path

## 5. Database Setup (SQLite for sessions/cache only)

```bash
touch database/database.sqlite
php artisan migrate
```

**Note**: SQLite is only used for Laravel sessions and cache. All application data lives in Firestore.

## 6. Create Firebase Config

Create `config/firebase.php`:

```php
<?php

return [
    'project_id' => env('FIREBASE_PROJECT_ID'),
    'credentials' => env('FIREBASE_CREDENTIALS'),
];
```

## 7. Filament Panel Configuration

The Filament admin panel will be configured in `app/Providers/Filament/AdminPanelProvider.php`:

- Panel ID: `admin`
- Path: `/admin`
- Auth guard: `firebase` (custom)
- Dark mode: enabled by default (class-based)
- Colors: Custom primary matching Flutter `AppColors.primary`
- Navigation groups: MAIN, COMMUNICATION, INSIGHTS, SYSTEM
- Locale switcher: EN/AR/FR

## 8. Asset Compilation

```bash
npm install
npm run build
```

For development with hot reload:
```bash
npm run dev
```

## 9. Run Development Server

```bash
php artisan serve
```

Visit `http://localhost:8000/admin` to access the admin panel.

## 10. Login

Use any Firebase Auth account that has `isAdmin: true` in their Firestore `users` document.

---

## Development Workflow

### File Structure Quick Reference

```
app/Filament/Resources/     → CRUD resources (Users, Therapists, Bookings, etc.)
app/Filament/Pages/         → Custom pages (Dashboard, Chat, Analytics, etc.)
app/Filament/Widgets/       → Dashboard widgets (KPIs, Agenda, Alerts, etc.)
app/Models/                 → FirestoreModel base class + entity models
app/Services/               → Firestore service, Auth, Analytics, Risk, etc.
app/Auth/                   → Firebase auth guard + user provider
app/Http/Livewire/          → Real-time components (Chat, Notifications, AI)
resources/views/livewire/   → Blade templates for Livewire components
resources/css/admin.css     → Custom dark theme (Roobin Mood)
lang/{en,ar,fr}/            → Translation files
config/firebase.php         → Firebase project configuration
```

### Key Commands

```bash
# Run tests
php artisan test

# Code style (Laravel Pint)
./vendor/bin/pint

# Clear caches
php artisan optimize:clear

# Create new Filament Resource
php artisan make:filament-resource User

# Create new Filament Page
php artisan make:filament-page Dashboard

# Create new Filament Widget
php artisan make:filament-widget KpiStats
```

### Testing with Firebase Emulator

For local development without touching production Firestore:

```bash
# In a separate terminal, start Firebase Emulator
firebase emulators:start --only firestore,auth

# Set environment variable to use emulator
FIREBASE_EMULATOR_HOST=localhost:8080
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
```

---

## Implementation Order

1. **Foundation**: Laravel project + Filament + Firebase SDK + Auth guard
2. **Dashboard**: Dashboard page + KPI widgets + agenda + risk alerts + activity
3. **Core CRUD**: Users, Therapists, Bookings resources
4. **Payments**: Payments overview + verification workflow
5. **CMS**: Content, Quotes, Challenges resources
6. **Communication**: Chat support + community moderation
7. **Analytics**: Charts + Reports + exports
8. **Settings**: System settings + data management + AI assistant + notifications

Each phase should be independently testable and deployable.
