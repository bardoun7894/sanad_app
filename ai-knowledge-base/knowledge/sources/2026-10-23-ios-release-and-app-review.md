---
name: Sanad iOS release path and App Review status (2026-10-23)
description: How Sanad iOS is signed, built and uploaded, and where the Guideline 2.1 App Review submission stands on 2026-10-23
type: source
sources: [raw/2026-10-23-ios-release-and-app-review.md]
created: "2026-10-23"
updated: "2026-10-23"
---

# Sanad iOS release path and App Review status (2026-10-23)

## Summary

The Sanad iOS app (bundle com.sanadtherapy.app, team SMMX7CLH24, HM5 Group) is built with `flutter build ipa` targeting `lib/main_user.dart` and uploaded with `xcrun altool` using App Store Connect API key 784AHAY2BN. Build 57 (version 1.0.30) was uploaded on 2026-10-23 and attached to the renamed App Store version through the API. Submission d3eb11d5 (1.0.25) was rejected under Guideline 2.1 Information Needed and, as of 2026-10-23, remains UNRESOLVED_ISSUES because no reply has been sent.

## Key points

- Apple Developer enrollment has been ACTIVE since 2026-09-30, and the Small Business Program (15% commission) was accepted 2026-10-10. This supersedes the old "enrollment stuck" note.
- Signing uses the 'Apple Distribution: Mohaned Mirghani (SMMX7CLH24)' certificate and the 'Sanad AppStore' profile (valid to 2027-09-30) with aps-environment=production, Sign in with Apple and Apple Pay merchant.app.sanad. Runner.entitlements now has aps-environment, which supersedes "iOS push not configured"; the APNs key in Firebase is not verified.
- Build and upload: `flutter build ipa --release -t lib/main_user.dart --export-options-plist=ios/ExportOptions.plist`, then `xcrun altool --upload-app --type ios` with `--apiKey 784AHAY2BN` and the matching issuer. Key 75H344S4C4 returns 401 with that issuer.
- Build history: 48-52 (Sep 30 to Oct 4), 54 (Oct 12), 57 = 1.0.30 (2026-10-23, delivery c92d7049). The App Store version was renamed 1.0.28 to 1.0.30 and build 57 attached via the API.
- Remaining: reply in App Store Connect App Review with the screen recording, text and a valid licence (the therapist licence sent 2026-10-17 expired 2026-07-21), then resubmit. The 18 MB recording cannot be uploaded through browser automation (10 MB cap).

## See also

- [[concepts/ios-release-pipeline]]
