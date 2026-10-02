import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/auth/models/auth_user.dart';
import 'package:sanad_app/features/insights/insights_screen.dart';

final _account = StateProvider<String?>((ref) => 'alice');

void main() {
  ProviderContainer containerFor(
    Future<Map<String, dynamic>> Function(String) fetch,
  ) {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) {
          final uid = ref.watch(_account);
          return uid == null
              ? null
              : AuthUser(
                  uid: uid,
                  email: 'user@example.test',
                  createdAt: DateTime(2026),
                  provider: AuthProvider.email,
                );
        }),
        languageProvider.overrideWith(
          (ref) => LanguageNotifier(initial: AppLanguage.english),
        ),
        insightsPatternsCallableProvider.overrideWithValue(fetch),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> open(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
  }

  Map<String, dynamic> themes(String uid) => {
    'noteThemes': ['$uid private health theme'],
  };

  testWidgets(
    'completed health insights clear immediately for another account and sign-out',
    (tester) async {
      final bob = Completer<Map<String, dynamic>>();
      final requested = <String>[];
      final container = containerFor((uid) {
        requested.add(uid);
        return uid == 'alice' ? Future.value(themes('alice')) : bob.future;
      });
      await open(tester, container);
      await tester.pumpAndSettle();
      expect(find.text('alice private health theme'), findsOneWidget);
      container.read(_account.notifier).state = 'bob';
      await tester.pump();
      expect(find.text('alice private health theme'), findsNothing);
      bob.complete(themes('bob'));
      await tester.pumpAndSettle();
      expect(find.text('bob private health theme'), findsOneWidget);
      container.read(_account.notifier).state = null;
      await tester.pumpAndSettle();
      expect(find.text('bob private health theme'), findsNothing);
      expect(requested, ['alice', 'bob']);
    },
  );

  for (final aliceCompletesFirst in [true, false]) {
    testWidgets(
      'old inflight insights never replace new account data, old finishes ${aliceCompletesFirst ? 'first' : 'last'}',
      (tester) async {
        final alice = Completer<Map<String, dynamic>>();
        final bob = Completer<Map<String, dynamic>>();
        final requested = <String>[];
        final container = containerFor((uid) {
          requested.add(uid);
          return uid == 'alice' ? alice.future : bob.future;
        });
        await open(tester, container);
        await tester.pump();
        container.read(_account.notifier).state = 'bob';
        await tester.pump();
        if (aliceCompletesFirst) {
          alice.complete(themes('alice'));
          await tester.pump();
          expect(find.text('alice private health theme'), findsNothing);
        }
        bob.complete(themes('bob'));
        await tester.pumpAndSettle();
        expect(find.text('bob private health theme'), findsOneWidget);
        if (!aliceCompletesFirst) {
          alice.complete(themes('alice'));
          await tester.pumpAndSettle();
        }
        expect(find.text('alice private health theme'), findsNothing);
        expect(find.text('bob private health theme'), findsOneWidget);
        expect(requested, ['alice', 'bob']);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
