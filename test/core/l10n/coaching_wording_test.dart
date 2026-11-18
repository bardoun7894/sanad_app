import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/config/store_profile.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/therapists/widgets/coaching_disclaimer.dart';

import 'all_string_getters.dart';

void main() {
  tearDown(() => appleCoachingBuildOverride = null);

  Map<String, String> sample(S s) => {
    'navTherapists': s.navTherapists,
    'therapySessions': s.therapySessions,
    'psychologicalTests': s.psychologicalTests,
    'talkToTherapist': s.talkToTherapist,
    'therapyCall': s.therapyCall,
    'featureDirectTherapist': s.featureDirectTherapist,
    'therapyIndividualDesc': s.therapyIndividualDesc,
    'findTherapist': s.findTherapist,
  };

  test('iOS: support and booking strings say counselor, not specialist', () {
    appleCoachingBuildOverride = false;
    expect(S(AppLanguage.arabic).bookSpecialistTitle, 'احجز جلسة مع أخصائي');

    appleCoachingBuildOverride = true;
    final ar = S(AppLanguage.arabic);
    expect(ar.connectWithProfessional, 'تواصل مع مستشار معتمد يمكنه تقديم دعم شخصي لك.');
    expect(ar.bookSpecialistTitle, 'احجز جلسة مع مستشار');
    final en = S(AppLanguage.english);
    expect(en.connectWithProfessional, contains('certified counselor'));
    expect(en.bookSpecialistTitle, 'Book a Session with a Counselor');
    final fr = S(AppLanguage.french);
    expect(fr.connectWithProfessional, contains('conseiller certifié'));
    expect(fr.bookSpecialistTitle, 'Réserver une séance avec un conseiller');
  });

  test('Arabic: original off iOS, coaching on iOS', () {
    final s = S(AppLanguage.arabic);
    appleCoachingBuildOverride = false;
    final orig = sample(s);
    expect(orig['navTherapists'], 'المعالجين');
    expect(orig['therapySessions'], 'جلسات العلاج');
    expect(orig['therapyCall'], 'مكالمة علاجية');
    expect(orig['psychologicalTests'], 'الاختبارات النفسية');

    appleCoachingBuildOverride = true;
    final ios = sample(s);
    expect(ios['navTherapists'], 'الكوتشز');
    expect(ios['therapySessions'], 'جلسات الكوتشينج');
    expect(ios['therapyCall'], 'مكالمة كوتشينج');
    expect(ios['psychologicalTests'], 'اختبارات التقييم الذاتي');
    expect(ios['therapyIndividualDesc'], 'جلسات خاصة مع كوتش معتمد');
    for (final e in ios.entries) {
      expect(e.value, isNot(contains('معالج')), reason: e.key);
      expect(e.value, isNot(contains('علاج')), reason: e.key);
    }
  });

  test('English: original off iOS, coaching on iOS', () {
    final s = S(AppLanguage.english);
    appleCoachingBuildOverride = false;
    final orig = sample(s);
    expect(orig['navTherapists'], 'Therapists');
    expect(orig['findTherapist'], contains('Therapist'));

    appleCoachingBuildOverride = true;
    final ios = sample(s);
    expect(ios['navTherapists'], 'Coaches');
    for (final e in ios.entries) {
      expect(e.value.toLowerCase(), isNot(contains('therap')), reason: e.key);
      expect(
        e.value.toLowerCase(),
        isNot(contains('psycholog')),
        reason: e.key,
      );
    }
  });

  test('French: thérapeute becomes coach on iOS only', () {
    final s = S(AppLanguage.french);
    appleCoachingBuildOverride = false;
    expect(s.navTherapists, 'Thérapeutes');
    appleCoachingBuildOverride = true;
    expect(s.navTherapists, 'Coachs');
  });

  test('excluded portal keys and brand unchanged on iOS', () {
    appleCoachingBuildOverride = true;
    final ar = S(AppLanguage.arabic);
    expect(ar.therapistDashboard, 'لوحة تحكم المعالج');
    expect(ar.registerAsTherapist, 'التسجيل كمعالج');
    expect(ar.bankAccountHolder, 'Sanad Therapy');
    expect(S(AppLanguage.english).bankAccountHolder, 'Sanad Therapy');
  });

  test('processing (معالجة) is not rewritten', () {
    appleCoachingBuildOverride = true;
    expect(S(AppLanguage.arabic).processingPayment, contains('معالجة'));
  });

  test('report: Arabic values still containing therapy words on iOS', () {
    appleCoachingBuildOverride = true;
    final all = allStringGetters(S(AppLanguage.arabic));
    final re = RegExp(r'معالج(?![ةت])|علاج');
    final left = all.entries.where((e) => re.hasMatch(e.value)).toList();
    // ignore: avoid_print
    print('IOS_AR_TOTAL=${all.length} REMAINING=${left.length}');
    for (final e in left) {
      // ignore: avoid_print
      print('REMAINING ${e.key}: ${e.value}');
    }
  });

  Future<void> pumpDisclaimer(WidgetTester tester) => tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: Scaffold(body: CoachingDisclaimer())),
    ),
  );

  testWidgets('booking disclaimer hidden off iOS', (tester) async {
    appleCoachingBuildOverride = false;
    await pumpDisclaimer(tester);
    expect(find.byKey(const Key('coaching_disclaimer')), findsNothing);
  });

  testWidgets('booking disclaimer visible on iOS', (tester) async {
    appleCoachingBuildOverride = true;
    await pumpDisclaimer(tester);
    expect(find.byKey(const Key('coaching_disclaimer')), findsOneWidget);
    expect(find.text(CoachingDisclaimer.ar), findsOneWidget);
  });

  test('disclaimer texts per language', () {
    expect(
      CoachingDisclaimer.textFor(AppLanguage.english),
      'Coaching sessions for personal development, not psychological or medical treatment or diagnosis.',
    );
    expect(
      CoachingDisclaimer.textFor(AppLanguage.french),
      startsWith('Séances de coaching'),
    );
  });
}
