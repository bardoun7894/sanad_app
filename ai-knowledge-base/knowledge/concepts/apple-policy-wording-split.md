---
name: Apple Policy Wording Split
description: iOS reads its own Firestore fields for coach/counselor policy wording to satisfy Apple review, while Android keeps the shared fields
type: concept
tags: [ios, apple, firestore, compliance, static-pages]
sources: [daily/2026-11-17.md]
created: "2026-11-18"
updated: "2026-11-18"
---

# Apple Policy Wording Split

## Overview

To address Apple's App Review concerns about therapist-related wording, the Sanad app uses separate Firestore fields for iOS policy text. iOS reads its own `_ios`-suffixed fields (e.g. for coach/counselor terminology) while Android continues to read the shared fields. This allows the iOS build to present Apple-compliant wording without affecting the Android app's content.

## Key Points

- iOS reads dedicated Firestore fields for static pages that contain policy-sensitive wording (coach/counselor instead of therapist terminology).
- Android keeps the shared fields with the new wording temporarily; the original text is restored post-submission via a restore script.
- The split was implemented in commit `dce61b2` and confirmed by the owner as acceptable ("ok" to making coach/counselor text iOS-only).
- A backup of the original shared fields exists at `functions/scripts/backups/static_pages-2026-11-16`.
- Post-submission restore command: `node scripts/static_pages_apple_split.js --restore-shared functions/scripts/backups/static_pages-2026-11-16`.

## Details

Apple's Guideline 2.1 rejection required the app to adjust how it presents its services. Rather than changing the wording globally (which would affect the Arabic-market Android users), the approach splits the content at the Firestore level. The Flutter app checks the platform and reads from the appropriate field, so the same codebase serves both platforms with different policy text.

This is a pragmatic compliance strategy: the iOS-specific fields exist only to satisfy Apple's review process. Once the submission is approved, the shared fields are restored for Android via the `--restore-shared` flag on the split script. The pattern can be reused if future Apple reviews require platform-specific content adjustments without changing the core product messaging.

The old recording used in the demo video still shows the pre-change wording ("معالج نفسي"), but the live app serves the correct iOS-specific text. This was noted as acceptable for submission since the video predates the wording change.

## Related Concepts

- [[concepts/ios-release-pipeline]] — The release workflow this strategy supports; build 59 (1.0.31) includes this change
- [[concepts/app-store-connect-api-constraints]] — API limitations encountered while preparing the same submission

## Sources

- [[daily/2026-11-17.md]] — Owner approved Apple-only policy wording; commit `dce61b2` implements iOS-specific Firestore field reads; restore script documented
