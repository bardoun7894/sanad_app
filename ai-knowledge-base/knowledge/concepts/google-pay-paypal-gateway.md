---
name: Google Pay PayPal Gateway
description: Google Pay configured with PayPal as gateway in production mode — merchant ID requirement and token flow
type: concept
sources: [daily/2026-04-13.md]
created: 2026-04-13
updated: 2026-04-13
---

# Google Pay PayPal Gateway

Google Pay in the Sanad App is configured to use **PayPal** as the payment gateway in **production** mode. During the 2026-04-13 session, the gateway was changed from the placeholder `"example"` to `"paypal"` and the environment was switched from test to `PRODUCTION`.

## Key Points

- The Google Pay payment profile at `assets/payment_profiles/default_payment_profile_google_pay.json` was updated: gateway `"example"` -> `"paypal"`, environment -> `PRODUCTION`.
- The profile requires a real `gatewayMerchantId` — currently a `YOUR_PAYPAL_MERCHANT_ACCOUNT_ID` placeholder.
- The merchant ID is found in PayPal Dashboard -> Account Settings -> Business Profile.
- Google Pay uses the `pay` Flutter package with a `GooglePayButton` widget.
- The backend Cloud Function `createGooglePayOrder` is shared with [[concepts/apple-pay-integration]].

## Details

The Google Pay integration uses PayPal as an intermediary rather than connecting directly to card networks. This keeps the app out of direct PCI scope — all sensitive card processing is handled by PayPal. The `pay` Flutter package provides the `GooglePayButton` widget, which handles the native Google Pay sheet on Android devices. When the user authorizes, the package returns a `paymentToken` which is sent to the `createGooglePayOrder` Firebase Cloud Function.

The configuration change from `"example"` gateway to `"paypal"` was a critical fix — the example gateway is only valid for test environments and would cause failures in production. The environment flag was also set to `PRODUCTION` to ensure Google Pay validates against real payment credentials rather than test ones.

The `gatewayMerchantId` placeholder is the last remaining blocker for Google Pay to work in production. This value must match the merchant account ID from the PayPal business dashboard and cannot be a test value.

## Related Concepts

- [[concepts/payment-system]] — Parent payment architecture; Google Pay is one of five supported methods
- [[concepts/apple-pay-integration]] — Sibling payment method sharing the `createGooglePayOrder` Cloud Function
- [[concepts/paypal-webview-flow]] — Alternative payment path for users who prefer card entry via WebView

## Sources

- [[daily/2026-04-13.md]] — Gateway changed from `"example"` to `"paypal"`, environment set to PRODUCTION, merchant ID placeholder documented
