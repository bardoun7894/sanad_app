/// TDD red: Tests for multilingual therapist UI strings.
/// These tests verify that:
///   1. The new l10n keys exist in the S class.
///   2. The keys return correct values per language.
///   3. The _langCode helper maps AppLanguage to ISO code strings.
///
/// Tests will FAIL until Task 4 (l10n strings) is implemented.

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';

// Inline helper mirroring what the UI screens will use.
String _langCode(AppLanguage l) =>
    l == AppLanguage.english ? 'en' : (l == AppLanguage.french ? 'fr' : 'ar');

void main() {
  group('_langCode helper', () {
    test('maps arabic to ar', () {
      expect(_langCode(AppLanguage.arabic), 'ar');
    });
    test('maps english to en', () {
      expect(_langCode(AppLanguage.english), 'en');
    });
    test('maps french to fr', () {
      expect(_langCode(AppLanguage.french), 'fr');
    });
  });

  group('S — nameIn* keys exist and return non-empty strings', () {
    final sAr = S(AppLanguage.arabic);
    final sEn = S(AppLanguage.english);
    final sFr = S(AppLanguage.french);

    test('nameInArabic is non-empty in all languages', () {
      expect(sAr.nameInArabic, isNotEmpty);
      expect(sEn.nameInArabic, isNotEmpty);
      expect(sFr.nameInArabic, isNotEmpty);
    });

    test('nameInEnglish is non-empty in all languages', () {
      expect(sAr.nameInEnglish, isNotEmpty);
      expect(sEn.nameInEnglish, isNotEmpty);
      expect(sFr.nameInEnglish, isNotEmpty);
    });

    test('nameInFrench is non-empty in all languages', () {
      expect(sAr.nameInFrench, isNotEmpty);
      expect(sEn.nameInFrench, isNotEmpty);
      expect(sFr.nameInFrench, isNotEmpty);
    });
  });

  group('S — bioIn* keys exist and return non-empty strings', () {
    final sAr = S(AppLanguage.arabic);
    final sEn = S(AppLanguage.english);
    final sFr = S(AppLanguage.french);

    test('bioInArabic is non-empty in all languages', () {
      expect(sAr.bioInArabic, isNotEmpty);
      expect(sEn.bioInArabic, isNotEmpty);
      expect(sFr.bioInArabic, isNotEmpty);
    });

    test('bioInEnglish is non-empty in all languages', () {
      expect(sAr.bioInEnglish, isNotEmpty);
      expect(sEn.bioInEnglish, isNotEmpty);
      expect(sFr.bioInEnglish, isNotEmpty);
    });

    test('bioInFrench is non-empty in all languages', () {
      expect(sAr.bioInFrench, isNotEmpty);
      expect(sEn.bioInFrench, isNotEmpty);
      expect(sFr.bioInFrench, isNotEmpty);
    });
  });

  group('S — titleIn* keys exist and return non-empty strings', () {
    final sAr = S(AppLanguage.arabic);
    final sEn = S(AppLanguage.english);
    final sFr = S(AppLanguage.french);

    test('titleInArabic is non-empty in all languages', () {
      expect(sAr.titleInArabic, isNotEmpty);
      expect(sEn.titleInArabic, isNotEmpty);
      expect(sFr.titleInArabic, isNotEmpty);
    });

    test('titleInEnglish is non-empty in all languages', () {
      expect(sAr.titleInEnglish, isNotEmpty);
      expect(sEn.titleInEnglish, isNotEmpty);
      expect(sFr.titleInEnglish, isNotEmpty);
    });

    test('titleInFrench is non-empty in all languages', () {
      expect(sAr.titleInFrench, isNotEmpty);
      expect(sEn.titleInFrench, isNotEmpty);
      expect(sFr.titleInFrench, isNotEmpty);
    });
  });

  group('S — atLeastOneLanguageRequired key exists', () {
    final sAr = S(AppLanguage.arabic);
    final sEn = S(AppLanguage.english);
    final sFr = S(AppLanguage.french);

    test('atLeastOneLanguageRequired is non-empty in all languages', () {
      expect(sAr.atLeastOneLanguageRequired, isNotEmpty);
      expect(sEn.atLeastOneLanguageRequired, isNotEmpty);
      expect(sFr.atLeastOneLanguageRequired, isNotEmpty);
    });

    test('English variant matches spec exactly', () {
      expect(sEn.atLeastOneLanguageRequired,
          'At least one language is required');
    });
  });

  group('S — nameIn* values match spec per language', () {
    test('nameInArabic Arabic variant', () {
      final sAr = S(AppLanguage.arabic);
      expect(sAr.nameInArabic, 'الاسم بالعربية');
    });

    test('nameInEnglish English variant', () {
      final sEn = S(AppLanguage.english);
      expect(sEn.nameInEnglish, 'Name (English)');
    });

    test('nameInFrench French variant', () {
      final sFr = S(AppLanguage.french);
      expect(sFr.nameInFrench, 'Nom (Français)');
    });
  });
}
