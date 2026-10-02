# App Store subscription rollout

Bundle: `com.sanadtherapy.app` · Apple app ID: `6817892036` · Firebase project: `sanad-app-beldify`.

## Products

All products are in subscription group `22429209` (Sanad Subscriptions). USD is the base price; the app displays the localized StoreKit price. Apple supplies regional price equivalents.

| Product ID | Apple ID | Period | USD base price | Level |
| --- | --- | --- | --- | --- |
| com.sanadtherapy.app.weekly | 6817911709 | One week | 7.90 | 4 |
| com.sanadtherapy.app.basic | 6817912236 | One month | 19.90 | 3 |
| com.sanadtherapy.app.premium | 6817912241 | One month | 34.90 | 2 |
| com.sanadtherapy.app.premium_vip | 6817905001 | One month | 54.90 | 1 |

Inspect the catalog using `scripts/setup-app-store-subscriptions.js` with `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_KEY_PATH` supplied in the environment. The default is read-only; `--apply` creates missing draft metadata/pricing/availability, and `--metadata-only` omits pricing. Never place private keys in the repository. This script does not submit products for review.

Completed October 1, 2026: all four products and the group have Arabic, English and French localizations. Review screenshots from the actual Flutter paywall are uploaded and processed (`COMPLETE`), and all products reached `READY_TO_SUBMIT`. These are widget-rendered screenshots, not proof of a device purchase. All four products and the group have been added to one unsubmitted review draft. The app is available in 174 territories, with France excluded for the initial release; subscription pricing remains configured in 175 territories.

The approved In-App Purchase key `F663JQ23MG` is stored outside the repository with restricted file permissions and in Firebase Secret Manager (`APP_STORE_PRIVATE_KEY`, version 1). The three functions and security rules are deployed. Both Apple notification URLs are configured as V2. Nonsecret deployment environment values are in the gitignored `functions/.env.sanad-app-beldify`.

Apple's genuine Sandbox `TEST` notification reached the deployed endpoint with **SUCCESS**, reconfirmed October 1, 2026. Both V2 URLs are confirmed saved by the App Store Connect API. Production rejects Apple's `POST /inApps/v1/notifications/test` with HTTP 401 before issuing a test token or attempting endpoint delivery; this is not a rejection from the Firebase notification endpoint. A controlled test with the same correctly signed, unexpired JWT returned Sandbox 200 and Production 401, with the server clock matching Apple's response date.

