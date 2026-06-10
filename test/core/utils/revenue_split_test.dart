import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/utils/revenue_split.dart';

void main() {
  group('RevenueSplit.compute', () {
    test('splits 100 with 70/20/10 yields therapist=70, app=20, maintenance=10', () {
      final shares = RevenueSplit.compute(
        amount: 100,
        therapistPct: 70,
        appPct: 20,
        maintenancePct: 10,
      );
      expect(shares.therapist, closeTo(70.0, 0.001));
      expect(shares.app, closeTo(20.0, 0.001));
      expect(shares.maintenance, closeTo(10.0, 0.001));
    });

    test('splits fractional 34.99 with 70/20/10 yields therapist≈24.493, app≈6.998, maintenance≈3.499', () {
      final shares = RevenueSplit.compute(
        amount: 34.99,
        therapistPct: 70,
        appPct: 20,
        maintenancePct: 10,
      );
      expect(shares.therapist, closeTo(24.493, 0.001));
      expect(shares.app, closeTo(6.998, 0.001));
      expect(shares.maintenance, closeTo(3.499, 0.001));
    });

    test('splits 150 with 60/30/10 yields therapist=90, app=45, maintenance=15', () {
      final shares = RevenueSplit.compute(
        amount: 150,
        therapistPct: 60,
        appPct: 30,
        maintenancePct: 10,
      );
      expect(shares.therapist, closeTo(90.0, 0.001));
      expect(shares.app, closeTo(45.0, 0.001));
      expect(shares.maintenance, closeTo(15.0, 0.001));
    });
  });

  group('RevenueSplit.sumsTo100', () {
    test('(70, 20, 10) sums to 100 — returns true', () {
      expect(RevenueSplit.sumsTo100(70, 20, 10), isTrue);
    });

    test('(70, 20, 20) sums to 110 — returns false', () {
      expect(RevenueSplit.sumsTo100(70, 20, 20), isFalse);
    });

    test('(33.33, 33.33, 33.34) is within 0.01 tolerance of 100 — returns true', () {
      expect(RevenueSplit.sumsTo100(33.33, 33.33, 33.34), isTrue);
    });

    test('(50, 50, 10) sums to 110 — returns false', () {
      expect(RevenueSplit.sumsTo100(50, 50, 10), isFalse);
    });
  });
}
