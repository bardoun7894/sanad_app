---
name: Freemius 3DS White Screen — Root Cause
description: Android WebView swallows window.open during 3DS because the plugin enables multiple windows but never implements onCreateWindow
type: source
sources: [raw/kimi/2026-07-17-freemius-3ds-white-screen.md]
created: "2026-07-29"
updated: "2026-07-29"
---
# Freemius 3DS White Screen — Root Cause

## Summary

Investigation into why the Freemius card checkout went white during the 3-D Secure step on Android. The cause is in `webview_flutter_android`, not in the Freemius page: the plugin's controller constructor enables multiple-window support but the `WebChromeClient` it registers never overrides `onCreateWindow`, so any `window.open` the 3DS flow issues is silently dropped and the user is left on a blank view. The chosen fix forces multiple-window support back off after the constructor has run, which routes the popup navigation into the existing WebView instead.

> The raw document is an unedited model reasoning stream — line-wrapped mid-word, containing mojibake, self-correcting several times, and ending mid-sentence. Only the conclusions below were extracted, and each was verified against the committed implementation rather than taken from the transcript.

## Key points

- `AndroidWebViewController`'s constructor calls `settings.setDomStorageEnabled(true)`, `setJavaScriptCanOpenWindowsAutomatically(true)` and `setSupportMultipleWindows(true)`.
- The `WebChromeClient` the plugin registers overrides `onProgressChanged`, `onGeolocationPermissionsShowPrompt`, `onShowFileChooser`, `onPermissionRequest`, `onConsoleMessage`, the JS dialog callbacks and the custom-view callbacks — but **not** `onCreateWindow`.
- With `setSupportMultipleWindows(true)` and no `onCreateWindow` override, the default implementation returns false and the popup is discarded. `window.open` is swallowed with no error.
- `AndroidWebViewController` in plugin version 3.16.9 exposes no public setter for multiple-window support, so the setting has to be reached through the native settings object.
- Fix: inject a proxy and call `settings.setSupportMultipleWindows(false)` **after** the plugin's constructor has run, so it overrides the `true` the constructor set. Pigeon messages are delivered in call order on a single engine, so the later `false` reliably wins.
- Secondary failure mode: `onPageStarted` firing without a matching `onPageFinished` leaves the loader up permanently. A ~25 second watchdog started in `onPageStarted` clears the loader rather than showing white forever; it is cancelled on reveal, on `onWebResourceError`, and in `dispose`.
- iOS is unaffected — `WKWebView` loads `window.open` and `target=_blank` in the same view by default when no UI delegate creates a new one.

## Implementation status

Confirmed present in `lib/core/widgets/payment_webview.dart` — the proxy calls `nativeWebView?.settings.setSupportMultipleWindows(false)`, with the reasoning recorded in the file's leading comment.

## See also

- [[concepts/webview-popup-handling]] — the general mechanism and why it bites payment flows
- [[entities/payment-webview]] — the shared widget carrying the fix
- [[concepts/paypal-webview-flow]] — the other WebView-based checkout path
- [[concepts/payment-system]]
