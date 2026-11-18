---
name: iOS Release Pipeline
description: How Sanad iOS is built, uploaded and attached to an App Store version, and the state of the Guideline 2.1 review as of 2026-10-23
type: concept
sources: [sources/2026-10-23-ios-release-and-app-review]
created: "2026-10-23"
updated: "2026-10-23"
---

# iOS Release Pipeline

Sanad iOS releases are built locally with `flutter build ipa --release -t lib/main_user.dart --export-options-plist=ios/ExportOptions.plist`. The `main_user.dart` target produces the patient-facing app, and ExportOptions.plist drives App Store export signing with the 'Apple Distribution: Mohaned Mirghani (SMMX7CLH24)' certificate and the 'Sanad AppStore' profile. The resulting `build/ios/ipa/sanad_app.ipa` is uploaded with `xcrun altool --upload-app --type ios`, authenticated with App Store Connect API key 784AHAY2BN and its issuer ID. The key file lives at `~/.appstoreconnect/private_keys/AuthKey_784AHAY2BN.p8`; a different key, 75H344S4C4, returns 401 with that issuer.

The same API key reads and writes the App Store Connect API, which is how a processed build is attached to an App Store version. The version string on the App Store version must match the build's CFBundleShortVersionString. For build 57 the version was renamed from 1.0.28 to 1.0.30 before the build was attached.

As of 2026-10-23, submission d3eb11d5 (1.0.25) is still UNRESOLVED_ISSUES after a Guideline 2.1 Information Needed rejection. Apple asked for a screen recording, the app's purpose and a licence document. The client's iPhone recording arrived 2026-10-12, but no reply has been sent. A reply with the recording, text and a currently valid licence is still needed before resubmission. The therapist licence sent on 2026-10-17 expired on 2026-07-21, so it will not do.

## See also

- [[sources/2026-10-23-ios-release-and-app-review]]
- [[concepts/apple-pay-integration]]
