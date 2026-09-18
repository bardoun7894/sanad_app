import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/widgets/payment_webview.dart';

/// The checkout loader lifts only once this probe reports painted text. If the
/// parsing regresses, the loader either strands users on a spinner or reveals a
/// white WebView — the exact bug reported on the first live payment.
void main() {
  group('parseJsNumberResult', () {
    test('parses the JSON-encoded string Android returns', () {
      expect(parseJsNumberResult('"500"'), 500);
    });

    test('parses the raw num iOS returns', () {
      expect(parseJsNumberResult(500), 500);
    });

    test('parses an unquoted numeric string', () {
      expect(parseJsNumberResult('500'), 500);
    });

    test('treats unreadable results as not-yet-painted rather than painted', () {
      // Must be 0, never a truthy value: a probe that cannot read the page
      // must not be mistaken for a page that rendered.
      expect(parseJsNumberResult(null), 0);
      expect(parseJsNumberResult('null'), 0);
      expect(parseJsNumberResult('undefined'), 0);
      expect(parseJsNumberResult(''), 0);
    });

    test('a blank page reads as 0 and a painted checkout clears the threshold',
        () {
      // Live production checkout measures ~500 chars once rendered, ~0 blank.
      expect(parseJsNumberResult('"0"'), 0);
      expect(parseJsNumberResult('"500"'), greaterThan(100));
    });
  });
}
