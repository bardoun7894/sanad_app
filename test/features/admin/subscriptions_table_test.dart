import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/providers/system_settings_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_invoices_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_payments_provider.dart';
import 'package:sanad_app/features/admin/screens/payments_overview_screen.dart';

// ---------------------------------------------------------------------------
// TDD tests for the new subscriptions DataTable + therapist-dues DataTable.
//
// RED phase: these tests are written BEFORE production code. They must fail
// until the screen implementation is updated. Run them with:
//   flutter test test/features/admin/subscriptions_table_test.dart
// ---------------------------------------------------------------------------

/// Seed helpers
Future<FakeFirebaseFirestore> _seedWithMultiplePayments() async {
  final fake = FakeFirebaseFirestore();

  // Three payment records:
  //  p1 — PayPal (stored via `provider` field, payment_method absent)
  //  p2 — admin_grant (payment_method present)
  //  p3 — bank_transfer (payment_method present) - pending
  await fake.collection('payments').doc('p1').set({
    'user_id': 'u1',
    'user_email': 'alice@example.com',
    'amount': 34.99,
    'currency': 'USD',
    'status': 'completed',
    'provider': 'paypal',
    'created_at': Timestamp.fromDate(DateTime(2026, 5, 18)),
  });
  await fake.collection('payments').doc('p2').set({
    'user_id': 'u2',
    'user_email': 'bob@example.com',
    'amount': 99.00,
    'currency': 'USD',
    'status': 'completed',
    'payment_method': 'admin_grant',
    'created_at': Timestamp.fromDate(DateTime(2026, 6, 1)),
  });
  await fake.collection('payments').doc('p3').set({
    'user_id': 'u3',
    'user_email': 'carol@example.com',
    'amount': 49.00,
    'currency': 'USD',
    'status': 'pending',
    'payment_method': 'bank_transfer',
    'created_at': Timestamp.fromDate(DateTime(2026, 6, 2)),
  });

  // One booking for invoices view (required so screen doesn't show empty)
  await fake.collection('bookings').doc('b1').set({
    'client_name': 'فهد القحطاني',
    'therapist_id': 't1',
    'therapist_name': 'Lamia Salah',
    'amount': 34.99,
    'currency': 'USD',
    'status': 'completed',
    'payment_status': 'paid',
    'payment_method': 'paypal',
    'created_at': Timestamp.fromDate(DateTime(2026, 5, 17)),
  });

  return fake;
}

Future<FakeFirebaseFirestore> _seedTherapistDues() async {
  final fake = FakeFirebaseFirestore();

  // Two therapists with multiple bookings each
  await fake.collection('bookings').doc('b1').set({
    'client_name': 'أحمد',
    'therapist_id': 't1',
    'therapist_name': 'Lamia Salah',
    'amount': 100.0,
    'currency': 'USD',
    'status': 'completed',
    'payment_status': 'paid',
    'payment_method': 'paypal',
    'created_at': Timestamp.fromDate(DateTime(2026, 5, 10)),
  });
  await fake.collection('bookings').doc('b2').set({
    'client_name': 'سارة',
    'therapist_id': 't1',
    'therapist_name': 'Lamia Salah',
    'amount': 80.0,
    'currency': 'USD',
    'status': 'completed',
    'payment_status': 'paid',
    'payment_method': 'paypal',
    'created_at': Timestamp.fromDate(DateTime(2026, 5, 15)),
  });
  await fake.collection('bookings').doc('b3').set({
    'client_name': 'خالد',
    'therapist_id': 't2',
    'therapist_name': 'Youssef Nour',
    'amount': 60.0,
    'currency': 'USD',
    'status': 'completed',
    'payment_status': 'paid',
    'payment_method': 'bank_transfer',
    'created_at': Timestamp.fromDate(DateTime(2026, 5, 20)),
  });

  return fake;
}

Widget _buildScreen(FakeFirebaseFirestore fake) {
  return ProviderScope(
    overrides: [
      adminPaymentsProvider.overrideWith(
        (ref) => AdminPaymentsNotifier(firestore: fake),
      ),
      adminInvoicesProvider.overrideWith(
        (ref) => AdminInvoicesNotifier(
          ref,
          firestore: fake,
          settingsOverride: const SystemSettings(),
        ),
      ),
    ],
    child: const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: PaymentsOverviewScreen(),
      ),
    ),
  );
}

void main() {
  // ── Subscriptions tab (now visible: _showSubscriptionsTab = true) ──────────

  group('Subscriptions tab — visible + DataTable', () {
    testWidgets(
      'subscriptions toggle IS visible when _showSubscriptionsTab = true',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedWithMultiplePayments();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // The subscriptions toggle segment must now appear
        expect(find.text('الاشتراكات'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'switching to subscriptions view shows a DataTable with key column headers',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedWithMultiplePayments();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // Tap the subscriptions segment to switch views
        await tester.tap(find.text('الاشتراكات').first);
        await tester.pumpAndSettle();

        // Column headers for the subscriptions DataTable must be present
        expect(find.text('العميل'), findsWidgets);      // user/client name col
        expect(find.text('المبلغ'), findsWidgets);      // amount col
        expect(find.text('طريقة الدفع'), findsWidgets); // method col
        expect(find.text('الحالة'), findsWidgets);      // status col
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'subscriptions DataTable shows resolved payment method (not "unknown") '
      'for provider-only records',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedWithMultiplePayments();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // Switch to subscriptions view
        await tester.tap(find.text('الاشتراكات').first);
        await tester.pumpAndSettle();

        // p1 had `provider: paypal` but no payment_method — should show PayPal,
        // NOT "unknown"
        expect(find.text('PayPal'), findsWidgets);
        expect(find.textContaining('unknown'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'name search in subscriptions view filters displayed rows',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Seed payments with known user email (name resolved best-effort;
        // since fake Firestore has no users collection, name falls back to email)
        final fake = await _seedWithMultiplePayments();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        await tester.tap(find.text('الاشتراكات').first);
        await tester.pumpAndSettle();

        // Find the search TextField (subscriptions view search box)
        final searchField = find.byType(TextField).first;
        await tester.enterText(searchField, 'alice');
        await tester.pumpAndSettle();

        // After filtering by 'alice', carol@example.com must NOT appear in rows
        expect(find.textContaining('carol'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ── Therapist-dues table ────────────────────────────────────────────────────

  group('Therapist-dues summary — DataTable', () {
    testWidgets(
      'therapist-dues section renders a DataTable with therapist column header',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedTherapistDues();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // The therapist-dues table must show the therapist column header
        expect(find.text('المعالج'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'therapist-dues table shows one row per therapist',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedTherapistDues();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // Two distinct therapists → both names must appear in the dues table
        expect(find.textContaining('Lamia Salah'), findsWidgets);
        expect(find.textContaining('Youssef Nour'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'therapist-dues DataTable shows sessions count column',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedTherapistDues();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // The sessions count column header must be present
        expect(find.text('الجلسات'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'detailed invoice DataTable still shows every individual booking row',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedTherapistDues();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // All three individual booking client names must appear in invoice table
        expect(find.textContaining('أحمد'), findsWidgets);
        expect(find.textContaining('سارة'), findsWidgets);
        expect(find.textContaining('خالد'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ── Regression: existing tests still satisfied ──────────────────────────────

  group('Regression guard', () {
    testWidgets(
      'invoices view (default) renders without layout exceptions',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedWithMultiplePayments();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // Default view must always be invoices
        expect(find.text('تصدير CSV'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'export CSV button remains visible on invoices view after subscriptions tab restored',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedWithMultiplePayments();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        expect(find.text('تصدير CSV'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
