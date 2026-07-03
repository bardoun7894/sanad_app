# Research: my-journal

**Generated**: 2026-07-03
**Feature**: [spec.md](./spec.md)

<!-- Sections below are populated by /kb-spec <mode> before each Spec Kit phase.
     Each section is owned by exactly one mode and is replaced wholesale on re-run.
     Free-form notes added by the user between sections are preserved. -->

## Prior art from KB

*Queried at 2026-07-03 · Mode: pre · Question: "What existing journaling/mood-entry code and patterns does the codebase have that a new 'مذكرتي' (My Journal) tab could reuse?"*

Direct codebase grep (KB has no dedicated article on this yet — first time this area is being scoped):

- `lib/features/mood/screens/journal_entry_screen.dart` — **already implements** a mood-tagged rich-ish entry screen: mood selector, prompt picker (gratitude/challenge/anxiety/win prompts), free-text `TextEditingController`. This is ~60% of the client's "write an entry with a mood + optional prompt" ask already built, just living inside the Mood feature, not exposed as its own "مذكرتي" destination.
- `lib/features/mood/models/mood_entry.dart` — `MoodEntry` + `MoodMetadata` models already persist mood + text + metadata per entry.
- `lib/features/mood/screens/mood_monthly_report_screen.dart` + `lib/features/mood/widgets/mood_chart.dart` + `mood_insights_row.dart` — already implement the monthly donut-chart mood breakdown the client's mockup (image 27550) shows in "تحليلات المشاعر". The "AI smart note suggesting an exercise" panel is new, but the chart/aggregation plumbing exists.
- `lib/features/mood/providers/mood_tracker_provider.dart` + `mood_repository.dart` — existing Firestore read/write path for mood entries; new Journal entries should extend this rather than create a parallel data model, to avoid the `orderBy` field-omission bug class documented in [[firestore_orderby_hides_docs_missing_field]] and [[dashboard_orderby_created_at_hides_users]] (always fetch-all + client-sort when a field may be missing on older docs).
- `lib/features/admin/screens/mood_feed_screen.dart` (admin side, recently touched — see current branch diff) — the admin "Moods" tab already surfaces mood entries; if Journal entries are private-only (per the PIN-lock mockup), this admin surface must explicitly exclude Journal entry *text* from admin visibility — only mood tags, to preserve the "distraction-free, private" positioning shown in the mockup.

**Not yet built anywhere in the codebase** (confirmed via grep, no matches):
- PIN/biometric lock screen for a specific in-app section (no local-auth gating pattern found elsewhere in the app — new pattern to introduce, likely `local_auth` package)
- Voice-to-text entry transcription (no speech-to-text package currently in `pubspec.yaml`)
- "كبسولة الزمن" (Time Capsule / on-this-day recall)
- Tag management UI (freeform tags, not mood categories)
- Deep-link from a mood-analytics AI note into the Exercises tab

## Related GitHub issues & PRs

*Queried at 2026-07-03 · Mode: pre*

`gh` not run for this pass — no open issue/PR tracker currently used for this repo's feature intake (client requests arrive via WhatsApp, tracked in `specs/_session/*.md`). Skipped per prerequisite fallback.
