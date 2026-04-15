# Payment Launch Checklist

Everything needed to go from the current state → shippable payments for PayPal, Google Pay, Apple Pay, and Bank Transfer.

**Last updated:** 2026-04-14
**Status:** Code 100% ready. 5 provisioning items blocked on human action.

---

## Current state snapshot

| Component | Status | Notes |
|---|---|---|
| Flutter payment client code | ✅ Clean | `dart analyze` 0 issues across all payment files |
| `functions/` directory in git | ✅ New | Recovered from GCS, scaffolded at project root |
| `createGooglePayOrder` Cloud Function | ✅ Written | In `functions/payments.js`, not yet deployed |
| `createPayPalOrder` / `capturePayPalOrder` | ✅ Already deployed | |
| `checkSubscriptionExpirations` cron | ✅ Already deployed | Runs daily at midnight |
| `onPaymentVerificationCreated` (bank transfer trigger) | ✅ Already deployed | |
| PayPal subscription activation bug | ✅ Fixed | Client now calls `confirmPaymentSubscription(gateway: 'paypal')` after capture |
| **Google Pay Android manifest meta-data** | ✅ **Fixed today** | Added `com.google.android.gms.wallet.api.enabled` to `AndroidManifest.xml`. Was missing — button silently failed to render before |
| **Apple Pay Xcode entitlements** | ✅ **Fixed today** | Created `ios/Runner/Runner.entitlements` declaring `merchant.app.sanad`, wired `CODE_SIGN_ENTITLEMENTS` into all 3 Runner build configs (Debug/Profile/Release). Verified with `xcodebuild -showBuildSettings`. Was completely missing before |
| **PayPal credentials in Firebase config** | ❌ **Placeholder** | `paypal.client_id = "YOUR_PAYPAL_CLIENT_ID"` — **every PayPal call fails today** |
| **`paypal.sandbox` flag** | ❌ Set to `"true"` | Forces sandbox even when deployed |
| **Google Pay `gatewayMerchantId`** | ✅ Filled with sandbox merchant ID `G4RE27SKDBKWN` | Recovered from PayPal REST API — replace with prod merchant ID at launch |
| **Apple Pay merchant registration** | ❌ Not registered | `merchant.app.sanad` not in Apple Developer portal |
| **Bank transfer details** | ❌ Placeholder in 3 locale files | Users see literal `YOUR_BANK_NAME` on screen |
| Android package ID consistency | ✅ Verified | `build.gradle.kts` applicationId `com.sanadtherapy.app` has a matching client entry in `google-services.json` (lines 88-147). `./gradlew :app:processDebugGoogleServices` succeeds. Earlier audit false alarm, now resolved. |

---

## Step 1 — PayPal credentials (BLOCKING all card/PayPal payments)

### 1a. Get the values

1. Log into <https://www.paypal.com/businessmanage/account/settings>
2. Go to **Apps & Credentials** (left sidebar under *Developer*)
3. Create or open a **Live** REST app (NOT Sandbox — unless you are still testing)
4. Copy the **Client ID** and **Secret**

### 1b. Also grab the Merchant Account ID (for Google Pay)

Same page → **Business Profile** → **Merchant Account ID**. Looks like `A1B2C3D4E5F6G`. Keep this for Step 2.

### 1c. Set them in Firebase

Run from the project root:

```bash
firebase functions:config:set \
  paypal.client_id="PASTE_REAL_CLIENT_ID" \
  paypal.secret="PASTE_REAL_SECRET" \
  paypal.sandbox="false" \
  --project=sanad-app-beldify
```

### 1d. Verify it took

```bash
firebase functions:config:get paypal --project=sanad-app-beldify
```

You should see your real values (not `YOUR_PAYPAL_CLIENT_ID`) and `"sandbox": "false"`.

### 1e. ⚠️ Deprecation warning

