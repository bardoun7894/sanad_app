import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/providers/system_settings_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_invoices_provider.dart';

/// Unit tests for the client-requested invoice search filters
/// (بحث باسم العميل / بحث باسم المعالج). Backs the billing-dashboard rebuild.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<FakeFirebaseFirestore> seed() async {
    final fake = FakeFirebaseFirestore();
    await fake.collection('bookings').doc('b1').set({
      'client_name': 'Fahd AlQahtani',
      'therapist_id': 't1',
      'therapist_name': 'Lamia Salah',
      'amount': 100.0,
      'status': 'completed',
      'payment_status': 'paid',
      'created_at': Timestamp.fromDate(DateTime(2026, 5, 17)),
    });
    await fake.collection('bookings').doc('b2').set({
      'client_name': 'Mona Dugag',
      'therapist_id': 't2',
      'therapist_name': 'Ahmed Suleiman',
      'amount': 50.0,
      'status': 'completed',
      'payment_status': 'paid',
      'created_at': Timestamp.fromDate(DateTime(2026, 5, 18)),
    });
    return fake;
  }

  Future<ProviderContainer> bootContainer(FakeFirebaseFirestore fake) async {
    final container = ProviderContainer(overrides: [
      adminInvoicesProvider.overrideWith(
        (ref) => AdminInvoicesNotifier(
          ref,
          firestore: fake,
          settingsOverride: const SystemSettings(),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    // Wait for the constructor's loadInvoices() to settle.
    var guard = 0;
    while (container.read(adminInvoicesProvider).isLoading && guard < 200) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      guard++;
    }
    return container;
  }

  test('loads all qualifying invoices when no search query', () async {
    final container = await bootContainer(await seed());
    expect(container.read(adminInvoicesProvider).invoices.length, 2);
  });

  test('setClientQuery filters by client name (case-insensitive substring)',
      () async {
    final container = await bootContainer(await seed());
    container.read(adminInvoicesProvider.notifier).setClientQuery('mona');

    final state = container.read(adminInvoicesProvider);
    expect(state.invoices.length, 1);
    expect(state.invoices.first.clientName, 'Mona Dugag');
    // Totals reflect the filtered set, not the full set.
    expect(state.totalGross, 50.0);
  });

  test('setTherapistQuery filters by therapist name', () async {
    final container = await bootContainer(await seed());
    container.read(adminInvoicesProvider.notifier).setTherapistQuery('lamia');

    final state = container.read(adminInvoicesProvider);
    expect(state.invoices.length, 1);
    expect(state.invoices.first.therapistName, 'Lamia Salah');
    // Payout summary collapses to the single matching therapist.
    expect(state.payouts.length, 1);
    expect(state.payouts.first.therapistName, 'Lamia Salah');
  });

  test('clearing a query restores the full list', () async {
    final container = await bootContainer(await seed());
    final notifier = container.read(adminInvoicesProvider.notifier);
    notifier.setClientQuery('mona');
    expect(container.read(adminInvoicesProvider).invoices.length, 1);
    notifier.setClientQuery('');
    expect(container.read(adminInvoicesProvider).invoices.length, 2);
  });

  test('client and therapist queries compose (AND)', () async {
    final container = await bootContainer(await seed());
    final notifier = container.read(adminInvoicesProvider.notifier);
    notifier.setClientQuery('mona');
    notifier.setTherapistQuery('lamia'); // no booking has both → empty
    expect(container.read(adminInvoicesProvider).invoices, isEmpty);
  });
}
