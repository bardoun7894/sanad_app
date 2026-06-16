// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Triggers a browser file-download of [content] (UTF-8 CSV string) with the
/// given [filename]. This implementation uses the `package:web` / Dart
/// `dart:js_interop` pair which is the recommended approach for Dart 3.x
/// Flutter web targets (replaces the deprecated `dart:html` API).
///
/// This function is intentionally in a separate file so the non-web stub can
/// exist alongside it; the correct implementation is selected at compile time
/// via `conditional_imports` (or just the web target always uses this file).
///
/// Security note: the URL is created from a Blob of trusted, admin-generated
/// data. The URL is revoked immediately after the click to avoid memory leaks.
void downloadCsvOnWeb(String content, String filename) {
  // Encode content as a UTF-8 JS string and wrap in a Blob.
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8;'),
  );

  final url = web.URL.createObjectURL(blob);

  // Create an invisible anchor element, set the download attribute, and click.
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();

  // Cleanup: remove the anchor and revoke the object URL.
  web.document.body!.removeChild(anchor);
  web.URL.revokeObjectURL(url);
}