Production access is blocked until Sanad has a production release: App Store Connect currently lists only version `1.0.25` in `PREPARE_FOR_SUBMISSION`, with no previous released version. An [Apple App Store Commerce Engineer confirms that production API access unlocks after a production release](https://developer.apple.com/forums/thread/806452). No credential rotation or server change is indicated. Repeat the Production test immediately after the first production release and confirm **SUCCESS**; Production delivery remains unverified until then. Sandbox purchase, restore and renewal device tests still need to be completed before submission.

## Activation requirements

1. Completed: Paid Apps and Free Apps agreements, banking, and both US tax forms are **Active**, verified October 1, 2026 in [App Store Connect Business](https://appstoreconnect.apple.com/business). EU trader verification remains **In Review**.
2. Completed after explicit credential approval: **In-App Purchase key** `Sanad Subscription Server` is stored securely outside the repository and in Firebase Secret Manager as `APP_STORE_PRIVATE_KEY`. A general App Store Connect catalog API key cannot authenticate the App Store Server API. [Apple key instructions](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/generate-keys-for-in-app-purchases).
3. Set these nonsecret values in the Functions project environment:

   ```dotenv
   APP_STORE_KEY_ID=F663JQ23MG
   APP_STORE_ISSUER_ID=8129ee3d-6a41-496a-8f1c-2cb67c1a75df
   APP_STORE_ALLOW_SANDBOX=true
   ```

   Enable sandbox for TestFlight/App Review; sandbox verification still validates Apple signatures, this bundle, known products and the signed-in user's account token. Sandbox payment records have explicit environment markers and distinct document IDs.

4. Deploy only the required functions and rules after credentials are configured:

   ```sh
   firebase deploy --project sanad-app-beldify --only functions:prepareAppStorePurchase,functions:verifyAppStorePurchase,functions:appStoreNotifications,firestore:rules
   ```

5. Set both Production and Sandbox **App Store Server Notifications V2** URLs to:

   ```text
   https://us-central1-sanad-app-beldify.cloudfunctions.net/appStoreNotifications
   ```

   Send an Apple Sandbox test notification and confirm the deployed endpoint accepts it before submission. Configure these URLs in the app's App Information page after deployment. After the first production release unlocks the Production API, repeat the Production test and confirm delivery succeeds.

   `scripts/test-app-store-notifications.js` requests genuine Apple signed tests in both environments and reports delivery status. Supply `APP_STORE_KEY_PATH`, `APP_STORE_KEY_ID`, and `APP_STORE_ISSUER_ID`; it never prints the key, signed payload or notification token.
6. Screenshots and localizations are complete. Apple's current workflow adds the subscription group, four subscriptions, and app version to the **same draft review submission**; the old app-version subscription selector is no longer the documented workflow. Draft ID: `d3eb11d5-16ba-4e13-8dd7-628ff96bebd8`. The group and four products are present. Build 50 is selected, and a 13-inch iPad screenshot of the actual subscription widget is uploaded and processed as COMPLETE (2064×2752, English app locale, JPEG with no alpha channel). The app version cannot join the draft until the final App Privacy Publish confirmation is completed. Screenshot provenance: build/app-store-review/ipad/provenance.json. First subscriptions must be reviewed together with a new app version. [Apple submission guide](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase).
7. Signed iOS `1.0.25 (50)` is uploaded and processed as `VALID`, with build ID `d1ca54f5-0afd-4bbf-9aa5-5931acd2c724`. Its standard encryption/France-excluded declaration is saved. App Review version `1.0.25` now selects this build. Internal TestFlight group `Sanad Subscription QA` contains the owner tester and build 50; automatic distribution remains disabled. Bilingual test instructions cover native subscriptions, consent/revocation, account isolation, human chat and local insights. Device purchase/restore/renewal checks remain outstanding because the iPhone is unavailable.

   ```sh
   flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
   ```

   The export settings select the existing `Sanad AppStore` profile for HM5 Group; the default Flutter export omitted the required manual mapping. The profile includes the app's existing Apple Pay, push and Sign in with Apple capabilities.

## Owner and Android release status

The owner confirmed all content is owned or licensed; Apple's content-rights declaration is saved. The review contact is configured, and review notes explain native purchases, restoration and explicit Gemini consent. The owner has said there is no registered company. [Apple guideline 5.1.1(ix)](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage) requires the legal entity providing healthcare or sensitive-data services to submit these apps. Account/legal-entity eligibility remains an owner requirement; the HM5 Group team name alone does not establish registration.

The correct Google Play owner account is accessible. Its existing app-content/data declarations are completed and no policy issue is displayed. Production still runs `45 (1.0.21)`. A `1.0.25 (50)` production release draft with Arabic consent/privacy release notes is saved. The signed AAB is built and verified (ZIP integrity, signature, embedded version name and merged release manifest); provenance is in `build/release-archive/sanad-50-aab-provenance.json`. Upload is blocked by Chrome extension file access; enable "Allow access to file URLs" or upload `build/app/outputs/bundle/release/app-release.aab` manually. At the user's direction, existing data-category declarations are preserved. OAuth and partial-deletion-link corrections are saved only as a declaration draft. The previously broken deletion URL now serves the verified bilingual [account-deletion page](https://sanadtherapy.com/data-deletion.html).

The explicit AI consent callable, guarded chat/report functions and security rules are deployed. Their unauthenticated endpoints reject requests with `UNAUTHENTICATED`. Existing AR/EN CMS privacy paragraphs and the website policy are published and verified, including Gemini sharing, authorized staff/processors, safety alerts and revocation. Apple's 14 privacy response drafts are complete, linked to identity and marked no tracking; final Publish awaits the owner's legal confirmation. Calling SDK diagnostics are linked because ZEGOCLOUD's [analytics documentation](https://www.zegocloud.com/docs/admin-console/function-introduction?language=all&platform=all) identifies user/device information in call-quality reports. Older apps cannot create the new consent record and must update before using Gemini.

## Device verification

- Signed-in purchase: confirm native price/period, approve in the sandbox, verify the user plan and exact expiry match Apple's signed transaction; the payment ID must appear once.
- Restore on another device using the same Sanad account. Restoring with a different Sanad account must be rejected and must not grant access.
- Cancel and pending/Ask to Buy flows must not grant access prematurely. Complete a pending transaction and confirm verification succeeds.
- Disconnect the server during purchase, then restore/retry. The transaction stays unfinished until verification succeeds and further purchases are blocked during unresolved verification.
- Sandbox renewals, expiry, refund and billing grace: notification processing must fetch current Apple status, preserve paid access after auto-renew is canceled, expire/refund correctly, and avoid duplicate payment records.
- Upgrade/downgrade between group levels and test a delayed old notification; it must not overwrite the selected newer subscription.
- Open Manage/Cancel Subscription, Privacy Policy and Terms of Use in each supported locale.

## Verification and merge danger

Backend tests: `cd functions && npm test`.

Flutter subscription tests: `flutter test test/features/subscription`.

Rules tests from the project root:

```sh
firebase emulators:exec --project demo-sanad-rules --only firestore --config firebase.rules-test.json 'cd functions && node --test test/appStoreRules.test.js'
```

The iOS debug build was verified with `flutter build ios --no-codesign --debug`. Automated tests do not replace a real sandbox purchase or Apple review.

Latest October 1 automated results: 132 backend tests, 256 focused Flutter tests and 14 Firestore emulator tests passed. Analysis of the 27 changed Dart files found no issues. The website static release build passed lint/type checks and export. The signed IPA was verified to contain the compiled StoreKit 2 plugin and privacy bundle, with bundle/version/build `com.sanadtherapy.app / 1.0.25 / 50`; artifact provenance is in `build/release-archive/sanad-50-ipa-provenance.json`.

Code and rules can be rolled back. Published product IDs and Apple review/subscription state are external commitments; do not delete or reuse them. The main failure mode is missing credentials or notifications leaving paid access unavailable or stale. Deploy/configure the server before distributing the purchasing build, then verify a real purchase and renewal.

Apple entitlement fields and account mappings are server-controlled, and owners cannot promote themselves to admin. Existing non-Apple user entitlement writes remain client-controlled to preserve current checkout flows; migrating that broader legacy authority is a separate hardening task.

## Scheduled backend maintenance

The successful October 1 deployment reports that Node.js 20 will be decommissioned on October 30, 2026. Upgrade the Functions runtime before that deadline, with a reviewed SDK/config migration and verification of the existing functions. This runtime migration is separate from the targeted consent deployment completed here. [Google runtime schedule](https://cloud.google.com/functions/docs/runtime-support).
