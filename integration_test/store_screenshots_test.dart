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
    // Debug-only third-party asserts (e.g. Zego ringtone audio context) must not end the tour.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (d) {
      // ignore: avoid_print
      print('IGNORED: ${d.exceptionAsString().split('\n').first}');
    };
    addTearDown(() => FlutterError.onError = originalOnError);
    // Uncaught async errors from app startup would fail the test and blank the app.
    runZonedGuarded(app.main, (e, _) {
      // ignore: avoid_print
      print('IGNORED ZONE: ${e.toString().split('\n').first}');
    });
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
    await go(t, '/', wait: 18); // recommendations row loads last
    await shot(t, 'home');

    await go(t, '/chat', wait: 6);
    // Start from an empty AI conversation (earlier runs leave history behind).
    if (find.byIcon(Icons.delete_outline_rounded).evaluate().isNotEmpty) {
      await t.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await idle(t, 2);
      for (final label in ['مسح المحادثة', 'Clear chat']) {
        if (find.text(label).evaluate().length > 1) {
          await t.tap(find.text(label).last); // dialog action, not the dialog title
          await idle(t, 3);
        }
      }
    }
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
      // The AI-consent dialog appears a few seconds after the first send; the
      // pending message continues once it is accepted.
      var accepted = false;
      for (var i = 0; i < 20 && !accepted; i++) {
        await idle(t, 1);
        for (final agree in ['أوافق', 'Agree']) {
          if (!accepted && find.text(agree).evaluate().isNotEmpty) {
            await t.tap(find.text(agree).last);
            accepted = true;
          }
        }
      }
      await idle(t, 25);
    }
    await shot(t, 'chat');

    for (final r in [
      // Insights, therapy selection and community are left out (empty states, real
      // users' posts); coaches too: real coaches' faces stay out of the listing.
      ['mood', '/mood-tracker'],
      ['exercises', '/exercises'],
      ['tests', '/psychological-tests'],
      ['journal', '/journal'],
      ['subscription', '/subscription'],
    ]) {
      await go(t, r[1]);
      await shot(t, r[0]);
    }
    await go(t, '/', wait: 2);
  },
      timeout: const Timeout(Duration(minutes: 10)),
      // Only runs through app-store-assets/capture.sh, which passes the demo credentials.
      skip: _phone.isEmpty);
}
