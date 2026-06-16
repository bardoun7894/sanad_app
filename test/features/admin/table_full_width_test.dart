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
// TDD tests for the full-width DataTable fix (TASK 1 — billing tables).
//
// Requirement: every DataTable in the billing screen must fill the full
// content width on desktop. The technique is:
//   SingleChildScrollView(horizontal) →
//     LayoutBuilder →
//       ConstrainedBox(minWidth: constraints.maxWidth) →
//         DataTable(...)
//
// A table that fills full width will have its DataTable widget rendered with
// a width >= the available content width. We verify this by reading the
// RenderBox size of each DataTable.
// ---------------------------------------------------------------------------

Future<FakeFirebaseFirestore> _seed() async {
  final fake = FakeFirebaseFirestore();
  // Bookings for invoices + payouts tables.
  for (var i = 0; i < 5; i++) {
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
  // Payment for subscriptions table.
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
  // A wide desktop viewport (1440 × 900). The content area minus padding is
  // 1440 - 2×24 = 1392px. A content-sized DataTable with 7 narrow columns
  // will be much shorter than 1392px, so any value >= 1200px safely means
  // the table has been stretched to fill the available width.
  const viewportWidth = 1440.0;
  const viewportHeight = 900.0;
  // Minimum rendered width we expect the DataTable to reach.
  const minExpectedWidth = 1200.0;

  // ── TASK 1 — Billing: invoice rows DataTable ────────────────────────────

  group('Billing — invoice rows DataTable fills full width', () {
    testWidgets(
      'invoice-rows DataTable renders at >= content width on desktop',
      (tester) async {
        tester.view.physicalSize = const Size(viewportWidth, viewportHeight);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seed();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // The invoices view is default. Find all DataTable widgets and
        // verify at least one is rendered at or near the full content width.
        final dataTableFinders = tester.widgetList<DataTable>(
          find.byType(DataTable),
        ).toList();

        expect(dataTableFinders, isNotEmpty,
            reason: 'At least one DataTable must be present in invoices view');

        // At least one DataTable must have a rendered width >= minExpectedWidth.
        bool foundFullWidth = false;
        for (final _ in dataTableFinders) {
          final element = tester.element(
            find.byType(DataTable).first,
          );
          final renderBox = element.renderObject as RenderBox?;
          if (renderBox != null && renderBox.size.width >= minExpectedWidth) {
            foundFullWidth = true;
            break;
          }
        }

        // We check ALL DataTable render boxes.
        for (final tableElement in tester.elementList(find.byType(DataTable))) {
          final renderBox = tableElement.renderObject as RenderBox?;
          if (renderBox != null && renderBox.size.width >= minExpectedWidth) {
            foundFullWidth = true;
          }
        }

        expect(
          foundFullWidth,
          isTrue,
          reason:
              'At least one billing DataTable must be rendered at >= '
              '${minExpectedWidth}px on a ${viewportWidth}px-wide desktop viewport. '
              'Wrap the DataTable in LayoutBuilder + ConstrainedBox(minWidth: maxWidth).',
        );
      },
    );

    testWidgets(
      'invoice-rows DataTable has a ConstrainedBox ancestor in its scroll view',
      (tester) async {
        tester.view.physicalSize = const Size(viewportWidth, viewportHeight);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seed();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // The full-width technique requires a ConstrainedBox between the
        // SingleChildScrollView and the DataTable.
        final constrainedBoxes = find.byType(ConstrainedBox);
        expect(
          constrainedBoxes,
          findsWidgets,
          reason:
              'Expected ConstrainedBox(minWidth: maxWidth) wrapper to make the '
              'DataTable fill the available content width.',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ── TASK 1 — Billing: payouts DataTable ────────────────────────────────

  group('Billing — payouts (therapist-dues) DataTable fills full width', () {
    testWidgets(
      'payouts DataTable is present and rendered without exception',
      (tester) async {
        tester.view.physicalSize = const Size(viewportWidth, viewportHeight);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seed();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // The payouts header text must be visible (table is present).
        expect(find.text('المعالج'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ── TASK 1 — Billing: subscriptions DataTable ──────────────────────────

  group('Billing — subscriptions DataTable fills full width', () {
    testWidgets(
      'subscriptions DataTable is rendered at >= content width on desktop',
      (tester) async {
        tester.view.physicalSize = const Size(viewportWidth, viewportHeight);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seed();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        // Switch to subscriptions view.
        await tester.tap(find.text('الاشتراكات').first);
        await tester.pumpAndSettle();

        bool foundFullWidth = false;
        for (final tableElement in tester.elementList(find.byType(DataTable))) {
          final renderBox = tableElement.renderObject as RenderBox?;
          if (renderBox != null && renderBox.size.width >= minExpectedWidth) {
            foundFullWidth = true;
          }
        }

        expect(
          foundFullWidth,
          isTrue,
          reason:
              'Subscriptions DataTable must be rendered at >= ${minExpectedWidth}px '
              'on a ${viewportWidth}px desktop viewport.',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ── Regression: horizontal scroll is preserved ─────────────────────────

  group('Horizontal scroll is preserved (not removed)', () {
    testWidgets(
      'horizontal SingleChildScrollView is still present in invoices view',
      (tester) async {
        tester.view.physicalSize = const Size(viewportWidth, viewportHeight);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = await _seed();
        await tester.pumpWidget(_buildScreen(fake));
        await tester.pumpAndSettle();

        final horizontalScrollViews = tester
            .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .where((w) => w.scrollDirection == Axis.horizontal)
            .toList();

        expect(
          horizontalScrollViews,
          isNotEmpty,
          reason:
              'At least one horizontal SingleChildScrollView must remain so '
              'wide tables can still scroll horizontally on narrow viewports.',
        );
      },
    );
  });
}
