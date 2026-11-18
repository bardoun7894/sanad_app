---
name: App Store Connect API Constraints
description: Operational limits of the App Store Connect API — Resolution Center posting, single attachment per version, export compliance prerequisite for TestFlight
type: concept
tags: [ios, apple, app-store-connect, api]
sources: [daily/2026-11-17.md]
created: "2026-11-18"
updated: "2026-11-18"
---

# App Store Connect API Constraints

## Overview

The App Store Connect API supports build uploads, version management, and TestFlight distribution, but has significant gaps in its coverage of the review workflow. These constraints were discovered during the Sanad build 59 (1.0.31) App Review response preparation on 2026-11-17.

## Key Points

- The API **cannot post to the Resolution Center thread** — replies to App Review rejections must be entered manually in the web UI.
- Notes and attachments on a version can be set programmatically, but the Resolution Center conversation itself is read-only via the API.
- Apple allows **only one review attachment per version** — the old attachment must be deleted before a new one can be uploaded.
- Adding a build to a TestFlight group **requires export compliance to be set first** — the API rejects the group-add call if the build's export compliance answer is missing.

## Details

The inability to post to the Resolution Center is the most impactful constraint for automated workflows. While the API can manage builds, versions, and beta distribution, the actual review response — the text reply that addresses Apple's rejection reasons — must be composed and submitted through the App Store Connect web interface. This means the final step of any App Review response workflow requires human interaction with the browser UI, regardless of how automated the rest of the pipeline is.

The single-attachment limit is a practical constraint when iterating on review materials. If a demo video needs to be replaced (e.g. updating from build 58 to build 59 references), the previous attachment must be explicitly deleted via the API before the replacement can be uploaded. Attempting to add a second attachment without deletion results in an error.

The export compliance prerequisite for TestFlight caught the team during build 59 distribution. Even though the answer ("no non-exempt encryption") was identical to the previous build, it had to be explicitly set on the new build before it could be added to any TestFlight group. This is not a one-time setting — it must be answered per build.

## Related Concepts

- [[concepts/ios-release-pipeline]] — The release workflow where these constraints surface; build 59 preparation encountered all three
- [[concepts/apple-policy-wording-split]] — The content compliance strategy prepared alongside this submission

## Sources

- [[daily/2026-11-17.md]] — Resolution Center API limitation discovered; single-attachment constraint hit; export compliance prerequisite for TestFlight documented
