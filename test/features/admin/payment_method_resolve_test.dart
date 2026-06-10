import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/admin_payments_provider.dart';

void main() {
  group('PaymentRecord.resolveMethod', () {
    test('payment_method present and non-empty wins over provider', () {
      expect(
        PaymentRecord.resolveMethod({'payment_method': 'bank_transfer', 'provider': 'paypal'}),
        'bank_transfer',
      );
    });

    test('payment_method==admin_grant is returned as-is', () {
      expect(
        PaymentRecord.resolveMethod({'payment_method': 'admin_grant'}),
        'admin_grant',
      );
    });

    test('provider==paypal maps to "paypal"', () {
      expect(
        PaymentRecord.resolveMethod({'provider': 'paypal'}),
        'paypal',
      );
    });

    test('provider==google_pay_via_paypal maps to "google_pay"', () {
      expect(
        PaymentRecord.resolveMethod({'provider': 'google_pay_via_paypal'}),
        'google_pay',
      );
    });

    test('provider==freemius maps to "card"', () {
      expect(
        PaymentRecord.resolveMethod({'provider': 'freemius'}),
        'card',
      );
    });

    test('empty map returns "unknown"', () {
      expect(
        PaymentRecord.resolveMethod({}),
        'unknown',
      );
    });

    test('empty payment_method string falls through to provider', () {
      expect(
        PaymentRecord.resolveMethod({'payment_method': '', 'provider': 'paypal'}),
        'paypal',
      );
    });

    test('unknown provider returns "unknown"', () {
      expect(
        PaymentRecord.resolveMethod({'provider': 'stripe'}),
        'unknown',
      );
    });
  });
}
