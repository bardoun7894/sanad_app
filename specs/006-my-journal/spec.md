# Feature Specification: مذكرتي (My Journal)

**Feature Branch**: `006-my-journal`
**Created**: 2026-07-03
**Status**: Draft — pending client sign-off on scope/billing before planning
**Input**: Client request via WhatsApp (Mohanned Rahma, 2026-07-02), text spec + 2 reference mockup images + 1 placement screenshot. Billed separately from the existing contract per client's explicit note.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Write a private mood-tagged journal entry (Priority: P1)

A user opens "مذكرتي" from a home-screen shortcut or the More tab, picks how they feel (happy/tense/sad/angry), optionally answers a daily prompt, and writes freely in a distraction-free editor (light or dark background), then saves.

**Why this priority**: This is the core loop everything else (analytics, time capsule, exercise links) depends on. Largely reuses `lib/features/mood/screens/journal_entry_screen.dart` + `MoodEntry` model already in the codebase.

**Independent Test**: Create an entry, verify it persists and appears in the entries list with its mood tag.

**Acceptance Scenarios**:

1. **Given** the user is on the Journal home, **When** they tap "تدوينة جديدة", **Then** they see the mood picker before the editor.
2. **Given** an entry is being written, **When** the user selects a prompt, **Then** it's inserted at the top of the text field (existing behavior).
3. **Given** the user saves an entry, **When** they return to the entries list, **Then** the new entry appears, tagged with its mood color/icon.

---

### User Story 2 - Lock the journal with a PIN/biometric (Priority: P1)

Per the mockup, the journal must be a private space — a 4-digit PIN screen (with fingerprint fallback) gates entry into "مذكرتي" specifically, separate from any app-wide lock.

**Why this priority**: Explicitly shown as its own screen in the client's mockup and central to the "safe space" positioning; without it the feature doesn't match what was pitched to him.

**Independent Test**: Set a journal PIN, background the app, reopen — journal requires PIN/biometric before showing any entry content.

**Acceptance Scenarios**:

1. **Given** no PIN is set, **When** the user first opens the journal, **Then** they're prompted to set one (skippable, revisitable in settings).
2. **Given** a PIN is set, **When** the user opens the journal after backgrounding the app, **Then** they must enter the PIN or use biometrics before seeing entries.
3. **Given** the device supports biometrics, **When** on the PIN screen, **Then** a fingerprint/face-ID shortcut is offered.

---

### User Story 3 - Voice-to-text entry (Priority: P2)

User taps a mic icon in the editor, speaks, and the app transcribes speech into the entry text field live or on stop.

**Why this priority**: Explicitly shown in the mockup ("تفريغ صوتي") but not core to MVP — text entry alone delivers the primary value.

**Independent Test**: Tap mic, speak a sentence, stop — transcribed text appears in the editor, editable before save.

**Acceptance Scenarios**:

1. **Given** the editor is open, **When** the user taps the mic icon, **Then** recording starts with a live waveform + timer (per mockup).
2. **Given** recording stops, **When** transcription completes, **Then** the text is inserted into the editor for the user to edit before saving.
3. **Given** microphone permission is denied, **When** the user taps mic, **Then** a clear permission-request/explanation is shown (no silent failure).

---

### User Story 4 - Mood analytics with AI note → exercise link (Priority: P2)

A monthly view shows a donut chart of mood distribution plus an AI-generated note ("you often mention work stress") with a button that deep-links into the existing Exercises tab, pre-filtered/relevant to that note.

**Why this priority**: Reuses existing `mood_monthly_report_screen.dart` chart plumbing; the new pieces are the AI note text and the deep link — moderate net-new backend work (an LLM summarization pass over entry text) plus one navigation route.

**Independent Test**: With ≥5 entries in a month, open analytics — chart renders, an AI note appears, tapping its button navigates to Exercises.

**Acceptance Scenarios**:

1. **Given** entries exist for the current month, **When** the user opens journal analytics, **Then** the donut chart reflects their actual mood percentages (reuse existing aggregation).
2. **Given** the AI note references a theme (e.g. anxiety), **When** the user taps its action button, **Then** they land on the Exercises tab (deep link, not just a generic tab switch — should carry a relevant filter/highlight if the Exercises tab supports one, else a plain navigation is acceptable for v1).
3. **Given** fewer than 3 entries exist this month, **When** analytics is opened, **Then** an empty/low-data state is shown instead of a misleading chart.

---

### User Story 5 - Time Capsule (on-this-day recall) (Priority: P3)

Surfaces past entries written on the same calendar day in previous months/years, shown as a "1 year ago today you wrote..." card.

**Why this priority**: Delightful but non-essential; depends on the journal having accumulated history, so has near-zero value until users have months of entries.

**Independent Test**: With an entry from ≥1 month ago on today's date (seeded in test data), open the journal home — the time-capsule card appears with that entry's excerpt.

**Acceptance Scenarios**:

1. **Given** an entry exists dated exactly N months/years before today, **When** the user opens the journal home, **Then** a card surfaces it.
2. **Given** no past entry matches today's date, **When** the user opens the journal home, **Then** no time-capsule card is shown (not an empty/broken card).

---

### User Story 6 - Tag management (Priority: P3)

Users can create/edit/delete freeform tags (e.g. "عمل", "علاقات") independent of mood, and filter entries by tag.

