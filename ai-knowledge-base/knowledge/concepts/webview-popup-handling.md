---
name: WebView Popup Handling
description: Why window.open silently disappears in Android WebViews and how that breaks 3DS and other payment step-ups
type: concept
tags: [android, webview, payment, flutter]
sources: [sources/freemius-3ds-white-screen]
created: "2026-07-29"
updated: "2026-07-29"
---
# WebView Popup Handling

## Overview

Android's `WebView` will not open a second window on its own. `WebSettings.setSupportMultipleWindows(true)` is a promise by the host application that it will handle the request itself, by overriding `WebChromeClient.onCreateWindow`. If the flag is on and the override is missing, the default implementation returns false and the popup is discarded — no exception, no console message, no navigation. The page that called `window.open` simply stays where it is, which the user experiences as a blank or frozen screen.

## Why payment flows hit this

Card authentication step-ups — 3-D Secure and its equivalents — routinely open the issuer's challenge in a new window rather than navigating the checkout page. A checkout that works end to end in a browser will therefore die at exactly the authentication step inside a WebView, and only for cards that trigger a challenge. That makes the failure look intermittent and card-specific, which sends debugging toward the payment provider instead of the WebView.

## The trap in webview_flutter_android

`AndroidWebViewController`'s constructor turns multiple-window support **on** while the `WebChromeClient` it registers never overrides `onCreateWindow`. The plugin therefore ships the exact broken combination by default, and version 3.16.9 exposes no public setter to undo it. The workaround is to reach the native settings object through a proxy and set the flag back to false after construction; with support off, the popup navigation is delivered to the existing WebView instead of being dropped. Message ordering makes this safe — Pigeon calls are delivered in order on a single engine, so the later `false` wins over the constructor's `true`.

## Related failure: the load that never finishes

The same screens can hang a second way. If `onPageStarted` fires and `onPageFinished` never does, a loading overlay stays up forever and is indistinguishable from the popup bug. A watchdog timer started in `onPageStarted` — around 25 seconds, since authentication pages are legitimately slow — that reveals the page anyway is the mitigation. Showing a half-loaded page beats showing white.

## Platform difference

iOS does not share the problem. `WKWebView` loads `window.open` and `target=_blank` in the same view by default when no UI delegate creates a new one, so the popup is never lost.

## See also

- [[entities/payment-webview]] — the shared widget where this is handled
- [[sources/freemius-3ds-white-screen]] — the investigation that identified it
- [[concepts/paypal-webview-flow]] — the other WebView checkout path in the app
- [[concepts/payment-system]]
