import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/subscription/services/freemius_checkout_service.dart';

FreemiusPurchaseData _purchase(String paymentId) => FreemiusPurchaseData(
      paymentId: paymentId,
      userId: 'u1',
      planId: '48712',
      productId: '29606',
      amount: 9.99,
      currency: 'USD',
      status: 'completed',
    );

void main() {
  group('isNewFreemiusPurchase', () {
    test('null current is never new', () {
      expect(isNewFreemiusPurchase(null, null), isFalse);
      expect(isNewFreemiusPurchase('p1', null), isFalse);
    });

    test('empty payment id is never new', () {
      expect(isNewFreemiusPurchase(null, _purchase('')), isFalse);
      expect(isNewFreemiusPurchase('p1', _purchase('   ')), isFalse);
    });

    test('first-ever purchase (no baseline) is new', () {
      expect(isNewFreemiusPurchase(null, _purchase('pay_100')), isTrue);
    });

    test('same id as baseline is stale, not new', () {
      expect(isNewFreemiusPurchase('pay_100', _purchase('pay_100')), isFalse);
    });

    test('different id from baseline is new', () {
      // Returning subscriber / second booking: a prior doc exists, a fresh
      // payment must still be detected.
      expect(isNewFreemiusPurchase('pay_100', _purchase('pay_200')), isTrue);
    });

    test('whitespace around ids is ignored', () {
      expect(isNewFreemiusPurchase(' pay_1 ', _purchase('pay_1')), isFalse);
    });
  });
}
