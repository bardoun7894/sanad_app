import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// A [WebViewWidget] that keeps rendering when the soft keyboard opens.
///
/// On Android the plugin defaults to texture-layer hybrid composition, which
/// blanks the WebView to white when the host window resizes. Our activity is
/// `windowSoftInputMode="adjustResize"`, so the window resizes the instant a
/// user taps a card field — turning the checkout white mid-payment.
/// Hybrid composition repaints correctly across resizes at some scroll cost,
/// which is the right trade for a payment form.
///
/// Refs: flutter/flutter#104889, flutter/flutter#116954.
/// iOS (WKWebView) is unaffected and uses the default path.
Widget buildPaymentWebView(WebViewController controller) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return WebViewWidget.fromPlatformCreationParams(
      params: AndroidWebViewWidgetCreationParams(
        controller: controller.platform,
        displayWithHybridComposition: true,
      ),
    );
  }
  return WebViewWidget(controller: controller);
}

/// Normalises a numeric `runJavaScriptReturningResult` result across platforms.
///
/// Android returns JSON-encoded strings (`"500"`), iOS returns a num (`500`).
/// Anything unparseable becomes 0, which callers must treat as "not ready yet"
/// rather than an error — a probe that can't read the page must never be
/// mistaken for a page that rendered.
int parseJsNumberResult(Object? raw) =>
    int.tryParse('$raw'.replaceAll('"', '').trim()) ?? 0;
