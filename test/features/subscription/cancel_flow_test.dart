// test/features/subscription/cancel_flow_test.dart
// TDD tests for subscription cancel flow: snackbar text, date formatting, RTL wrapping, error handling.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/subscription/models/subscription_status.dart';
import 'package:sanad_app/features/subscription/models/subscription_product.dart';
import 'package:sanad_app/features/subscription/providers/subscription_provider.dart';
import 'package:sanad_app/features/subscription/screens/subscription_screen.dart';

// ---------------------------------------------------------------------------
// FakeSubscriptionNotifier
//
// Uses `implements SubscriptionNotifier` to satisfy Riverpod's type check
// at the overrideWith site, while extending `StateNotifier` directly so no
// real constructor body (which would call Firebase) is ever executed.
//
// `noSuchMethod` covers every SubscriptionNotifier method not overridden
// here — they are never called by the cancel-flow code path under test.
// ---------------------------------------------------------------------------

// ignore: must_be_immutable
class _FakeSubscriptionNotifier extends StateNotifier<SubscriptionUIState>
    implements SubscriptionNotifier {
  bool throwOnCancel;
  DateTime? postCancelExpiry;

  _FakeSubscriptionNotifier(
    SubscriptionUIState initial, {
    this.throwOnCancel = false,
    this.postCancelExpiry,
  }) : super(initial);

  @override
  Future<void> cancelSubscription() async {
    if (throwOnCancel) throw Exception('network error');
    state = state.copyWith(
      status: SubscriptionStatus(
        state: SubscriptionState.cancelled,
        expiryDate: postCancelExpiry,
      ),
    );
  }

  // Satisfies the `implements SubscriptionNotifier` contract for every method
  // not overridden above — they are unreachable in this test path.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ---------------------------------------------------------------------------
// Build helpers
// ---------------------------------------------------------------------------

SubscriptionUIState _premiumState({DateTime? expiryDate}) {
  return SubscriptionUIState(
    status: SubscriptionStatus(
      state: SubscriptionState.active,
      expiryDate: expiryDate,
    ),
    products: SubscriptionProduct.allProducts,
    isLoading: false,
    isInitialized: true,
  );
}

Widget _buildApp({
  required _FakeSubscriptionNotifier notifier,
  required AppLanguage language,
}) {
  return ProviderScope(
    overrides: [
      subscriptionProvider.overrideWith((ref) => notifier),
      languageProvider.overrideWith(
        (ref) => LanguageNotifier()..setLanguage(language),
      ),
    ],
    child: MaterialApp(
      home: const SubscriptionScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  // ── formatSubscriptionDate unit tests ──────────────────────────────────────

  group('formatSubscriptionDate', () {
    test('en locale matches DateFormat.yMd(en)', () {
      final date = DateTime(2025, 3, 15);
      expect(
        formatSubscriptionDate(date, 'en'),
        DateFormat.yMd('en').format(date),
      );
    });

    test('ar locale matches DateFormat.yMd(ar)', () {
      final date = DateTime(2025, 3, 15);
      expect(
        formatSubscriptionDate(date, 'ar'),
        DateFormat.yMd('ar').format(date),
      );
    });

    test('fr locale matches DateFormat.yMd(fr)', () {
      final date = DateTime(2025, 3, 15);
      expect(
        formatSubscriptionDate(date, 'fr'),
        DateFormat.yMd('fr').format(date),
      );
    });

    test('en result does not use hardcoded YYYY-MM-DD format', () {
      final date = DateTime(2025, 3, 15);
      expect(formatSubscriptionDate(date, 'en'), isNot(equals('2025-03-15')));
    });
  });

  // ── wrapDateForLocale unit tests ───────────────────────────────────────────

  group('wrapDateForLocale', () {
    test('ar locale wraps with LRM marks', () {
      const date = '3/15/2025';
      final wrapped = wrapDateForLocale(date, 'ar');
      expect(wrapped, contains(date));
      // U+200E LRM must be present
      expect(wrapped.codeUnits, contains(0x200E));
    });

    test('en locale does not add LRM marks', () {
      const date = '3/15/2025';
      final wrapped = wrapDateForLocale(date, 'en');
      expect(wrapped, equals(date));
      expect(wrapped.codeUnits, isNot(contains(0x200E)));
    });

    test('fr locale does not add LRM marks', () {
      const date = '15/03/2025';
      final wrapped = wrapDateForLocale(date, 'fr');
      expect(wrapped, equals(date));
    });
  });

  // ── Cancel flow widget tests ───────────────────────────────────────────────

  group('Cancel flow – EN locale', () {
    testWidgets('snackbar shows localised text with interpolated date (en)',
        (tester) async {
      // Use a future date so SubscriptionStatus.isActive returns true.
      final expiry = DateTime(2027, 8, 20);
      final notifier = _FakeSubscriptionNotifier(
        _premiumState(expiryDate: expiry),
        postCancelExpiry: expiry,
      );

      await tester.pumpWidget(_buildApp(notifier: notifier, language: AppLanguage.english));
      await tester.pumpAndSettle();

      // Scroll to the cancel button (it may be below the fold)
      await tester.scrollUntilVisible(
        find.text('Cancel Subscription').last,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cancel Subscription').last);
      await tester.pumpAndSettle();

      // Tap the confirm (destructive) action inside the dialog.
      // The dialog title is also "Cancel Subscription" so use .last to get the button.
      final dialogConfirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel Subscription'),
      ).last;
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      final formattedDate = formatSubscriptionDate(expiry, 'en');
      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      final textWidget = snackbar.content as Text;
      expect(textWidget.data, contains(formattedDate));
    });

    testWidgets('snackbar has floating behavior and 4s duration (en)',
        (tester) async {
      final expiry = DateTime(2027, 8, 20);
      final notifier = _FakeSubscriptionNotifier(
        _premiumState(expiryDate: expiry),
        postCancelExpiry: expiry,
      );

      await tester.pumpWidget(_buildApp(notifier: notifier, language: AppLanguage.english));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Cancel Subscription').last,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cancel Subscription').last);
      await tester.pumpAndSettle();

      // The dialog title is also "Cancel Subscription" so use .last to get the button.
      final dialogConfirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel Subscription'),
      ).last;
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackbar.behavior, SnackBarBehavior.floating);
      expect(snackbar.duration, const Duration(seconds: 4));
    });
  });

  group('Cancel flow – AR locale', () {
    testWidgets('snackbar shows localised text with interpolated date (ar)',
        (tester) async {
      final expiry = DateTime(2027, 8, 20);
      final notifier = _FakeSubscriptionNotifier(
        _premiumState(expiryDate: expiry),
        postCancelExpiry: expiry,
      );

      await tester.pumpWidget(_buildApp(notifier: notifier, language: AppLanguage.arabic));
      await tester.pumpAndSettle();

      // Scroll to bring the cancel button into view
      await tester.scrollUntilVisible(
        find.text('إلغاء الاشتراك').last,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('إلغاء الاشتراك').last);
      await tester.pumpAndSettle();

      // Tap confirm in dialog — the dialog title is also "إلغاء الاشتراك" so use .last.
      final dialogConfirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('إلغاء الاشتراك'),
      ).last;
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      final rawDate = formatSubscriptionDate(expiry, 'ar');
      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      final textWidget = snackbar.content as Text;
      // Strip LRM marks when asserting the raw date portion
      final snackText = textWidget.data!.replaceAll('‎', '');
      expect(snackText, contains(rawDate));
    });
  });

  group('Cancel flow – error path', () {
    testWidgets('shows subscriptionCancelError snackbar, not raw exception (en)',
        (tester) async {
      final notifier = _FakeSubscriptionNotifier(
        _premiumState(expiryDate: DateTime(2027, 8, 20)),
        throwOnCancel: true,
      );

      await tester.pumpWidget(_buildApp(notifier: notifier, language: AppLanguage.english));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Cancel Subscription').last,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cancel Subscription').last);
      await tester.pumpAndSettle();

      // The dialog title is also "Cancel Subscription" so use .last to get the button.
      final dialogConfirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel Subscription'),
      ).last;
      await tester.tap(dialogConfirm);
      await tester.pumpAndSettle();

      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      final textWidget = snackbar.content as Text;
      // Must NOT expose the raw Exception string
      expect(textWidget.data, isNot(startsWith('Exception:')));
      // Must match the localized friendly error message
      expect(textWidget.data, equals(S(AppLanguage.english).subscriptionCancelError));
    });
  });
}
