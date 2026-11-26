// App Store screenshot tour. Not part of CI: needs the prod screenshot demo account.
//
// Run through app-store-assets/capture.sh, which passes the credentials with --dart-define
// and grabs a native simulator screenshot on every "SHOT:<name>" line printed here.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/main_user.dart' as app;

const _email = String.fromEnvironment('SHOT_EMAIL');
const _phone = String.fromEnvironment('SHOT_PHONE');
const _code = String.fromEnvironment('SHOT_CODE');
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
    assert(_phone.isNotEmpty && _code.isNotEmpty, 'pass SHOT_PHONE/SHOT_CODE');
    // Debug-only third-party asserts (e.g. Zego ringtone audio context) must not end the tour.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (d) {
      // ignore: avoid_print
      print('IGNORED: ${d.exceptionAsString().split('\n').first}');
    };
    addTearDown(() => FlutterError.onError = originalOnError);
    app.main();
    await idle(t, 8);

    final container = ProviderScope.containerOf(ctx(t));
    container.read(languageProvider.notifier).setLanguage(
          _lang == 'en' ? AppLanguage.english : AppLanguage.arabic,
        );

    // Email/password is disabled on the project: sign in with the demo account's
    // Firebase test phone number (no SMS, no reCAPTCHA with verification disabled).
    if (FirebaseAuth.instance.currentUser?.email != _email) {
      final auth = FirebaseAuth.instance;
      await auth.signOut();
      await auth.setSettings(appVerificationDisabledForTesting: true);
      final verificationId = Completer<String>();
      await auth.verifyPhoneNumber(
        phoneNumber: _phone,
        verificationCompleted: (_) {},
        verificationFailed: (e) => verificationId.completeError(e),
        codeSent: (id, _) => verificationId.complete(id),
        codeAutoRetrievalTimeout: (_) {},
      );
      final id = await verificationId.future.timeout(const Duration(seconds: 30));
      await auth.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: id, smsCode: _code),
      );
    }
    await idle(t, 10);
    await go(t, '/', wait: 8);
    await shot(t, 'home');

    await go(t, '/chat', wait: 6);
    for (final agree in ['أوافق', 'Agree']) {
      if (find.text(agree).evaluate().isNotEmpty) {
        await t.tap(find.text(agree).last);
        await idle(t, 3);
      }
    }
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
