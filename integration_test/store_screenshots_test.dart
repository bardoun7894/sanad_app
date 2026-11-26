// App Store screenshot tour. Not part of CI: needs the prod screenshot demo account.
//
// Run through app-store-assets/capture.sh, which passes the credentials with --dart-define
// and grabs a native simulator screenshot on every "SHOT:<name>" line printed here.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/main_user.dart' as app;

const _email = String.fromEnvironment('SHOT_EMAIL');
const _password = String.fromEnvironment('SHOT_PASSWORD');
const _lang = String.fromEnvironment('SHOT_LANG', defaultValue: 'ar');
const _chatPrompt = String.fromEnvironment('SHOT_CHAT');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> idle(WidgetTester t, int seconds) async {
    for (var i = 0; i < seconds * 4; i++) {
      await t.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await idle(t, 2);
    // ignore: avoid_print
    print('SHOT:$name');
    await idle(t, 4); // host grabs the frame while we keep rendering
  }

  BuildContext ctx(WidgetTester t) => t.element(find.byType(Scaffold).first);

  Future<void> go(WidgetTester t, String route, {int wait = 6}) async {
    GoRouter.of(ctx(t)).go(route);
    await idle(t, wait);
  }

  testWidgets('store screenshot tour', (t) async {
    assert(_email.isNotEmpty && _password.isNotEmpty, 'pass SHOT_EMAIL/SHOT_PASSWORD');
    app.main();
    await idle(t, 8);

    final container = ProviderScope.containerOf(ctx(t));
    container.read(languageProvider.notifier).setLanguage(
          _lang == 'en' ? AppLanguage.english : AppLanguage.arabic,
        );

    if (FirebaseAuth.instance.currentUser?.email != _email) {
      await FirebaseAuth.instance.signOut();
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email, password: _password);
    }
    await idle(t, 10);
    await go(t, '/', wait: 8);
    await shot(t, 'home');

    await go(t, '/chat', wait: 6);
    if (_chatPrompt.isNotEmpty) {
      await t.enterText(find.byType(TextField).last, _chatPrompt);
      await idle(t, 1);
      await t.tap(find.byIcon(Icons.send_rounded).last);
      await idle(t, 25);
    }
    await shot(t, 'chat');

    for (final r in [
      ['mood', '/mood-tracker'],
      ['insights', '/insights'],
      ['exercises', '/exercises'],
      ['coaches', '/therapists'],
      ['selection', '/therapy-selection'],
      ['tests', '/psychological-tests'],
      ['journal', '/journal'],
      ['community', '/community'],
      ['subscription', '/subscription'],
    ]) {
      await go(t, r[1]);
      await shot(t, r[0]);
    }
    await go(t, '/', wait: 2);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
