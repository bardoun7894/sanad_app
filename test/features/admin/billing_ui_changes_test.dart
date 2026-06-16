import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/providers/system_settings_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_invoices_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_payments_provider.dart';
import 'package:sanad_app/features/admin/screens/payments_overview_screen.dart';

/// Widget tests for the two client-requested UI changes:
///   1. Subscriptions toggle hidden (guarded by _showSubscriptionsTab = false).
///   2. Export CSV button visible on the invoices view.
void main() {
  Future<FakeFirebaseFirestore> seed() async {
    final fake = FakeFirebaseFirestore();
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

  testWidgets(
    'subscriptions toggle IS visible (restored per client request Jun-2026)',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fake = await seed();
      await pumpScreen(tester, fake);

      // The subscriptions toggle must now be visible again
      // (_showSubscriptionsTab = true per Jun-2026 redesign task).
      expect(find.text('الاشتراكات'), findsWidgets);
    },
  );

  testWidgets(
    'export CSV button is visible on the invoices view',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fake = await seed();
      await pumpScreen(tester, fake);

      // The export button (تصدير CSV) must be visible on the invoices view.
      expect(find.text('تصدير CSV'), findsOneWidget);
    },
  );
}
