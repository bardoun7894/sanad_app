---
name: iOS Release Pipeline
description: How Sanad iOS is built, uploaded and attached to an App Store version; Guideline 2.1 response in progress with build 59 (1.0.31)
type: concept
tags: [ios, release, app-store, apple]
sources: [sources/2026-10-23-ios-release-and-app-review, daily/2026-11-17.md]
created: "2026-10-23"
updated: "2026-11-18"
---

# iOS Release Pipeline

Sanad iOS releases are built locally with `flutter build ipa --release -t lib/main_user.dart --export-options-plist=ios/ExportOptions.plist`. The `main_user.dart` target produces the patient-facing app, and ExportOptions.plist drives App Store export signing with the 'Apple Distribution: Mohaned Mirghani (SMMX7CLH24)' certificate and the 'Sanad AppStore' profile. The resulting `build/ios/ipa/sanad_app.ipa` is uploaded with `xcrun altool --upload-app --type ios`, authenticated with App Store Connect API key 784AHAY2BN and its issuer ID. The key file lives at `~/.appstoreconnect/private_keys/AuthKey_784AHAY2BN.p8`; a different key, 75H344S4C4, returns 401 with that issuer.

The same API key reads and writes the App Store Connect API, which is how a processed build is attached to an App Store version. The version string on the App Store version must match the build's CFBundleShortVersionString. For build 57 the version was renamed from 1.0.28 to 1.0.30 before the build was attached.

## Build History

| Build | Version | Date | Notes |
|-------|---------|------|-------|
| 48–52 | various | 2026-09-30 to 2026-10-04 | Initial submissions |
| 54 | — | 2026-10-12 | — |
| 57 | 1.0.30 | 2026-10-23 | Delivery c92d7049 |
| 59 | 1.0.31 | 2026-11-17 | App Review 2.1 response build |

## Guideline 2.1 — App Review Response

Submission d3eb11d5 (1.0.25) was rejected under Guideline 2.1 Information Needed. Apple asked for a screen recording, the app's purpose, and a licence document. As of 2026-11-17, the response for build 59 (1.0.31) is prepared:

- A combined demo video (`Sanad-AppReview-1.0.31-combined.mp4`, 5:16, 24 MB) was created, splicing subscription screens from the first recording into a new recording.
- Reply text lives in `docs/app-review/2026-11-apple-2.1-reply-1.0.31.md` (updated from "build 58" to "build 59").
- Export compliance set to "no non-exempt encryption" (same as build 58).
- Build 59 includes iOS-only policy wording via separate Firestore fields (`dce61b2`) — see [[concepts/apple-policy-wording-split]].
- **Pending action:** owner must reply in App Review Resolution Center and press Submit for Review; the API cannot post to the Resolution Center thread — see [[concepts/app-store-connect-api-constraints]].
- Post-submission: run `node scripts/static_pages_apple_split.js --restore-shared` to restore Android's original policy text.

## See also

- [[sources/2026-10-23-ios-release-and-app-review]]
- [[concepts/apple-pay-integration]]
- [[concepts/apple-policy-wording-split]]
- [[concepts/app-store-connect-api-constraints]]
