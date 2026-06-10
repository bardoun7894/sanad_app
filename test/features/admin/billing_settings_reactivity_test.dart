import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/providers/system_settings_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_invoices_provider.dart';

/// Guards the bug where invoice shares were baked at load and never tracked
/// the admin-configured revenue split. The split numbers MUST reflect the
/// current SystemSettings percentages.
void main() {
  Future<FakeFirebaseFirestore> seedOnePaidBooking({double amount = 100}) async {
    final fake = FakeFirebaseFirestore();
    await fake.collection('bookings').doc('b1').set({
      'client_name': 'Client A',
      'therapist_id': 't1',
      'therapist_name': 'Therapist One',
      'amount': amount,
      'currency': 'USD',
      'status': 'completed',
      'payment_status': 'paid',
      'created_at': Timestamp.fromDate(DateTime(2026, 5, 10)),
    });
    return fake;
  }

  Future<AdminInvoicesState> loadWith(
    FakeFirebaseFirestore fake,
    SystemSettings settings,
  ) async {
    final container = ProviderContainer(overrides: [
      adminInvoicesProvider.overrideWith(
        (ref) => AdminInvoicesNotifier(
          ref,
          firestore: fake,
          settingsOverride: settings,
        ),
      ),
    ]);
    addTearDown(container.dispose);
    // Instantiate the notifier so its constructor kicks off loadInvoices(),
    // then let the async Firestore read complete before reading state.
    container.read(adminInvoicesProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return container.read(adminInvoicesProvider);
  }

  test('shares follow a 70/20/10 split', () async {
    final fake = await seedOnePaidBooking(amount: 100);
    final state = await loadWith(
      fake,
      const SystemSettings(
        revenueTherapistPct: 70,
        revenueAppPct: 20,
        revenueMaintenancePct: 10,
      ),
    );
    expect(state.invoices, hasLength(1));
    expect(state.totalTherapist, closeTo(70, 0.001));
    expect(state.totalApp, closeTo(20, 0.001));
    expect(state.totalMaintenance, closeTo(10, 0.001));
    expect(state.payouts.single.therapistDue, closeTo(70, 0.001));
  });

  test('changing the split to 50/30/20 changes the computed shares', () async {
    final fake = await seedOnePaidBooking(amount: 100);
    final state = await loadWith(
      fake,
      const SystemSettings(
        revenueTherapistPct: 50,
        revenueAppPct: 30,
        revenueMaintenancePct: 20,
      ),
    );
    // Same booking, different configured split → different payout numbers.
    expect(state.totalTherapist, closeTo(50, 0.001));
    expect(state.totalApp, closeTo(30, 0.001));
    expect(state.totalMaintenance, closeTo(20, 0.001));
    expect(state.invoices.single.shares.therapist, closeTo(50, 0.001));
  });

  test('split is computed off the booking amount, not a hardcoded price',
      () async {
    // Old/seed bookings can be \$150, not the current \$34.99 flat price.
    final fake = await seedOnePaidBooking(amount: 150);
    final state = await loadWith(
      fake,
      const SystemSettings(
        revenueTherapistPct: 60,
        revenueAppPct: 30,
        revenueMaintenancePct: 10,
      ),
    );
    expect(state.totalGross, closeTo(150, 0.001));
    expect(state.totalTherapist, closeTo(90, 0.001)); // 60% of 150
    expect(state.totalApp, closeTo(45, 0.001)); // 30% of 150
    expect(state.totalMaintenance, closeTo(15, 0.001)); // 10% of 150
  });
}