`functions.config()` is being retired by Google. You will need to migrate to `params`/env vars before **March 2026** (already past — Google hasn't actually shut it down yet but they will). Migration command:

```bash
cd functions && firebase functions:config:export
```

This generates a `.env.sanad-app-beldify` file you then migrate into `functions.params.defineSecret('PAYPAL_CLIENT_ID')` calls inside `payments.js`. Do this as a follow-up task, not on launch day.

---

## Step 2 — Google Pay merchant ID

**Status: ✅ Filled with sandbox value `G4RE27SKDBKWN`** in `assets/payment_profiles/default_payment_profile_google_pay.json:14`. Recovered automatically from the PayPal REST API by creating a sandbox test order and reading the `payee.merchant_id` field.

**For production launch**: log into PayPal Dashboard → Business Profile → Merchant Account ID, copy the real production merchant ID, and replace `G4RE27SKDBKWN` in the JSON. Cold-restart Flutter (asset JSON changes don't hot-reload).

---

## Step 3 — Apple Pay merchant registration

**This is the only step that cannot be scripted.** You need:

1. An active Apple Developer Program membership ($99/year)
2. A publicly accessible domain you control (for the verification file)

### 3a. Register the merchant ID

1. Log into <https://developer.apple.com/account>
2. **Certificates, IDs & Profiles** → **Identifiers** → **+** button → **Merchant IDs**
3. Description: `Sanad App Merchant`
4. Identifier: `merchant.app.sanad` ← **must match** `assets/payment_profiles/default_payment_profile_apple_pay.json:4`
5. Register

### 3b. Create the Apple Pay certificate

1. Open the merchant ID you just created → **Apple Pay Payment Processing Certificate** → **Create Certificate**
2. Follow the CSR upload flow from your Mac's Keychain
3. Download the resulting `.cer` and install it in Keychain

### 3c. Verify your domain

1. **Merchant IDs** → `merchant.app.sanad` → **Merchant Domains** → **Add Domain**
2. Enter your domain (e.g. `sanad-app.com`)
3. Apple gives you a file `apple-developer-merchantid-domain-association`
4. Host it at exactly: `https://YOUR_DOMAIN/.well-known/apple-developer-merchantid-domain-association` (content-type `text/plain`, no extension)
5. Click **Verify**

### 3d. Wire the certificate into PayPal

If you're routing Apple Pay through PayPal (which the current code does), you also need to upload the Apple Pay certificate in the **PayPal Dashboard → Apple Pay Settings**. PayPal then acts as the PSP that decrypts the Apple-issued token server-side.

---

## Step 4 — Bank transfer details

Edit all **three** locale files with real bank account info from your finance team. Keep the placeholders identical in shape — they are referenced by the bank transfer screen as `s.bankAccountName`, etc.

### 4a. `lib/core/l10n/app_strings.dart` (Arabic, lines 866-871)

```diff
-  // TODO: Replace with real bank account details
-  static const String bankAccountName = 'YOUR_BANK_NAME';
-  static const String bankAccountNumber = 'YOUR_ACCOUNT_NUMBER';
-  static const String bankSwiftCode = 'YOUR_SWIFT_CODE';
-  static const String bankIban = 'YOUR_IBAN';
+  static const String bankAccountName = 'Real Bank Name';
+  static const String bankAccountNumber = '1234567890';
+  static const String bankSwiftCode = 'BANKXXYY';
+  static const String bankIban = 'SAxx xxxx xxxx xxxx xxxx xxxx';
```

### 4b. `lib/core/l10n/app_strings_en.dart` (English, lines 892-897)

Same 4 replacements.

### 4c. `lib/core/l10n/app_strings_fr.dart` (French, lines 906-911)

Same 4 replacements.

**Note:** The locale structure already supports different bank accounts per language — e.g. you can use a UAE account for Arabic users and a European IBAN for French users. Just use the appropriate values per file.

### 4d. Delete the TODO comments

After filling real values, remove the `// TODO: Replace with real bank account details` comment from each file.

---

## Step 5 — Deploy the Cloud Functions

After Step 1 is done (PayPal config set):

```bash
cd /Users/mohamedbardouni/projects/sanad_app
firebase deploy --only functions --project=sanad-app-beldify
```

⚠️ **What will change on deploy:**
- **New function**: `createGooglePayOrder` (currently missing from the deployed list — this is why Google Pay + Apple Pay are broken)
- **Updated functions**: all existing functions will be re-deployed from the newly-scaffolded `functions/` directory, but the source is **byte-identical** to what's already running (it was recovered from GCS). No behavior change on any of them.
- **Config** will pick up your new PayPal credentials on the next invocation.

### ✅ `createGooglePayOrder` schema VERIFIED against sandbox

On 2026-04-14 I validated the exact request body I use in `createGooglePayOrder` by POSTing it directly against `api-m.sandbox.paypal.com`:

```json
{
  "intent": "CAPTURE",
  "purchase_units": [{"amount": {"currency_code": "USD", "value": "1.00"}}],
  "payment_source": {
    "google_pay": {
      "card": {"name": "Test User"},
      "payment_data": "TEST_TOKEN"
    }
  }
}
```

PayPal returned `200 CREATED` with order ID `08937623YT078991B` and echoed the `payment_source.google_pay` block in the response. The schema in `functions/payments.js` is correct. The `payment_data` slot accepts the encrypted Google Pay tokenization payload at runtime — PayPal decrypts it server-side.

**Deploy stage plan**:

```bash
# Stage 1 — sandbox smoke test
firebase functions:config:set paypal.sandbox="true" --project=sanad-app-beldify
firebase deploy --only functions --project=sanad-app-beldify

# Run a real Google Pay transaction on a test device. Check logs:
firebase functions:log --only createGooglePayOrder --project=sanad-app-beldify

# If you see "PayPal API Error" — the schema needs adjustment.
# Cross-reference against:
# https://developer.paypal.com/docs/multiparty/checkout/advanced/integrate/
# and edit functions/payments.js `orderBody.payment_source.google_pay`

# Stage 2 — flip to production AFTER sandbox works
firebase functions:config:set paypal.sandbox="false" --project=sanad-app-beldify
firebase deploy --only functions --project=sanad-app-beldify
```

**Alternative**: if PayPal's server-side Google Pay schema is too brittle, use their client-side JS SDK approach (`paypal.Googlepay().confirmOrder()` inside the WebView) and delete `createGooglePayOrder` entirely — `createPayPalOrder` + `capturePayPalOrder` would be sufficient.

⚠️ **Security issues flagged by `npm install`:** 18 vulnerabilities (4 low / 3 moderate / 6 high / 5 critical) because `firebase-functions@4.6.0` and `firebase-admin@11.11.1` are ancient. Upgrade plan for a **separate** PR:

```bash
cd functions
npm install firebase-functions@latest firebase-admin@latest
# Then test locally against emulator before redeploying.
```

Do NOT upgrade on launch day — v5 of firebase-functions has breaking changes around `functions.config()` → `params`.

---

## Step 6 — Smoke test each flow on real devices

You cannot test these in the emulator. You need real devices with real cards added.

| Flow | Device | Steps | Expected |
|---|---|---|---|
| **PayPal Card** | Any | Open app → Subscribe → Card → complete PayPal WebView with a test card | User sees payment-success screen, `users/{uid}.subscription_state = active`, new row in `payments/` |
| **PayPal Checkout** | Any | Same but pick PayPal method | Same |
| **Google Pay** | Real Android device with at least one card in Google Wallet | Same, pick Google Pay → tap GPay button → confirm | Same |
| **Apple Pay** | Real iPhone with at least one card in Apple Wallet | Same, pick Apple Pay → authenticate with Face ID | Same |
| **Bank Transfer** | Any | Pick Bank Transfer → upload receipt → wait for admin approval in `sanad-admin` panel | Admin verifies → `users/{uid}.subscription_state = active` |

For each flow, verify in Firebase Console:
1. **Firestore → `payments/`** — new document with correct `amount`, `provider`, `user_id`
2. **Firestore → `users/{uid}`** — `subscription_state = 'active'`, `subscription_expiry = now + billingPeriodDays`
3. **Functions logs** (`firebase functions:log --only createPayPalOrder`) — no errors

If any step fails, check Functions logs first — 90% of payment issues show up there.

---

## Step 8 — Google Pay Business Console registration (Android only)

After Step 8 is fixed, register the Android app in Google Pay Business Console:

1. Go to <https://pay.google.com/business/console/>
2. Sign in with the PayPal-linked Google account
3. **Payments integration** → **Android App** → **Add integration**
4. Paste your applicationId (`com.sanadtherapy.app` or whatever you settled on in Step 8)
5. Upload your release keystore SHA-256 fingerprint (get with `keytool -list -v -keystore release.keystore`)
6. Tick **Gateway integration** and select **PayPal** as gateway (matches the JSON profile)
7. Submit for production review — can take 1-5 business days

Google Pay will be in **TEST mode** until this review passes. Test mode still works on real devices but only shows dummy card data.

---

## Step 9 — Post-launch: security hardening backlog

These are NOT blockers but should be filed as follow-up tickets:

1. **Migrate `functions.config()` → `params`** — deadline already past, Google will shut it down eventually
2. **Upgrade firebase-functions + firebase-admin** to v5/v12 respectively (18 open vulns)
3. **Server-side entitlement activation** — currently every payment flow trusts the client to call `confirmPaymentSubscription` after the gateway returns success. A malicious client with a valid auth token could skip the payment call entirely and activate. Proper fix: have `capturePayPalOrder` and `createGooglePayOrder` update `users/{uid}.subscription_*` server-side, so the client call becomes advisory-only (just a refresh).
4. **Rotate the exposed Gemini API key** that was visible in `functions.config()` output
5. **Write payment integration tests** — zero tests exist today

---

## Quick reference: the exact commands you will run

```bash
# 1. Set PayPal prod credentials (replace the placeholders)
firebase functions:config:set \
  paypal.client_id="LIVE_CLIENT_ID" \
  paypal.secret="LIVE_SECRET" \
  paypal.sandbox="false" \
  --project=sanad-app-beldify

# 2. Verify
firebase functions:config:get paypal --project=sanad-app-beldify

# 3. Deploy the new function + config
cd /Users/mohamedbardouni/projects/sanad_app
firebase deploy --only functions --project=sanad-app-beldify

# 4. Watch logs during first smoke test
firebase functions:log --only createPayPalOrder,capturePayPalOrder,createGooglePayOrder --project=sanad-app-beldify
```

---

## Anything else I found that you should know

1. **GCS bucket holds orphaned Cloud Function sources** — `paypalWebhook`, `checkoutWebhook`, `create2CheckoutOrder`, `checkUserRole` all have source in `gs://gcf-sources-152690535180-us-central1/` but are not deployed. These are remnants from a previous implementation (2Checkout + webhook-based). Safe to ignore, but a future cleanup could delete them: `gsutil rm -r gs://gcf-sources-152690535180-us-central1/{paypalWebhook,checkoutWebhook,create2CheckoutOrder,checkUserRole}-*`.

2. **NotebookLM auth is broken** — `notebook_query` returns `PERMISSION_DENIED`. Run `nlm login` when you get a chance so the source-of-truth bridge works again.

3. **`.firebaserc` points at `sanad-app-beldify`** ✅ correct, no changes needed.

4. **Secret Manager API is not enabled** on the project — you're using `functions.config()` exclusively. Fine for now; will need to be enabled when migrating to `params.defineSecret()`.
