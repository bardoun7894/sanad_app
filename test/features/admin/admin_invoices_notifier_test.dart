import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/providers/system_settings_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_invoices_provider.dart';

// Use the default SystemSettings (70/20/10) as a fixed test override,
// passed directly to AdminInvoicesNotifier via settingsOverride so we never
// touch systemSettingsProvider or FirebaseFirestore.instance in tests.

// ---------------------------------------------------------------------------
// Helper: seed a booking doc into the fake Firestore.
// ---------------------------------------------------------------------------
Future<void> _seedBooking(
  FakeFirebaseFirestore fake,
  String id,
  Map<String, dynamic> data,
) async {
  await fake.collection('bookings').doc(id).set(data);
}

// ---------------------------------------------------------------------------
// Helper: build a ProviderContainer with adminInvoicesProvider overridden.
// settingsOverride avoids systemSettingsProvider's Firestore dependency.
// ---------------------------------------------------------------------------
ProviderContainer _makeContainer(FakeFirebaseFirestore fake) {
  return ProviderContainer(
    overrides: [
      adminInvoicesProvider.overrideWith(
        (ref) => AdminInvoicesNotifier(
          ref,
          firestore: fake,
          settingsOverride: const SystemSettings(), // 70 / 20 / 10 defaults
        ),
      ),
    ],
  );
}

