import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/admin_payments_provider.dart';

/// Payments view should join the `users` collection so each row shows a real
/// name (most signups are phone-only with no email on the payment record).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> boot(FakeFirebaseFirestore fake) async {
    final container = ProviderContainer(overrides: [
      adminPaymentsProvider
          .overrideWith((ref) => AdminPaymentsNotifier(firestore: fake)),
    ]);
    addTearDown(container.dispose);
    var guard = 0;
    while (container.read(adminPaymentsProvider).isLoading && guard < 200) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      guard++;
    }
    return container;
  }

  test('resolves userName from users/{uid} (first+last)', () async {
    final fake = FakeFirebaseFirestore();
    await fake.collection('users').doc('u1').set({
      'first_name': 'Mona',
      'last_name': 'Dugag',
    });
    await fake.collection('payments').doc('p1').set({
      'user_id': 'u1',
      'amount': 34.90,
      'status': 'completed',
      'provider': 'paypal',
      'created_at': Timestamp.fromDate(DateTime(2026, 6, 13)),
    });

    final container = await boot(fake);
    final payments = container.read(adminPaymentsProvider).payments;
    expect(payments.length, 1);
    expect(payments.first.userName, 'Mona Dugag');
  });

  test('leaves userName null when the user doc is missing', () async {
    final fake = FakeFirebaseFirestore();
    await fake.collection('payments').doc('p1').set({
      'user_id': 'ghost',
      'amount': 10.0,
      'status': 'completed',
      'provider': 'paypal',
      'created_at': Timestamp.fromDate(DateTime(2026, 6, 13)),
    });

    final container = await boot(fake);
    final payments = container.read(adminPaymentsProvider).payments;
    expect(payments.length, 1);
    expect(payments.first.userName, isNull);
  });
}
