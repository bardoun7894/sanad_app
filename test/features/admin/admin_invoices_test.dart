import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/admin_invoices_provider.dart';

void main() {
  group('InvoiceClassifier.qualifies', () {
    test('payment_status==paid qualifies', () {
      expect(
        InvoiceClassifier.qualifies({'payment_status': 'paid'}),
        isTrue,
      );
    });

    test('status==completed qualifies', () {
      expect(
        InvoiceClassifier.qualifies({'status': 'completed'}),
        isTrue,
      );
    });

    test('both payment_status==paid and status==completed qualifies', () {
      expect(
        InvoiceClassifier.qualifies({'payment_status': 'paid', 'status': 'completed'}),
        isTrue,
      );
    });

    test('status==pending and payment_status==awaiting_payment does not qualify', () {
      expect(
        InvoiceClassifier.qualifies({'status': 'pending', 'payment_status': 'awaiting_payment'}),
        isFalse,
      );
    });

    test('empty map does not qualify', () {
      expect(
        InvoiceClassifier.qualifies({}),
        isFalse,
      );
    });
  });

  group('InvoiceClassifier.dedupe', () {
    test('list without duplicates is returned unchanged in length', () {
      final items = [
        {'id': 'a', 'v': 1},
        {'id': 'b', 'v': 2},
      ];
      final result = InvoiceClassifier.dedupe(items, (m) => m['id'] as String);
      expect(result.length, 2);
    });

    test('duplicate id: only first occurrence is kept', () {
      final first = {'id': 'x', 'v': 1};
      final duplicate = {'id': 'x', 'v': 2};
      final items = [first, duplicate, {'id': 'y', 'v': 3}];

      final result = InvoiceClassifier.dedupe(items, (m) => m['id'] as String);

      expect(result.length, 2);
      expect(identical(result[0], first), isTrue);
    });

    test('multiple duplicates collapsed to one entry each', () {
      final items = [
        {'id': 'a'},
        {'id': 'b'},
        {'id': 'a'},
        {'id': 'b'},
        {'id': 'c'},
      ];
      final result = InvoiceClassifier.dedupe(items, (m) => m['id'] as String);
      expect(result.length, 3);
    });
  });

  group('InvoiceFilter.inRange', () {
    final base = DateTime(2024, 6, 15);
    final from = DateTime(2024, 6, 1);
    final to = DateTime(2024, 6, 30);

    test('date inside [from, to] returns true', () {
      expect(InvoiceFilter.inRange(base, from, to), isTrue);
    });

    test('date equal to from boundary returns true (inclusive)', () {
      expect(InvoiceFilter.inRange(from, from, to), isTrue);
    });

    test('date equal to to boundary returns true (inclusive)', () {
      expect(InvoiceFilter.inRange(to, from, to), isTrue);
    });

    test('date before from returns false', () {
      final before = DateTime(2024, 5, 31);
      expect(InvoiceFilter.inRange(before, from, to), isFalse);
    });

    test('date after to returns false', () {
      final after = DateTime(2024, 7, 1);
      expect(InvoiceFilter.inRange(after, from, to), isFalse);
    });

    test('null from — open lower bound: any date at or before to returns true', () {
      expect(InvoiceFilter.inRange(DateTime(2020, 1, 1), null, to), isTrue);
    });

    test('null to — open upper bound: any date at or after from returns true', () {
      expect(InvoiceFilter.inRange(DateTime(2030, 12, 31), from, null), isTrue);
    });

    test('null from and null to — fully open: any date returns true', () {
      expect(InvoiceFilter.inRange(base, null, null), isTrue);
    });
  });
}
