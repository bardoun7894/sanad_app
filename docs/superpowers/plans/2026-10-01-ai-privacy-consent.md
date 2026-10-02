# AI Privacy Consent Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans task by task. Preserve unrelated existing workspace changes; file ownership below separates concurrent work.

**Goal:** Prevent AI transfers before the account holder accepts the disclosed Google Gemini processing and align privacy text with actual behavior.

**Architecture:** A server-normalized, versioned consent record belongs to each user. Flutter asks for consent before AI operations and exposes revocation; server functions independently enforce it for the patient whose information they process.

**Tech Stack:** Flutter/Riverpod, Firebase callable Functions and Firestore, Node tests, Next.js landing page.

## Task 1: Server consent and enforcement

Files: create `functions/lib/aiPrivacyConsent.js`, `functions/test/aiPrivacyConsent.test.js`; modify `functions/index.js`, `firestore.rules` and relevant rules tests. Backend worker owns these files.

- [x] Write and run failing tests for accepted/current consent, missing/declined/outdated consent, account identity, revocation and normalized timestamps. Exercise the real helper/callable boundary; a rejected request must never invoke the AI dependency.
- [x] Implement the version/record check:

  ```js
  const AI_PRIVACY_CONSENT_VERSION = '2026-10-01';
  function hasAiPrivacyConsent(record) {
    return record?.accepted === true &&
      record.version === AI_PRIVACY_CONSENT_VERSION;
  }
  ```

- [x] Export authenticated `setAiPrivacyConsent` for the `{accepted, version}` protocol in the spec. Store only server-normalized fields, with a Firestore server timestamp. Reuse current Functions/Admin initialization.
- [x] Guard `chatWithGemini` and `generateUserReport` before their external AI calls; audit `generateUserBriefing` and all other Gemini entry points. Check target patient's consent for therapist/admin-generated reports.
- [x] Block direct owner/admin-client consent writes through Firestore rules; callable Admin SDK writes remain possible. Allow ordinary profile registration without a consent field.
- [x] Run `cd functions && npm test` and the relevant emulator rules checks. Record the failing test evidence and final results.

## Task 2: Flutter consent, localization and fallback

Files: create a focused consent service/provider/dialog with tests under `lib/features/chat/` and `test/features/chat/`; modify actual AI send/confirmation paths, privacy controls and `lib/features/more/static_page_screen.dart`. Client worker owns these files; no Functions/rules edits.

- [x] Add failing tests proving Not now/cancellation/read or write errors make no AI request, acceptance permits it, revoked/outdated consent requires acceptance, and a different signed-in account cannot inherit the previous user's choice.
- [x] Use `users/{uid}.ai_privacy_consent` and callable `setAiPrivacyConsent` with the exact version/protocol above. Never cache acceptance globally across accounts or treat a failed save as acceptance.
- [x] Name Google Gemini and the shared messages/history/profile/health context before consent. Include safety screening/escalation. Offer localized Agree/Not now and a revoke control; preserve human chat.
- [x] Guard main chat, direct crisis confirmation and any direct AI SDK invocation. Handle permission errors with the consent explanation rather than a generic AI failure.
- [x] Correct the privacy fallback's external-AI, authorized staff and safety descriptions. Do not edit unused draft pages as a substitute for the live route.
- [x] Run focused Flutter tests and analyze changed files, then run chat and subscription tests together.

## Task 3: Published privacy and rollout

Root owns live CMS and website deployment, App Store/Play metadata, release version, build/upload and runbook.

- [x] Review the client's corrected privacy text; patch the existing AR/EN live CMS paragraphs and matching landing-page paragraphs without replacing unrelated legal terms.
- [x] Review the combined server/client diff in a fresh context. Run meaningful automated checks and build the real iOS/Android release artifacts.
- [x] Deploy only the AI consent and guarded functions plus relevant rules, and publish the verified website policy change.
- [x] Upload iOS build 50, select it for App Review, and assign the internal QA group. The subscription group and four products are in the existing unsubmitted review draft.
- [x] Resolve Apple's missing 13-inch iPad screenshot requirement using the unchanged production subscription widget; verify COMPLETE processing and listing placement.
- [ ] Publish Apple's completed privacy response draft after the required owner legal confirmation, then add the prepared app version to the same review draft.
- [ ] Upload the verified Android AAB after Chrome file-access permission is enabled; the release name and notes are already saved as a draft. Preserve the existing Play data-category declarations as requested.
- [ ] Complete sandbox purchase/restore/renewal device checks when the currently unavailable iPhone is connected.
- [x] Keep owner content-rights/legal-entity requirements explicit. Do not submit false declarations or claim device purchases were tested from widget renders.
- [ ] Retest Production notifications immediately after the first production release; Apple blocks that API while the app is unreleased.
