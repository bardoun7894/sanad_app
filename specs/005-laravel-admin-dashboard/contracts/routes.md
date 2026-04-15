# Route Contracts: Laravel Admin Dashboard

**Branch**: `005-laravel-admin-dashboard` | **Date**: 2026-02-05
**Note**: Filament v3 auto-generates routes for Resources and Pages. This document defines the logical route structure, not REST API endpoints (there is no API — this is a server-rendered Filament panel).

## Panel Configuration

**Panel ID**: `admin`
**Path Prefix**: `/admin`
**Auth Guard**: `firebase`
**Middleware**: `VerifyAdminRole`
**Default Page**: `Dashboard`

---

## Route Map

### Authentication Routes

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/login` | GET | `filament.admin.auth.login` | Filament Login (customized) | FR-001 |
| `/admin/login` | POST | — | Firebase Auth verification | FR-001 |
| `/admin/logout` | POST | `filament.admin.auth.logout` | Session destroy | FR-001 |

---

### Dashboard & Widgets

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin` | GET | `filament.admin.pages.dashboard` | `Dashboard` page | FR-002, FR-003, FR-004, FR-005, FR-027 |

**Dashboard Widgets** (loaded as components within Dashboard page):
- `KpiStatsWidget` — 4 stat cards (Active Users, Critical Flags, Today's Sessions, Earnings) → FR-002
- `QuickActionsWidget` — 4 action buttons → FR-027
- `WeeklyAgendaWidget` — Week view with bookings → FR-003
- `RiskAlertsWidget` — Risk level patient list (polls 30s) → FR-004
- `RecentActivityWidget` — Latest 5 actions → FR-005
- `AiAssistantWidget` — Right panel toggle → FR-023

---

### MAIN Navigation Group

#### Users (Filament Resource)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/users` | GET | `filament.admin.resources.users.index` | `ListUsers` | FR-006, FR-011 |
| `/admin/users/{record}` | GET | `filament.admin.resources.users.view` | `ViewUser` (tabbed) | FR-022, FR-018 |
| `/admin/users/{record}/edit` | GET | `filament.admin.resources.users.edit` | `EditUser` | FR-006 |

**Actions on ViewUser**:
- Tab: Overview — User profile data
- Tab: Sessions — User's bookings list
- Tab: Assessments — User's assessment history
- Tab: Billing — Subscription management, payment history
- Action: Assign Subscription (modal: plan select + duration) → FR-018
- Action: Revoke Subscription → FR-018
- Action: Chat with User → FR-008

**Table Actions on ListUsers**:
- Bulk Export CSV → FR-030
- Bulk Export PDF → FR-030
- Search (name, email) → FR-006
- Filter by role → FR-006
- Filter by subscription status → FR-006

---

#### Clinicians (Filament Resource)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/clinicians` | GET | `filament.admin.resources.clinicians.index` | `ListTherapists` | FR-006, FR-020 |
| `/admin/clinicians/{record}` | GET | `filament.admin.resources.clinicians.view` | `ViewTherapist` | FR-006 |

**Tab Navigation** (within ListTherapists):
- Pending Review tab → `approval_status = 'pending'`
- Approved tab → `approval_status = 'approved'`
- Rejected tab → `approval_status = 'rejected'`

**Actions on ListTherapists**:
- Approve (on pending) → FR-020
- Reject with reason (on pending) → FR-020
- Filter by specialty → FR-006
- Bulk Export CSV/PDF → FR-030

---

#### Appointments (Filament Resource)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/appointments` | GET | `filament.admin.resources.appointments.index` | `ListBookings` | FR-006, FR-021 |
| `/admin/appointments/{record}` | GET | `filament.admin.resources.appointments.view` | `ViewBooking` | FR-006 |

**Tab Navigation** (within ListBookings):
- All / Upcoming / Completed / Cancelled

**Filters**:
- Session type (Video/Chat/Audio/In Person) → FR-021
- Date range → FR-006
- Search by client name → FR-006

**Actions**:
- Cancel with reason → FR-006
- Bulk Export CSV/PDF → FR-030

---

### COMMUNICATION Navigation Group

#### Support Chat (Custom Filament Page)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/support-chat` | GET | `filament.admin.pages.chat-support` | `ChatSupport` page | FR-008, FR-019 |

**Livewire Components**:
- `ChatPanel` — Thread list + message detail (polls 5s) → FR-008
- Actions: Send message, New chat, Broadcast all → FR-019

**Stats Header**: Total conversations, Unread messages, Urgent count, Avg response time

---

#### Community (Custom Filament Page)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/community` | GET | `filament.admin.pages.community-moderation` | `CommunityModeration` page | FR-009 |

**Actions**: Approve, Remove, Warn user

---

### INSIGHTS Navigation Group

#### Analytics (Custom Filament Page)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/analytics` | GET | `filament.admin.pages.analytics` | `Analytics` page | FR-010 |

**Charts** (Chart.js via Filament Charts):
- Therapist ratings distribution
- Session volume over time
- Revenue trends
- No-show rates
- Session type distribution
- Clinician performance comparison

---

#### Reports (Custom Filament Page)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/reports` | GET | `filament.admin.pages.reports` | `Reports` page | FR-028, FR-029 |
| `/admin/reports/generate/{template}` | POST | — | Report generation action | FR-028 |
| `/admin/reports/download/{id}` | GET | — | Report file download | FR-029 |

**Templates**: Monthly Summary, Patient Activity, Clinician Report, Financial Report, Risk Assessment, Custom Report

---

### SYSTEM Navigation Group

#### Billing (Filament Resource — Payments Overview + Verification)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/billing` | GET | `filament.admin.resources.payments.index` | `ListPayments` | FR-006 |
| `/admin/billing/verification` | GET | `filament.admin.pages.payment-verification` | `PaymentVerification` page | FR-007 |

**Payments Overview** (ListPayments):
- Stats: Total Revenue, This Month Revenue, Average Transaction, Conversion Rate, Success Rate, Approval Rate
- Tabs: All / Completed / Pending / Failed
- Bulk Export CSV/PDF → FR-030

**Payment Verification** (Custom Page):
- List pending verifications
- Actions: View receipt, Approve (activates subscription), Reject with reason → FR-007

---

#### Content (Filament Resource — Tabbed CMS)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/content` | GET | `filament.admin.resources.content.index` | `ListContent` | FR-006 |
| `/admin/content/create` | GET | `filament.admin.resources.content.create` | `CreateContent` | FR-006 |
| `/admin/content/{record}/edit` | GET | `filament.admin.resources.content.edit` | `EditContent` | FR-006 |
| `/admin/content/quotes` | GET | `filament.admin.resources.quotes.index` | `ListQuotes` | FR-006 |
| `/admin/content/quotes/create` | GET | `filament.admin.resources.quotes.create` | `CreateQuote` | FR-006 |
| `/admin/content/quotes/{record}/edit` | GET | `filament.admin.resources.quotes.edit` | `EditQuote` | FR-006 |
| `/admin/content/challenges` | GET | `filament.admin.resources.challenges.index` | `ListChallenges` | FR-006 |
| `/admin/content/challenges/create` | GET | `filament.admin.resources.challenges.create` | `CreateChallenge` | FR-006 |
| `/admin/content/challenges/{record}/edit` | GET | `filament.admin.resources.challenges.edit` | `EditChallenge` | FR-006 |

**Note**: Content, Quotes, and Challenges are 3 separate Filament Resources grouped under the "Content" navigation group.

---

#### Data Management (Custom Filament Page)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/data-management` | GET | `filament.admin.pages.data-management` | `DataManagement` page | FR-024 |

**Actions**: Export data (CSV/PDF), Cleanup operations

---

#### Settings (Custom Filament Page or Settings Plugin)

| Route | Method | Name | Component | FR |
|-------|--------|------|-----------|----|
| `/admin/settings` | GET | `filament.admin.pages.settings` | `Settings` page | FR-016 |

**Fields**:
- Maintenance Mode toggle
- Therapist Applications toggle
- Minimum App Version text input
- Support Email text input

---

### Header Components (Global)

| Component | Type | FR |
|-----------|------|----|
| `GlobalSearch` | Livewire (header) | FR-011 |
| `NotificationBell` | Livewire (header, polls 10s) | FR-017 |
| `ProfileMenu` | Filament user menu | FR-001 |
| `BreadcrumbNav` | Filament breadcrumbs | FR-026 |
| `LanguageSwitcher` | Filament plugin | FR-012 |

---

## Sidebar Navigation Structure (FR-025)

```
MAIN
├── Dashboard          → /admin
├── Users              → /admin/users
├── Clinicians         → /admin/clinicians
└── Appointments       → /admin/appointments

COMMUNICATION
├── Support Chat       → /admin/support-chat
└── Community          → /admin/community

INSIGHTS
├── Analytics          → /admin/analytics
└── Reports            → /admin/reports

SYSTEM
├── Billing            → /admin/billing
├── Content            → /admin/content
├── Data Management    → /admin/data-management
└── Settings           → /admin/settings
```

---

## Quick Actions Navigation Map (FR-027)

| Button | Label | Navigates To |
|--------|-------|-------------|
| New Patient | `New Patient` | `/admin/users` |
| Schedule Session | `Schedule Session` | `/admin/appointments` |
| Add Clinician | `Add Clinician` | `/admin/clinicians` |
| Create Invoice | `Create Invoice` | `/admin/billing` |

---

## Notification Action Routes (FR-017)

| Notification Type | Action Route | Navigates To |
|-------------------|-------------|-------------|
| `booking` | `/admin/appointments/{id}` | Booking detail |
| `message` | `/admin/support-chat` | Chat support |
| `community` | `/admin/community` | Moderation page |
| `mood` | `/admin/users/{id}` | User profile |
| `therapist` | `/admin/clinicians/{id}` | Therapist detail |
| `payment` | `/admin/billing/verification` | Payment verification |
| `system` | `/admin/settings` | Settings page |

---

## Export Endpoints (FR-030)

All list Resources support CSV and PDF export via Filament's `ExportAction`:

| Resource | Export Route (auto-generated) | Formats |
|----------|------------------------------|---------|
| Users | `/admin/users/export` | CSV, PDF |
| Clinicians | `/admin/clinicians/export` | CSV, PDF |
| Appointments | `/admin/appointments/export` | CSV, PDF |
| Payments | `/admin/billing/export` | CSV, PDF |
