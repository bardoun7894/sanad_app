import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/providers/system_settings_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_invoices_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_payments_provider.dart';
import 'package:sanad_app/features/admin/screens/payments_overview_screen.dart';

/// Render smoke test: the screen logic is unit-tested elsewhere; this proves
/// both views actually build (no overflow / layout exceptions) in RTL with
/// realistic data. Overrides both providers with a fake Firestore so no real
/// Firebase is touched.
void main() {
  Future<FakeFirebaseFirestore> seed() async {
    final fake = FakeFirebaseFirestore();
    // A paid booking → becomes an invoice + a payout row.
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
    // A subscription payment → shows in the Subscriptions view.
    await fake.collection('payments').doc('p1').set({
      'user_id': 'u1',
      'amount': 34.99,
      'currency': 'USD',
      'status': 'completed',
      'provider': 'paypal',
      'created_at': Timestamp.fromDate(DateTime(2026, 5, 18)),
    });
    return fake;
  }

  Future<void> pumpScreen(WidgetTester tester, FakeFirebaseFirestore fake) async {
    await tester.pumpWidget(
      ProviderScope(
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
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders subscriptions view then invoices view without errors',
      (tester) async {
    // Generous surface so the responsive layout uses the wide branch.
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final fake = await seed();
    await pumpScreen(tester, fake);

    // Subscriptions view built fine.
    expect(tester.takeException(), isNull);

    // Switch to the Therapist Invoices & Payouts view.
    await tester.tap(find.text(AppStringsTherapistInvoicesLabel));
    await tester.pumpAndSettle();

    // No overflow / layout exception thrown while building the invoices view.
    expect(tester.takeException(), isNull);
    // The payout summary section rendered.
    expect(find.textContaining('Lamia Salah'), findsWidgets);
  });
}

// The screen uses AppStrings.adminTherapistInvoices (Arabic). Re-declared here
// as a constant to avoid importing the 2k-line strings file into the test.
const String AppStringsTherapistInvoicesLabel = 'فواتير ومستحقات المعالجين';
