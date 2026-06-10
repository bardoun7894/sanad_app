import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/admin_invoices_provider.dart';

void main() {
  group('InvoiceClassifier.qualifies', () {
    test('qualifies when payment_status is paid', () {
      final data = {'payment_status': 'paid', 'status': 'pending'};
      expect(InvoiceClassifier.qualifies(data), isTrue);
    });

    test('qualifies when status is completed', () {
      final data = {'payment_status': 'unpaid', 'status': 'completed'};
      expect(InvoiceClassifier.qualifies(data), isTrue);
    });

    test('qualifies when both conditions are true', () {
      final data = {'payment_status': 'paid', 'status': 'completed'};
      expect(InvoiceClassifier.qualifies(data), isTrue);
    });

    test('does not qualify when neither condition is true', () {
      final data = {'payment_status': 'unpaid', 'status': 'pending'};
      expect(InvoiceClassifier.qualifies(data), isFalse);
    });

    test('does not qualify with missing fields', () {
      final data = <String, dynamic>{};
      expect(InvoiceClassifier.qualifies(data), isFalse);
    });
  });

  group('InvoiceClassifier.dedupe', () {
    test('removes items with duplicate ids keeping first occurrence', () {
      final items = [
        {'id': 'a', 'val': 1},
        {'id': 'b', 'val': 2},
        {'id': 'a', 'val': 3}, // duplicate
      ];
      final result = InvoiceClassifier.dedupe(items, (m) => m['id'] as String);
      expect(result.length, 2);
      expect(result[0]['val'], 1); // first occurrence kept
      expect(result[1]['val'], 2);
    });

    test('returns original list unchanged when no duplicates', () {
      final items = [
        {'id': 'a'},
        {'id': 'b'},
        {'id': 'c'},
      ];
      final result = InvoiceClassifier.dedupe(items, (m) => m['id'] as String);
      expect(result.length, 3);
    });

    test('returns empty list for empty input', () {
      final result = InvoiceClassifier.dedupe<Map<String, dynamic>>([], (m) => m['id'] as String);
      expect(result.isEmpty, isTrue);
    });

    test('preserves order of first occurrences', () {
      final items = ['c', 'a', 'b', 'a', 'c'];
      final result = InvoiceClassifier.dedupe(items, (s) => s);
      expect(result, ['c', 'a', 'b']);
    });
  });

  group('InvoiceFilter.inRange', () {
    final date = DateTime(2026, 6, 15);

    test('returns true when both bounds null (open-ended)', () {
      expect(InvoiceFilter.inRange(date, null, null), isTrue);
    });

    test('returns true when date equals from boundary (inclusive)', () {
      expect(InvoiceFilter.inRange(date, DateTime(2026, 6, 15), null), isTrue);
    });

    test('returns true when date equals to boundary (inclusive)', () {
      expect(InvoiceFilter.inRange(date, null, DateTime(2026, 6, 15)), isTrue);
    });

    test('returns true when date is within range', () {
      expect(
        InvoiceFilter.inRange(date, DateTime(2026, 6, 1), DateTime(2026, 6, 30)),
        isTrue,
      );
    });

    test('returns false when date is before from', () {
      expect(InvoiceFilter.inRange(date, DateTime(2026, 6, 16), null), isFalse);
    });

    test('returns false when date is after to', () {
      expect(InvoiceFilter.inRange(date, null, DateTime(2026, 6, 14)), isFalse);
    });

    test('null from with valid to allows dates before to', () {
      expect(
        InvoiceFilter.inRange(DateTime(2026, 1, 1), null, DateTime(2026, 6, 30)),
        isTrue,
      );
    });
  });
}
