import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/admin_payments_provider.dart';

void main() {
  group('PaymentRecord.resolveMethod', () {
    test('uses payment_method when present and non-empty', () {
      final data = {'payment_method': 'bank_transfer'};
      expect(PaymentRecord.resolveMethod(data), 'bank_transfer');
    });

    test('admin_grant payment_method passes through unchanged', () {
      final data = {'payment_method': 'admin_grant'};
      expect(PaymentRecord.resolveMethod(data), 'admin_grant');
    });

    test('maps provider paypal → paypal when payment_method absent', () {
      final data = {'provider': 'paypal'};
      expect(PaymentRecord.resolveMethod(data), 'paypal');
    });

    test('maps provider google_pay_via_paypal → google_pay', () {
      final data = {'provider': 'google_pay_via_paypal'};
      expect(PaymentRecord.resolveMethod(data), 'google_pay');
    });

    test('maps provider freemius → card', () {
      final data = {'provider': 'freemius'};
      expect(PaymentRecord.resolveMethod(data), 'card');
    });

    test('returns unknown for unknown provider when payment_method absent', () {
      final data = {'provider': 'stripe'};
      expect(PaymentRecord.resolveMethod(data), 'unknown');
    });

    test('returns unknown when both payment_method and provider absent', () {
      final data = <String, dynamic>{};
      expect(PaymentRecord.resolveMethod(data), 'unknown');
    });

    test('treats empty string payment_method as absent — falls through to provider', () {
      final data = {'payment_method': '', 'provider': 'paypal'};
      expect(PaymentRecord.resolveMethod(data), 'paypal');
    });

    test('treats null payment_method as absent — falls through to provider', () {
      final data = {'payment_method': null, 'provider': 'freemius'};
      expect(PaymentRecord.resolveMethod(data), 'card');
    });

    test('payment_method takes priority even when provider also present', () {
      final data = {'payment_method': 'bank_transfer', 'provider': 'paypal'};
      expect(PaymentRecord.resolveMethod(data), 'bank_transfer');
    });
  });
}
