---
name: PayPal WebView Flow
description: Card and PayPal checkout via WebView — cancel URL detection fix, deep-link interception, dead code cleanup
type: concept
sources: [daily/2026-04-13.md]
created: 2026-04-13
updated: 2026-04-13
---

# PayPal WebView Flow

The Sanad App handles credit/debit card payments and PayPal Checkout through an in-app WebView that loads PayPal's hosted payment pages. During the 2026-04-13 session, a critical bug in cancel detection was fixed, and dead code was identified for cleanup.

## Key Points

- Card payments (`card_payment_screen.dart`) and PayPal Checkout (`paypal_payment_screen.dart`) both use a `WebViewWidget` to load PayPal's hosted payment page.
- PayPal redirects to custom deep links: `sanad://payment/success` on approval, `sanad://payment/cancel` on cancellation.
- The cancel detection was narrowed from `url.contains('cancel')` to `url.startsWith('sanad://payment/cancel')` to prevent false-positive cancellations when URLs happen to contain the word "cancel" elsewhere.
- The `_buildCardFormHtml` method and `html` variable in `card_payment_screen.dart` are dead code — remnants of a previous direct card form approach that was replaced by PayPal-hosted pages.
- The `capturePayPalOrder` Cloud Function is called after the user approves to finalize the transaction.

## Details

The WebView payment flow begins when the app calls the `createPayPalOrder` Cloud Function, which returns an `approvalUrl`. This URL is loaded in a `WebViewWidget`. The user interacts with PayPal's hosted page to enter card details or log into their PayPal account. PayPal then redirects to a custom deep link scheme (`sanad://`), which the WebView's `onNavigationRequest` callback intercepts.

The cancel URL detection bug was a subtle issue: the original check `url.contains('cancel')` would trigger false cancellations if PayPal included the word "cancel" anywhere in intermediate navigation URLs (e.g., a "cancel your order" link on the payment page itself, or a query parameter). By narrowing to `url.startsWith('sanad://payment/cancel')`, the detection now only fires on the actual deep-link redirect from PayPal, eliminating false positives.

The dead code in `card_payment_screen.dart` (`_buildCardFormHtml` method and associated `html` variable) dates from an earlier approach where the app attempted to render its own card input form in an HTML WebView. This was replaced by the current PayPal-hosted approach, but the old code was never cleaned up. It should be removed when the file is next modified to reduce confusion.

## Related Concepts

- [[concepts/payment-system]] — Parent payment architecture; WebView flow handles card and PayPal checkout methods
- [[concepts/apple-pay-integration]] — Alternative native payment method that bypasses the WebView entirely
- [[concepts/google-pay-paypal-gateway]] — Alternative native payment method using PayPal as gateway without WebView

## Sources

- [[daily/2026-04-13.md]] — Cancel URL detection narrowed from `contains` to `startsWith`; dead code `_buildCardFormHtml` identified; PayPal WebView flow documented
