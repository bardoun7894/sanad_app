---
name: payment_webview
description: Shared Flutter widget for payment WebViews, carrying the Android multiple-window fix and the stuck-load watchdog
type: entity
tags: [flutter, webview, payment, android]
sources: [sources/freemius-3ds-white-screen]
created: "2026-07-29"
updated: "2026-07-29"
---
# payment_webview

## What it is

A shared widget at `lib/core/widgets/payment_webview.dart` that builds the WebView used by the app's payment screens. It exists so that the platform workarounds a checkout needs live in one place rather than being rediscovered per screen.

## Key facts

- Injects an Android proxy that calls `nativeWebView?.settings.setSupportMultipleWindows(false)` after the plugin's controller constructor has run, overriding the `true` the constructor sets. Without this, `window.open` during a 3-D Secure challenge is silently dropped and the screen goes white.
- The reasoning is recorded in a leading comment in the file, so the call is not mistaken for a redundant setting and removed.
- Carries a watchdog for the case where `onPageStarted` fires without a matching `onPageFinished`, revealing the page rather than leaving a loading overlay up indefinitely.
- Any new payment WebView should be built through this widget; screens that construct a raw `WebViewWidget` do not get these fixes.

## See also

- [[concepts/webview-popup-handling]] — why the multiple-window setting matters
- [[sources/freemius-3ds-white-screen]] — the investigation behind the fix
- [[concepts/paypal-webview-flow]]
- [[concepts/payment-system]]
