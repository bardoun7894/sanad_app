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
// TDD RED test: desktop vertical-scroll layout fix.
//
// Before the fix:
//   - _buildInvoicesView / _buildSubscriptionsView wrap the entire body in a
//     Column → Expanded(table), which clips the table vertically.
//   - On desktop the stat cards + search boxes + tabs eat the available height
//     and only ~2 rows are visible with no way to scroll down.
//
// After the fix (GREEN):
//   - Each view is wrapped in a vertical SingleChildScrollView so the whole
//     page scrolls, giving the DataTable natural (unbounded) height.
//   - No Expanded widget wraps the DataTable itself on desktop.
//   - The outer page Expanded is still present (it holds the scroll view).
//   - Mobile path (ListView.builder) is unchanged.
// ---------------------------------------------------------------------------

Future<FakeFirebaseFirestore> _seedFull() async {
  final fake = FakeFirebaseFirestore();
  // Enough bookings to fill more than the visible area.
  for (var i = 0; i < 15; i++) {
    await fake.collection('bookings').doc('b$i').set({
      'client_name': 'Client $i',
      'therapist_id': 't1',
      'therapist_name': 'Therapist A',
      'amount': 50.0 + i,
      'currency': 'USD',
      'status': 'completed',
      'payment_status': 'paid',
      'payment_method': 'paypal',
      'created_at': Timestamp.fromDate(DateTime(2026, 5, i + 1)),
    });
  }
  // A payment record so the subscriptions view is non-empty.
  await fake.collection('payments').doc('p1').set({
    'user_id': 'u1',
    'user_email': 'alice@example.com',
    'amount': 34.99,
    'currency': 'USD',
    'status': 'completed',
    'provider': 'paypal',
    'created_at': Timestamp.fromDate(DateTime(2026, 5, 18)),
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
  // ── Invoices view — vertical scroll ─────────────────────────────────────

  group('Invoices view — desktop vertical scroll layout', () {
    testWidgets(
      'invoices view contains a vertical SingleChildScrollView on desktop',
      (tester) async {
        // 1440×900 — a typical laptop/desktop viewport.
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedFull();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // The invoices view is active by default. There must be at least one
        // vertical SingleChildScrollView (the page-level scroll container).
        final verticalScrollViews = tester.widgetList<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        ).where((w) => w.scrollDirection == Axis.vertical).toList();

        expect(
          verticalScrollViews,
          isNotEmpty,
          reason:
              'Expected at least one vertical SingleChildScrollView in the '
              'invoices view so the page can scroll on desktop.',
        );
      },
    );

    testWidgets(
      'invoices view renders without layout overflow on a short desktop viewport',
      (tester) async {
        // Short viewport (600px) forces the old layout to clip; the new layout
        // must scroll instead.
        tester.view.physicalSize = const Size(1440, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedFull();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'all 15 seeded invoice client names are present in the widget tree '
      '(no rows hidden behind a non-scrolling clip)',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedFull();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // All client names must be in the widget tree (even if off-screen in
        // a scrollable). findWidgets searches the full render tree, so rows
        // that exist but are scrolled off-screen will still be found.
        for (var i = 0; i < 15; i++) {
          expect(
            find.textContaining('Client $i'),
            findsWidgets,
            reason: 'Client $i should be in the widget tree',
          );
        }
      },
    );
  });

  // ── Subscriptions view — vertical scroll ────────────────────────────────

  group('Subscriptions view — desktop vertical scroll layout', () {
    testWidgets(
      'subscriptions view contains a vertical SingleChildScrollView on desktop',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedFull();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // Switch to subscriptions view.
        await tester.tap(find.text('الاشتراكات').first);
        await tester.pumpAndSettle();

        final verticalScrollViews = tester.widgetList<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        ).where((w) => w.scrollDirection == Axis.vertical).toList();

        expect(
          verticalScrollViews,
          isNotEmpty,
          reason:
              'Expected at least one vertical SingleChildScrollView in the '
              'subscriptions view so the page can scroll on desktop.',
        );
      },
    );

    testWidgets(
      'subscriptions view renders without layout overflow on a short desktop viewport',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedFull();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        await tester.tap(find.text('الاشتراكات').first);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });

  // ── Mobile path unregressed ──────────────────────────────────────────────

  group('Mobile path — unchanged', () {
    testWidgets(
      'mobile invoices view still renders without exceptions',
      (tester) async {
        // Use logical pixels (devicePixelRatio = 1.0) for the Flutter test
        // canvas, giving a realistic 390×844 logical-pixel mobile viewport.
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seedFull();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
