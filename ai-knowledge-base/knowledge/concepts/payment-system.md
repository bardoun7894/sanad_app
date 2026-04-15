---
name: Payment System
description: Multi-gateway payments: Google Pay, Apple Pay, PayPal card, bank transfer. Config requirements, flow, known TODOs.
type: concept
sources: [daily/2026-04-13.md]
created: 2026-04-13
updated: 2026-04-13
---

# Payment System

## Architecture

The app uses a multi-gateway payment system. All card processing is delegated to **PayPal** (no direct PCI scope). Firebase Cloud Functions serve as the backend orchestrator.

## Payment Methods

| Method | Screen | Backend | Status |
|--------|--------|---------|--------|
| Google Pay (Android) | `google_pay_screen.dart` | `createGooglePayOrder` CF | Config requires PayPal merchant ID |
| Apple Pay (iOS) | `apple_pay_screen.dart` | `createGooglePayOrder` CF | Requires Apple merchant identifier |
| Credit/Debit Card (Visa, MC) | `card_payment_screen.dart` | `createPayPalOrder` + `capturePayPalOrder` CF | PayPal WebView, working |
| PayPal Checkout | `paypal_payment_screen.dart` | `createPayPalOrder` + `capturePayPalOrder` CF | Working |
| Bank Transfer | WhatsApp deep link | Manual admin approval | Working |

## Configuration Files

- **Google Pay profile**: `assets/payment_profiles/default_payment_profile_google_pay.json`
  - Gateway: `paypal` (production)
  - **Requires**: `YOUR_PAYPAL_MERCHANT_ACCOUNT_ID` → get from PayPal business dashboard → Account Settings → Business Profile
- **Apple Pay profile**: `assets/payment_profiles/default_payment_profile_apple_pay.json`
  - **Requires**: `merchant.app.sanad` → must be registered in Apple Developer account (Identifiers → Merchant IDs)

## PayPal Credentials (production)

Stored in `payment_gateway_service.dart`:
- Client ID: `ASSwN06x...`
- `isSandbox: false` → points to `https://api-m.paypal.com`

## Cloud Functions Required

| Function | Called From | Purpose |
|----------|-------------|---------|
| `createPayPalOrder` | `PaymentGatewayService` | Creates PayPal order, returns `approvalUrl` |
| `capturePayPalOrder` | `PaymentGatewayService` | Finalizes PayPal order after user approval |
| `createGooglePayOrder` | `PaymentGatewayService` | Processes Google Pay / Apple Pay token through PayPal |

## Payment Flow — Card (Visa/MC via PayPal WebView)

1. `CardPaymentScreen` calls `createPayPalOrder` Cloud Function
2. Gets `approvalUrl` → loads in `WebViewWidget`
3. User enters card details on PayPal's hosted page
4. PayPal redirects to `sanad://payment/success?token=ORDER_ID&PayerID=PAYER_ID`
5. WebView's `onNavigationRequest` intercepts → calls `capturePayPalOrder`
6. On success → `subscriptionProvider.checkSubscription()` → navigate to success screen

## Payment Flow — Google Pay / Apple Pay

1. `GooglePayButton` / `ApplePayButton` (from `pay` package) tokenizes card via PayPal gateway
2. `_onGooglePayResult` / `_onApplePayResult` extracts `paymentToken` from result
3. Calls `createGooglePayOrder` Cloud Function with token + userId + amount
4. On success → `subscriptionProvider.confirmGooglePaySubscription({'orderId': ...})`
5. Navigate to success screen

## Subscription State Updates

- `SubscriptionRepository.updateSubscriptionStatus()` → writes to Firestore `users/{uid}` + `payments/{id}`
- `confirmGooglePaySubscription` in `subscription_provider.dart` hardcodes `productId: 'monthly_premium'` — may need to pass the actual product ID

## Bank Transfer Details (configure in locale files)

All bank details live in `app_strings.dart` / `app_strings_en.dart` / `app_strings_fr.dart` — search for `bankAccountName`. Replace the `YOUR_*` placeholders with your real account info:

| Key | Files | Default |
|-----|-------|---------|
| `bankAccountName` | all 3 locale files | `YOUR_BANK_NAME` |
| `bankAccountNumber` | all 3 locale files | `YOUR_ACCOUNT_NUMBER` |
| `bankAccountHolder` | all 3 locale files | `Sanad App` |
| `bankSwiftCode` | all 3 locale files | `YOUR_SWIFT_CODE` |
| `bankIban` | all 3 locale files | `YOUR_IBAN` |
| `supportWhatsAppNumber` | all 3 locale files | `971554503909` |

Reference code is now dynamic: `REF-{UID6}-{YYYYMMDD}-{SUFFIX}` — generated in `BankTransferScreen.initState()`.

## Changes Made (2026-04-13)

Key fixes applied during the 2026-04-13 session:

- **Google Pay gateway**: changed from `"example"` to `"paypal"`, environment set to `PRODUCTION` — see [[concepts/google-pay-paypal-gateway]]
- **Apple Pay**: screen built from scratch (was a `// TODO` stub) — see [[concepts/apple-pay-integration]]
- **Bank transfer**: reference code made dynamic (`REF-{UID6}-{YYYYMMDD}-{SUFFIX}`), bank details moved to locale files — see [[concepts/bank-transfer-localization]]
- **PayPal WebView cancel URL**: narrowed from `url.contains('cancel')` to `url.startsWith('sanad://payment/cancel')` to prevent false positives — see [[concepts/paypal-webview-flow]]
- **Dead code identified**: `_buildCardFormHtml` method and `html` variable in `card_payment_screen.dart` are remnants of a previous direct card form approach

## Related Concepts

- [[concepts/google-pay-paypal-gateway]] — Google Pay gateway configuration with PayPal
- [[concepts/apple-pay-integration]] — Apple Pay screen, merchant ID, and domain verification
- [[concepts/bank-transfer-localization]] — Dynamic reference codes and locale-based bank details
- [[concepts/paypal-webview-flow]] — WebView-based card and PayPal checkout flow
- [[connections/payment-methods-and-localization]] — How bank transfer bridges payment and i18n systems

## Sources

- [[daily/2026-04-13.md]] — Full payment system audit and fixes: Google Pay gateway, Apple Pay screen creation, bank transfer localization, WebView cancel fix

## Known Issues / TODOs

1. **Google Pay `gatewayMerchantId`**: `YOUR_PAYPAL_MERCHANT_ACCOUNT_ID` in `assets/payment_profiles/default_payment_profile_google_pay.json` → get from PayPal dashboard → Account Settings → Business Profile
2. **Apple Pay merchant identifier**: `merchant.app.sanad` in `assets/payment_profiles/default_payment_profile_apple_pay.json` → must match Apple Developer portal registration; also requires domain verification file on server
3. **Bank details**: all `YOUR_*` placeholders in locale files need real account info
4. **`confirmGooglePaySubscription`** in `subscription_provider.dart` hardcodes `productId: 'monthly_premium'` — pass actual product ID
