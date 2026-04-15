---
name: Apple Pay Integration
description: Apple Pay screen built from scratch in Sanad App — merchant ID registration, domain verification, and PayPal token flow
type: concept
sources: [daily/2026-04-13.md]
created: 2026-04-13
updated: 2026-04-13
---

# Apple Pay Integration

The Sanad App Apple Pay integration was built from scratch during the 2026-04-13 session. The original codebase contained only a `// TODO: redirect to card` stub — no functional Apple Pay screen existed prior to this work. The implementation follows the same PayPal-as-gateway pattern used by [[concepts/google-pay-paypal-gateway]] and the broader [[concepts/payment-system]].

## Key Points

- `apple_pay_screen.dart` was created from scratch — the previous stub had no real implementation.
- Apple Pay uses the `pay` Flutter package with a `ApplePayButton` widget that tokenizes the card via the PayPal gateway.
- The payment profile lives at `assets/payment_profiles/default_payment_profile_apple_pay.json` with a placeholder `merchant.app.sanad` identifier.
- Apple Pay requires **both** a Merchant ID registered in the Apple Developer portal (Identifiers -> Merchant IDs) **and** a domain verification file hosted on the server.
- The route was wired into `app_router.dart` as part of the implementation.

## Details

Unlike Google Pay, which only requires a PayPal merchant ID in its JSON profile, Apple Pay has a two-step verification requirement. First, the merchant identifier (`merchant.app.sanad`) must be registered in the Apple Developer portal under Identifiers -> Merchant IDs. Second, Apple requires a domain verification file to be hosted on the web server — this is a step that is easy to overlook since it is external to the Flutter codebase.

The payment flow mirrors the Google Pay path: the `ApplePayButton` from the `pay` package tokenizes the card using PayPal as the gateway, then the `_onApplePayResult` handler extracts the `paymentToken` and calls the `createGooglePayOrder` Cloud Function (shared with Google Pay) with the token, userId, and amount. On success, the subscription is confirmed and the user navigates to a success screen.

The profile configuration file uses a placeholder merchant identifier that must be replaced before going live. This is tracked as a known TODO in the [[concepts/payment-system]] article.

## Related Concepts

- [[concepts/payment-system]] — Parent payment architecture; Apple Pay is one of five supported methods
- [[concepts/google-pay-paypal-gateway]] — Sibling payment method sharing the same Cloud Function backend
- [[concepts/paypal-webview-flow]] — Alternative payment path for card/PayPal checkout users

## Sources

- [[daily/2026-04-13.md]] — Apple Pay screen created from scratch; domain verification requirement discovered; route added to `app_router.dart`
