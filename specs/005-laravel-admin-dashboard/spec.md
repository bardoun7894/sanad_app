# Feature Specification: Laravel Admin Dashboard Conversion

**Feature Branch**: `005-laravel-admin-dashboard`
**Created**: 2026-02-05
**Status**: Draft
**Input**: User description: "Convert Flutter web admin dashboard to Laravel with minimal changes, keeping same features"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Admin Logs In and Views Dashboard (Priority: P1)

An admin user navigates to the Laravel admin panel URL, authenticates with their existing Firebase credentials, and sees the clinic overview dashboard with: KPI cards (active users, critical flags, today's sessions, earnings with trends), Quick Actions shortcuts (New Patient, Schedule Session, Add Clinician, Create Invoice), weekly agenda, risk alerts, and recent activity feed (latest 5 actions).

**Why this priority**: The dashboard is the entry point for all admin operations. Without authentication and the main dashboard, no other feature is accessible.

**Independent Test**: Can be fully tested by logging in with an admin Firebase account and verifying that all 4 KPI cards display data, the weekly agenda shows upcoming bookings, risk alerts list at-risk patients, and recent activity shows the latest 5 actions.

**Acceptance Scenarios**:

1. **Given** a user with `isAdmin: true` in their Firestore profile, **When** they log in via the Laravel admin panel, **Then** they are authenticated and redirected to the dashboard
2. **Given** a non-admin user, **When** they attempt to access the admin panel, **Then** they are denied access with an appropriate message
3. **Given** an authenticated admin on the dashboard, **When** the page loads, **Then** all 4 KPI stat cards display current data from Firestore
4. **Given** bookings exist for the current week, **When** the admin views the dashboard, **Then** the weekly agenda widget shows those bookings grouped by day
5. **Given** an admin on the dashboard, **When** they click the "New Patient" quick action, **Then** they are navigated to the Users page
6. **Given** an admin on the dashboard, **When** they view Recent Activity, **Then** the latest 5 admin actions are displayed with type icon, user name, description, and time ago

---

### User Story 2 - Admin Manages Users (Priority: P1)

An admin can view a searchable, filterable list of all users, view individual user profiles with full details (tabbed: Overview, Sessions, Assessments, Billing), edit user roles/status, assign or revoke subscriptions (with plan selection and custom duration: 7d/30d/90d/365d), and initiate chat with users directly from the list.

**Why this priority**: User management is the most frequently used admin function. Therapists, patients, and subscriptions all depend on user data.

**Independent Test**: Can be tested by navigating to the Users section, searching for a specific user by name or email, applying filters (role: patient, status: active), viewing a user's profile tabs, updating their role, and assigning a subscription plan.

**Acceptance Scenarios**:

1. **Given** an admin on the Users page, **When** they search for a user by name, **Then** matching results appear from the Firestore `users` collection
2. **Given** the user list is displayed, **When** the admin filters by role "therapist", **Then** only therapist accounts are shown
3. **Given** an admin viewing a user profile, **When** they change the user's role, **Then** the change is persisted to Firestore and reflected immediately
4. **Given** an admin on a user's profile, **When** they assign a subscription plan with a 30-day duration, **Then** the user's subscription is activated in Firestore with the correct expiry date
5. **Given** a premium user, **When** the admin revokes their subscription, **Then** the subscription status is cleared in Firestore
6. **Given** an admin viewing a user profile, **When** they switch between Overview/Sessions/Assessments/Billing tabs, **Then** each tab displays the relevant data for that user

---

### User Story 3 - Admin Manages Therapists (Priority: P1)

An admin can view all registered therapists in grid or list view, filter by specialty (Anxiety, Depression, Trauma, Relationships, Stress Management), and manage therapist accounts through a tabbed workflow: Pending Review, Approved, and Rejected. Admins can approve or reject pending therapists.

**Why this priority**: Therapist management is critical for the clinic's operations - approving new therapists and monitoring existing ones.

**Independent Test**: Can be tested by viewing the therapist list, switching between Pending/Approved/Rejected tabs, opening a therapist's detail page, and performing approve/reject actions on a pending therapist.

**Acceptance Scenarios**:

1. **Given** an admin on the Therapists page, **When** they view the list, **Then** all therapists from `therapist_profiles` are displayed with key info (name, title, specialties, rating, session price)
2. **Given** a pending therapist, **When** the admin approves them, **Then** the therapist status changes to "approved" in Firestore
3. **Given** a pending therapist, **When** the admin rejects them, **Then** the therapist status changes to "rejected" in Firestore
4. **Given** the admin switches to the Rejected tab, **When** the tab loads, **Then** only rejected therapists are shown

---

### User Story 4 - Admin Manages Bookings (Priority: P1)

An admin can view all bookings across the system in table or card view, filter by status tabs (All, Upcoming, Completed, Cancelled), filter by session type (Video, Chat, In Person), search by client name, filter by date range, and cancel bookings with a reason. Each booking shows its session type (Video/Chat/Audio/In Person) and detailed status (Pending/Confirmed/Completed/Cancelled/Rejected/No Show).

**Why this priority**: Booking oversight is essential for clinic operations and scheduling management.

**Independent Test**: Can be tested by viewing the bookings list, filtering by status and session type, searching by client name, viewing booking details in bottom sheet, and cancelling a specific booking with a reason.

**Acceptance Scenarios**:

1. **Given** an admin on the Bookings page, **When** they view the list, **Then** all bookings from Firestore `bookings` collection are displayed ordered by scheduled time with session type icons
2. **Given** an upcoming booking, **When** the admin cancels it with a reason, **Then** the booking status is updated in Firestore and the reason is recorded
3. **Given** the admin selects a date range filter, **When** they apply it, **Then** only bookings within that date range are shown
4. **Given** the admin filters by session type "Video", **When** the filter is applied, **Then** only video session bookings are displayed

---

### User Story 5 - Admin Manages Payments and Verifications (Priority: P2)

An admin has two separate payment pages:

**Payments Overview** (Billing): Displays revenue stats (Total Revenue, This Month Revenue, Average Transaction) plus three rate metrics (Free-to-Premium Conversion Rate, Payment Success Rate, Verification Approval Rate) and a list of all payment transactions filterable by tabs (All, Completed, Pending, Failed). Each transaction shows user info, amount, status, date, and transaction ID.

**Payment Verification**: Displays pending bank transfer verifications. Admin can review receipt images, approve payments (which automatically activates the user's subscription), or reject with a reason.

**Why this priority**: Payment verification is a revenue-critical workflow that directly impacts user access to premium features.

**Independent Test**: Can be tested by viewing the Payments Overview page stats and transaction list, then navigating to the Verification page to review a receipt, approve a payment, and confirm the user's subscription is activated in Firestore.

**Acceptance Scenarios**:

1. **Given** an admin on the Payments Overview page, **When** the page loads, **Then** 6 stat cards are displayed (Total Revenue, This Month Revenue, Average Transaction, Free-to-Premium Conversion Rate, Payment Success Rate, Verification Approval Rate)
2. **Given** payment transactions exist, **When** the admin filters by "Pending" tab, **Then** only pending transactions are shown
3. **Given** pending payment verifications exist, **When** the admin views the Verification page, **Then** all pending verifications are displayed with receipt details
4. **Given** a pending verification, **When** the admin approves it, **Then** the verification status changes to "approved" and the user's subscription is activated
5. **Given** a pending verification, **When** the admin rejects it with a reason, **Then** the verification status changes to "rejected" and the rejection reason is recorded

---

### User Story 6 - Admin Manages CMS Content (Priority: P2)

An admin can create, edit, and delete content items (articles, quotes, challenges) through the CMS management screens. Each content type has its own management interface.

**Why this priority**: CMS keeps the app's content fresh and engaging for users - quotes, challenges, and articles are core engagement features.

**Independent Test**: Can be tested by creating a new quote, editing an existing content item, and deleting a challenge, then verifying changes in Firestore.

**Acceptance Scenarios**:

1. **Given** an admin on the Content Management page, **When** they create a new content item, **Then** it is saved to Firestore and appears in the list
2. **Given** an existing quote, **When** the admin edits it, **Then** the changes are persisted to Firestore
3. **Given** a challenge, **When** the admin deletes it, **Then** it is removed from Firestore

---

### User Story 7 - Admin Uses Chat Support with Broadcast (Priority: P2)

An admin can view all support chat threads with stats (total conversations, unread messages, urgent count, average response time), filter by priority and unread status, select a conversation, read the message history, send replies in near-real-time, start new chats by searching for users, and broadcast messages to all users.

**Why this priority**: Support chat is essential for user satisfaction and issue resolution.

**Independent Test**: Can be tested by viewing chat threads, checking stats, opening a specific conversation, reading messages, sending a reply, starting a new chat, and sending a broadcast message.

**Acceptance Scenarios**:

1. **Given** support chat threads exist, **When** the admin views the chat list, **Then** all threads from `support_chats` are displayed with last message preview and unread count
2. **Given** an open chat thread, **When** the admin sends a message, **Then** it appears in the conversation and is saved to Firestore
3. **Given** the admin clicks "Broadcast All", **When** they enter a message and confirm, **Then** the message is sent to all users
4. **Given** the admin clicks "New Chat", **When** they search for and select a user, **Then** a new chat thread is created

---

### User Story 8 - Admin Moderates Community (Priority: P2)

An admin can view community posts flagged for moderation, review their content, and take moderation actions (approve, remove, warn user).

**Why this priority**: Community safety and content quality require active moderation.

**Independent Test**: Can be tested by viewing flagged posts on the moderation dashboard and performing a moderation action.

**Acceptance Scenarios**:

1. **Given** flagged community posts exist, **When** the admin views the moderation dashboard, **Then** all flagged posts are listed with details
2. **Given** a flagged post, **When** the admin removes it, **Then** the post is updated in Firestore accordingly

---

### User Story 9 - Admin Views Analytics and Generates Reports (Priority: P3)

**Analytics**: An admin can view analytics dashboards showing therapist ratings, response speed, session volume over time, revenue trends, no-show rates, session type distribution, and clinician performance metrics.

**Reports**: An admin can generate reports from 6 templates (Monthly Summary, Patient Activity, Clinician Report, Financial Report, Risk Assessment, Custom Report), view a list of recently generated reports with download (PDF/CSV) and preview options.

**Why this priority**: Analytics and reports provide insights for business decisions but are not required for day-to-day operations.

**Independent Test**: Can be tested by viewing the analytics page charts, generating a Monthly Summary report, downloading a recent report, and verifying data accuracy against Firestore.

**Acceptance Scenarios**:

1. **Given** an admin on the Analytics page, **When** the page loads, **Then** therapist ratings, session volume charts, and revenue trends are displayed
2. **Given** historical booking data, **When** the admin views the no-show rate, **Then** the calculated percentage matches actual data from Firestore
3. **Given** an admin on the Reports page, **When** they click "Generate" on the Monthly Summary template, **Then** a report is generated and added to the Recent Reports list
4. **Given** a generated report in Recent Reports, **When** the admin clicks download, **Then** the report is downloaded in the selected format (PDF or CSV)

---

### User Story 10 - Admin Configures Settings and Manages Data (Priority: P3)

An admin can access system settings with specific toggles and configuration fields: Maintenance Mode (on/off), Therapist Applications (allow/disallow), Minimum App Version (editable text), and Support Email (editable text). All settings are stored in the Firestore `system_settings` collection. Data management provides export and cleanup operations.

**Why this priority**: Settings and data management are administrative housekeeping tasks needed less frequently.

**Independent Test**: Can be tested by toggling Maintenance Mode, editing the Minimum App Version, changing the Support Email, and verifying each change persists in Firestore.

**Acceptance Scenarios**:

1. **Given** an admin on the Settings page, **When** they toggle Maintenance Mode on, **Then** the setting is saved to Firestore `system_settings` and a success confirmation is shown
2. **Given** an admin on the Settings page, **When** they edit the Minimum App Version to "2.0.0", **Then** the new version is saved to Firestore
3. **Given** an admin on the Settings page, **When** they toggle Therapist Applications off, **Then** new therapist applications are blocked
4. **Given** an admin on the Data Management page, **When** they initiate an export, **Then** the requested data is exported in the specified format

---

### User Story 11 - Admin Receives and Manages Notifications (Priority: P2)

An admin can view a notification bell with unread count badge in the header, open a dropdown showing recent notifications grouped by type (booking, message, community, mood, therapist, payment, system), mark individual notifications as read by clicking them, mark all as read, and navigate to the relevant screen via notification action routes.

**Why this priority**: Notifications keep admins informed of important events in real-time and drive timely action on urgent items like payments and risk alerts.

**Independent Test**: Can be tested by triggering a notification event, verifying the bell badge updates, opening the dropdown, clicking a notification to mark it read and navigate to the action route, and using "Mark All Read".

**Acceptance Scenarios**:

1. **Given** unread notifications exist, **When** the admin views the header, **Then** the notification bell shows a badge with the unread count (capped at "9+")
2. **Given** the notification dropdown is open, **When** the admin clicks a notification, **Then** it is marked as read and the admin navigates to the relevant screen
3. **Given** multiple unread notifications, **When** the admin clicks "Mark All Read", **Then** all notifications are marked as read and the badge is cleared

---

### User Story 12 - Admin Uses AI Assistant (Priority: P3)

An admin can toggle an AI assistant panel on the right side of the dashboard that generates a summary of clinic data (user stats, session data, revenue, risk alerts), provides actionable insights and recommendations, and supports follow-up questions in a conversational interface.

**Why this priority**: AI insights enhance decision-making but are not required for core admin operations.

**Independent Test**: Can be tested by toggling the AI panel, clicking "Generate Summary", reading the generated insights, and asking a follow-up question.

**Acceptance Scenarios**:

1. **Given** an admin on the dashboard, **When** they toggle the AI assistant panel, **Then** the right panel appears with the AI assistant interface
2. **Given** the AI panel is open, **When** the admin clicks "Generate Summary", **Then** the system analyzes clinic data and displays a summary with insights
3. **Given** a summary is displayed, **When** the admin types a follow-up question, **Then** the AI responds contextually based on the clinic data

---

### Edge Cases

- What happens when Firestore is temporarily unavailable? Admin sees a clear error message with retry option.
- What happens when an admin session expires? User is redirected to login with a session expired message.
- What happens when two admins approve/reject the same payment verification simultaneously? The first action wins; the second admin sees an "already processed" message.
- What happens when Firestore data is malformed or has missing fields? The admin panel handles missing data gracefully with fallback displays ("N/A" or "-").
- What happens when the admin searches for a user that doesn't exist? Empty state message is shown.
- What happens when risk alert detection finds no at-risk users? The risk alerts widget shows an "All clear" message.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST authenticate admin users using existing Firebase Auth credentials with `isAdmin: true` verification
- **FR-002**: System MUST display a dashboard with 4 KPI cards (Active Users, Critical Flags, Today's Sessions, Earnings) pulling live data from Firestore
- **FR-003**: System MUST provide a weekly agenda widget showing bookings for the current week grouped by day
- **FR-004**: System MUST detect and display risk alerts by analyzing mood entry patterns from Firestore `mood_entries` collection
- **FR-005**: System MUST log all admin actions to the `activity_logs` Firestore collection
- **FR-006**: System MUST provide searchable, filterable CRUD interfaces for Users, Therapists, Bookings, Payments, and CMS content
- **FR-007**: System MUST support payment verification workflow (view receipt, approve with subscription activation, reject with reason)
- **FR-008**: System MUST provide a chat support interface that reads/writes to `support_chats` Firestore collection
- **FR-009**: System MUST provide a community moderation interface for reviewing and actioning flagged posts
- **FR-010**: System MUST provide analytics dashboards with charts for ratings, session volume, revenue, no-show rates, and clinician performance
- **FR-011**: System MUST support global search across users, therapists, and bookings
- **FR-012**: System MUST support English, Arabic, and French localization with RTL layout for Arabic
- **FR-013**: System MUST provide a dark theme matching the existing "Roobin Mood" dark admin theme
- **FR-014**: System MUST be responsive across desktop (1024px+), tablet (768-1023px), and mobile (<768px) breakpoints
- **FR-015**: System MUST connect to the same Firestore database used by the Flutter mobile app with no data migration
- **FR-016**: System MUST provide settings page with specific controls: Maintenance Mode toggle, Therapist Applications toggle, Minimum App Version (editable), Support Email (editable), all persisted to Firestore `system_settings`
- **FR-017**: System MUST provide a notification system with bell icon, unread badge (capped at 9+), dropdown panel with notification items typed by category (booking, message, community, mood, therapist, payment, system), mark-as-read, mark-all-read, and navigation to action routes
- **FR-018**: System MUST support subscription management: assign subscription plans with selectable durations (7d/30d/90d/365d) and revoke subscriptions from user profiles
- **FR-019**: System MUST support chat broadcast to send a message to all users from the support chat interface
- **FR-020**: System MUST display therapists in three workflow tabs (Pending Review, Approved, Rejected) with approve and reject actions
- **FR-021**: System MUST track and display booking session types (Video, Chat, Audio, In Person) with appropriate visual indicators
- **FR-022**: System MUST provide a patient detail view with tabbed sections: Overview, Sessions, Assessments, Billing
- **FR-023**: System MUST provide an AI assistant panel that generates clinic data summaries with insights and supports follow-up questions
- **FR-024**: System MUST provide data management page for data export and cleanup operations
- **FR-025**: System MUST use the following sidebar navigation structure with exact labels: MAIN (Dashboard, Users, Clinicians, Appointments), COMMUNICATION (Support Chat, Community), INSIGHTS (Analytics, Reports), SYSTEM (Billing, Content, Data Management, Settings)
- **FR-026**: System MUST provide breadcrumb navigation showing the current route path with clickable parent segments
- **FR-027**: System MUST provide Quick Actions shortcuts on the dashboard: New Patient (→ Users), Schedule Session (→ Appointments), Add Clinician (→ Clinicians), Create Invoice (→ Billing)
- **FR-028**: System MUST provide 6 report templates: Monthly Summary, Patient Activity, Clinician Report, Financial Report, Risk Assessment, Custom Report - each generating downloadable reports (PDF/CSV)
- **FR-029**: System MUST display a Recent Reports list showing previously generated reports with download and preview actions
- **FR-030**: System MUST provide working CSV and PDF export on all list pages (Users, Clinicians, Appointments, Payments) - not placeholders

### Key Entities

- **User**: Represents an app user (patient or therapist). Key attributes: email, displayName, role, isPremium, subscriptionStatus, createdAt. Maps to Firestore `users` collection.
- **Therapist Profile**: Represents a therapist's professional details. Key attributes: qualifications, ratings, approval status, specializations. Maps to Firestore `therapist_profiles` collection.
- **Booking**: Represents a scheduled session. Key attributes: scheduled_time, status (upcoming/completed/cancelled), patient, therapist, cancellation reason. Maps to Firestore `bookings` collection.
- **Payment Transaction**: Represents a completed or attempted payment. Key attributes: userId, amount, status (completed/pending/failed), transactionId, date. Maps to Firestore `payments` collection. Displayed on Payments Overview page.
- **Payment Verification**: Represents a bank transfer verification request. Key attributes: amount, currency, referenceCode, receiptUrl, status (pending/approved/rejected), reviewedBy. Maps to Firestore `payment_verifications` collection. Displayed on separate Verification page.
- **Activity Log**: Represents an admin action audit trail. Key attributes: type, userId, description, timestamp, metadata. Maps to Firestore `activity_logs` collection.
- **Risk Alert**: Represents a detected mood decline pattern. Key attributes: patient info, risk level (critical/high/moderate/low), mood trend data. Derived from Firestore `mood_entries` collectionGroup.
- **Chat Thread**: Represents a support conversation. Key attributes: userId, userName, lastMessage, unreadCount. Maps to Firestore `support_chats` collection.
- **CMS Content**: Represents managed content (articles, quotes, challenges). Maps to respective Firestore collections.
- **Notification**: Represents an admin notification. Key attributes: type (booking/message/community/mood/therapist/payment/system), title, body, isRead, actionRoute, timestamp. Maps to admin notifications in Firestore.
- **System Setting**: Represents a configurable system parameter. Key attributes: key (maintenanceMode, therapistApplications, minAppVersion, supportEmail), value, updatedAt. Maps to Firestore `system_settings` collection.
- **Subscription Plan**: Represents an assignable subscription tier. Key attributes: planId, title, price, duration, isRecommended. Used when admins assign subscriptions to users.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All admin features from the Flutter web dashboard (30 functional requirements) are fully functional in the Laravel admin panel
- **SC-002**: Admin users can log in and access the dashboard within 5 seconds of page load
- **SC-003**: All CRUD operations (create, read, update, delete) reflect changes in Firestore within 3 seconds
- **SC-004**: The Flutter mobile app continues to function identically with zero changes to its codebase
- **SC-005**: 100% of admin users can complete their current workflows without additional training (familiar patterns)
- **SC-006**: The admin panel supports all 3 languages (English, Arabic, French) with correct RTL layout
- **SC-007**: Risk alerts update within 30 seconds of new mood data being recorded (via polling)
- **SC-008**: Global search returns results within 2 seconds across users, therapists, and bookings

### Performance & Quality Criteria

**Performance**:
- **SC-P01**: Dashboard page loads fully within 3 seconds on standard broadband connection
- **SC-P02**: List pages (users, bookings, etc.) paginate and load within 2 seconds per page
- **SC-P03**: Chat messages appear within 10 seconds of being sent (polling interval)

**Error Handling & Observability**:
- **SC-O01**: All Firestore connection failures display a user-friendly retry message
- **SC-O02**: All admin actions are logged to Firestore `activity_logs` for audit compliance
- **SC-O03**: Failed payment verification actions (approve/reject) show clear error messages and do not leave data in inconsistent state

## Clarifications

### Session 2026-02-05

- Q: Should all 8 missing features found in Flutter audit (notification bell, subscription management, chat broadcast, specific system settings, therapist rejection, session types, patient detail tabs, quick actions) be included in the spec? → A: Yes, include ALL for full Flutter parity.
- Q: Should Payments Overview (revenue stats + transaction history) and Payment Verification (approve/reject bank transfers) be two separate pages or merged? → A: Keep as two separate pages, matching Flutter exactly.
- Q: Should sidebar navigation use the exact Flutter labels and grouping or simplified labels? → A: Keep exact Flutter labels: MAIN (Dashboard, Users, Clinicians, Appointments), COMMUNICATION (Support Chat, Community), INSIGHTS (Analytics, Reports), SYSTEM (Billing, Content, Data Management, Settings).
- Q: What does "Conversion Rate" mean on Payments Overview? → A: Include ALL three metrics: Free-to-Premium conversion rate, Payment success rate, and Verification approval rate.
- Q: Should export buttons on list pages (Users, Bookings, Payments) be working or placeholder "coming soon"? → A: Implement all exports as working CSV/PDF downloads on all list pages.

## Assumptions

- The Firebase project service account credentials will be available for the Laravel application
- The existing Firestore security rules allow Admin SDK operations (Admin SDK bypasses client-side rules)
- The existing Firestore collections and document structures will not change during the migration
- The hosting environment for the Laravel application supports PHP 8.2+ and Composer
- Admin users will use the same Firebase Auth accounts they currently use (no new account creation needed)
- The Firebase Admin PHP SDK supports all required Firestore operations (queries, collection groups, polling)
- The admin panel framework provides sufficient customization for matching the existing dark theme
- Polling at 5-10 second intervals is acceptable as a replacement for real-time streams