void main() {
  group('AdminInvoicesNotifier.loadInvoices', () {
    late FakeFirebaseFirestore fake;

    setUp(() {
      fake = FakeFirebaseFirestore();
    });

    test(
        'qualifies paid booking; excludes non-qualifying; groups into TherapistPayout',
        () async {
      final now = DateTime(2026, 6, 7, 10, 0, 0);

      // Qualifying: payment_status==paid, therapist A.
      await _seedBooking(fake, 'b1', {
        'payment_status': 'paid',
        'status': 'pending',
        'therapist_id': 'therapist_a',
        'therapist_name': 'Alice',
        'client_name': 'Client 1',
        'amount': 100.0,
        'currency': 'USD',
        'payment_method': 'paypal',
        'scheduled_time': Timestamp.fromDate(now),
      });

      // Qualifying: status==completed, therapist A — same therapist → groups.
      await _seedBooking(fake, 'b2', {
        'payment_status': 'unpaid',
        'status': 'completed',
        'therapist_id': 'therapist_a',
        'therapist_name': 'Alice',
        'client_name': 'Client 2',
        'amount': 200.0,
        'currency': 'USD',
        'payment_method': 'card',
        'scheduled_time': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      });

      // Non-qualifying: excluded.
      await _seedBooking(fake, 'b3', {
        'payment_status': 'unpaid',
        'status': 'pending',
        'therapist_id': 'therapist_b',
        'therapist_name': 'Bob',
        'client_name': 'Client 3',
        'amount': 50.0,
        'currency': 'USD',
      });

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(adminInvoicesProvider.notifier).loadInvoices();
      final state = container.read(adminInvoicesProvider);

      // Two qualifying invoices, one excluded.
      expect(state.invoices.length, 2);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);

      // One therapist group (Alice).
      expect(state.payouts.length, 1);
      final payout = state.payouts.first;
      expect(payout.therapistId, 'therapist_a');
      expect(payout.therapistName, 'Alice');
      expect(payout.sessions, 2);
      expect(payout.gross, closeTo(300.0, 0.001));
      // 70% of 300
      expect(payout.therapistDue, closeTo(210.0, 0.001));
      // 20% of 300
      expect(payout.appCut, closeTo(60.0, 0.001));
      // 10% of 300
      expect(payout.maintenance, closeTo(30.0, 0.001));

      // Range totals.
      expect(state.totalGross, closeTo(300.0, 0.001));
      expect(state.totalTherapist, closeTo(210.0, 0.001));
      expect(state.totalApp, closeTo(60.0, 0.001));
      expect(state.totalMaintenance, closeTo(30.0, 0.001));
    });

    test(
        'booking qualifying by both paid and completed deduped to single invoice',
        () async {
      final now = DateTime(2026, 6, 7, 12, 0, 0);

      // This doc satisfies BOTH qualifies branches — still one invoice.
      await _seedBooking(fake, 'dup1', {
        'payment_status': 'paid',
        'status': 'completed',
        'therapist_id': 'therapist_c',
        'therapist_name': 'Carol',
        'client_name': 'Client 4',
        'amount': 80.0,
        'currency': 'SAR',
        'payment_method': 'bank_transfer',
        'scheduled_time': Timestamp.fromDate(now),
      });

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(adminInvoicesProvider.notifier).loadInvoices();
      final state = container.read(adminInvoicesProvider);

      expect(state.invoices.length, 1);
      expect(state.payouts.length, 1);
      expect(state.payouts.first.sessions, 1);
    });

    test(
        'booking missing scheduled_time falls back to created_at as invoice date',
        () async {
      final createdAt = DateTime(2026, 5, 1, 8, 0, 0);

      await _seedBooking(fake, 'notime1', {
        'payment_status': 'paid',
        'status': 'pending',
        'therapist_id': 'therapist_d',
        'therapist_name': 'Dave',
        'client_name': 'Client 5',
        'amount': 60.0,
        'currency': 'USD',
        'payment_method': 'card',
        // No scheduled_time field.
        'created_at': Timestamp.fromDate(createdAt),
      });

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(adminInvoicesProvider.notifier).loadInvoices();
      final state = container.read(adminInvoicesProvider);

      expect(state.invoices.length, 1);
      // Date must equal created_at since scheduled_time absent.
      expect(state.invoices.first.date, createdAt);
    });

    test('invoices sorted descending by date', () async {
      final dateOlder = DateTime(2026, 6, 1);
      final dateNewer = DateTime(2026, 6, 7);

      await _seedBooking(fake, 'old1', {
        'payment_status': 'paid',
        'status': 'pending',
        'therapist_id': 't',
        'therapist_name': 'T',
        'client_name': 'C',
        'amount': 10.0,
        'currency': 'USD',
        'payment_method': 'card',
        'scheduled_time': Timestamp.fromDate(dateOlder),
      });
      await _seedBooking(fake, 'new1', {
        'payment_status': 'paid',
        'status': 'pending',
        'therapist_id': 't',
        'therapist_name': 'T',
        'client_name': 'C',
        'amount': 20.0,
        'currency': 'USD',
        'payment_method': 'card',
        'scheduled_time': Timestamp.fromDate(dateNewer),
      });

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(adminInvoicesProvider.notifier).loadInvoices();
      final state = container.read(adminInvoicesProvider);

      expect(state.invoices.length, 2);
      // Newer first.
      expect(state.invoices[0].date, dateNewer);
      expect(state.invoices[1].date, dateOlder);
    });

    test('setRange filters invoices to the given date window', () async {
      final inRange = DateTime(2026, 6, 5);
      final outRange = DateTime(2026, 5, 1);

      await _seedBooking(fake, 'in1', {
        'payment_status': 'paid',
        'status': 'pending',
        'therapist_id': 't',
        'therapist_name': 'T',
        'client_name': 'C',
        'amount': 100.0,
        'currency': 'USD',
        'payment_method': 'card',
        'scheduled_time': Timestamp.fromDate(inRange),
      });
      await _seedBooking(fake, 'out1', {
        'payment_status': 'paid',
        'status': 'pending',
        'therapist_id': 't',
        'therapist_name': 'T',
        'client_name': 'C',
        'amount': 50.0,
        'currency': 'USD',
        'payment_method': 'card',
        'scheduled_time': Timestamp.fromDate(outRange),
      });

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(adminInvoicesProvider.notifier).loadInvoices();

      // Apply a range covering only inRange.
      container
          .read(adminInvoicesProvider.notifier)
          .setRange(DateTime(2026, 6, 1), DateTime(2026, 6, 30));

      final state = container.read(adminInvoicesProvider);
      // Only the in-range booking should show.
      expect(state.invoices.length, 1);
      expect(state.invoices.first.id, 'in1');
      expect(state.totalGross, closeTo(100.0, 0.001));
    });

    test('clearRange restores all invoices without hitting Firestore again',
        () async {
      final d1 = DateTime(2026, 6, 1);
      final d2 = DateTime(2026, 5, 1);

      await _seedBooking(fake, 'cr1', {
        'payment_status': 'paid',
        'status': 'pending',
        'therapist_id': 't',
        'therapist_name': 'T',
        'client_name': 'C',
        'amount': 40.0,
        'currency': 'USD',
        'payment_method': 'card',
        'scheduled_time': Timestamp.fromDate(d1),
      });
      await _seedBooking(fake, 'cr2', {
        'payment_status': 'paid',
        'status': 'pending',
        'therapist_id': 't',
        'therapist_name': 'T',
        'client_name': 'C',
        'amount': 60.0,
        'currency': 'USD',
        'payment_method': 'card',
        'scheduled_time': Timestamp.fromDate(d2),
      });

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(adminInvoicesProvider.notifier).loadInvoices();
      container
          .read(adminInvoicesProvider.notifier)
          .setRange(DateTime(2026, 6, 1), DateTime(2026, 6, 30));

      expect(container.read(adminInvoicesProvider).invoices.length, 1);

      container.read(adminInvoicesProvider.notifier).clearRange();

      // Both restored.
      expect(container.read(adminInvoicesProvider).invoices.length, 2);
      expect(container.read(adminInvoicesProvider).totalGross,
          closeTo(100.0, 0.001));
    });

    test('two bookings for same therapist accumulate sessions and sums correctly',
        () async {
      await _seedBooking(fake, 'acc1', {
        'payment_status': 'paid',
        'status': 'pending',
        'therapist_id': 'th_x',
        'therapist_name': 'Xavier',
        'client_name': 'Cx1',
        'amount': 150.0,
        'currency': 'USD',
        'payment_method': 'card',
        'scheduled_time': Timestamp.fromDate(DateTime(2026, 6, 6)),
      });
      await _seedBooking(fake, 'acc2', {
        'payment_status': 'paid',
        'status': 'pending',
        'therapist_id': 'th_x',
        'therapist_name': 'Xavier',
        'client_name': 'Cx2',
        'amount': 250.0,
        'currency': 'USD',
        'payment_method': 'card',
        'scheduled_time': Timestamp.fromDate(DateTime(2026, 6, 5)),
      });

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(adminInvoicesProvider.notifier).loadInvoices();
      final state = container.read(adminInvoicesProvider);

      expect(state.payouts.length, 1);
      final p = state.payouts.first;
      expect(p.therapistId, 'th_x');
      expect(p.sessions, 2);
      expect(p.gross, closeTo(400.0, 0.001));
      expect(p.therapistDue, closeTo(280.0, 0.001)); // 70% of 400
      expect(p.appCut, closeTo(80.0, 0.001));         // 20% of 400
      expect(p.maintenance, closeTo(40.0, 0.001));    // 10% of 400
    });
  });
}