**Why this priority**: Organizational nicety shown in the mockup; not required for the core write/reflect loop.

**Independent Test**: Create a tag, apply it to an entry, filter the entries list by that tag.

**Acceptance Scenarios**:

1. **Given** the tag management screen, **When** the user adds a new tag, **Then** it becomes selectable when writing/editing an entry.
2. **Given** entries tagged variously, **When** the user filters by one tag, **Then** only matching entries show.

---

### Edge Cases

- What happens if a user forgets their journal PIN? Needs a recovery path (e.g. re-auth via app account, not a silent reset that could expose entries) — **NEEDS CLARIFICATION** with client on acceptable recovery UX.
- What happens to journal entries when a user deletes their account? Should follow the existing hard-delete Cloud Function path ([[delete_account_and_soft_update]]) — confirm Journal entries are included in that deletion, not orphaned.
- What happens if voice-to-text fails mid-recording (network drop, if using a cloud STT API)? Must preserve any partial transcript and let the user retry, not silently discard.
- What happens if the AI mood-analytics note-generation call fails or times out? Show the chart without the note rather than blocking the whole analytics screen.
- Should admin/support ever see journal entry *text*? Per the "private safe space" positioning, **default to no** — only aggregate mood tags should be visible to admin (mirrors the existing `mood_feed_screen.dart` admin view, which already only shows mood, not raw journal prose from `journal_entry_screen.dart`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a "مذكرتي" entry point from the home screen (icon shortcut, per client mockup) and from the existing "المزيد" (More) tab under a Content section.
- **FR-002**: System MUST let users create a journal entry with: a mood tag, optional daily prompt, free rich-ish text (bold/italic/underline/font size per mockup), timestamp.
- **FR-003**: System MUST persist journal entries reusing/extending the existing `MoodEntry`/`mood_repository.dart` data path rather than a parallel model, per [[firestore_orderby_hides_docs_missing_field]] guidance (always fetch-all + client-sort, never `orderBy` on a field that may be absent on older docs).
- **FR-004**: System MUST gate the journal behind a PIN (with optional biometric unlock) set independently of any device-level lock.
- **FR-005**: System MUST support voice-to-text entry creation via microphone recording + transcription.
- **FR-006**: System MUST support both light and dark presentation of the entry editor (respecting or extending the app's existing theme system).
- **FR-007**: System MUST show a monthly mood-analytics view (donut chart + AI-generated note) reusing existing chart/aggregation code where possible.
- **FR-008**: System MUST deep-link from the analytics AI note into the existing Exercises tab.
- **FR-009**: System MUST support freeform tag creation, assignment, and tag-based filtering of entries.
- **FR-010**: System MUST surface a "Time Capsule" card recalling past entries from the same calendar day in prior months/years, when such an entry exists.
- **FR-011**: System MUST exclude raw journal entry text from any admin-facing screen; only mood aggregates are admin-visible.
- **FR-012**: System MUST include journal entries in the existing account-deletion flow ([[delete_account_and_soft_update]]).

### Key Entities

- **JournalEntry** (extends/reuses `MoodEntry`): mood tag, prompt (optional), rich text content, tags (new field), createdAt, userId. Voice-transcribed entries are indistinguishable from typed ones once saved (transcript becomes the text content).
- **JournalTag**: user-scoped freeform label (name, color), many-to-many with JournalEntry.
- **JournalPinConfig**: per-user PIN hash + biometric-enabled flag, stored separately from any app-wide auth state.
- **MoodAnalyticsSummary**: derived (not stored raw) monthly aggregate — mood percentage breakdown + one AI-generated note referencing dominant themes, with a suggested exercise-tab link.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can go from tapping the home-screen Journal shortcut to a saved entry in under 60 seconds on first use (excluding PIN setup).
- **SC-002**: PIN-lock correctly blocks entry content on 100% of app-background/foreground cycles during QA testing (no bypass via task-switcher preview, no stale unlocked state).
- **SC-003**: Voice-to-text transcription accuracy is acceptable for Arabic speech in at least an internal spot-check (no hard numeric target without a client-agreed STT vendor — **NEEDS CLARIFICATION** on which STT service/budget is approved, since this is a new paid dependency).
- **SC-004**: Admin dashboard never displays journal entry free text in any screen or export (verified by code review + a explicit admin-side test asserting the field is absent from any admin query/response).
- **SC-005**: Client reviews and signs off on entry-editor visual design (light + dark) before implementation of remaining stories, since this is explicitly a separate-billing addition — avoids rework.

---

## Open questions before planning (`/speckit.plan`)

1. **Billing/scope confirmation**: which of the 6 user stories are in the agreed separate-billing scope for v1 — all six, or P1/P2 only (write+lock+voice+analytics) with Time Capsule/Tags deferred?
2. **STT vendor**: no speech-to-text package exists in `pubspec.yaml` today. Need a vendor decision (on-device vs cloud API) — cost and Arabic-accuracy tradeoff.
3. **PIN recovery UX**: what happens when a user forgets their journal PIN — needs explicit client answer, since a wrong choice here is a security/trust issue for a "safe space" feature.
4. **AI note generation**: reuse the existing Gemini integration (`core/services/gemini_service.dart`) already used by the AI chat feature, or a separate call? Affects cost estimation.
