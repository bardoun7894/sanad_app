import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/app_strings.dart';
import 'package:sanad_app/core/l10n/app_strings_en.dart';
import 'package:sanad_app/core/l10n/app_strings_fr.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';

/// Pure validation function extracted from ProfileCompletionScreen logic.
/// This mirrors what the screen's validator will do after the fix.
String? validateName(String? value, {required bool isGoogleUser, required S s}) {
  if (value == null || value.isEmpty) return s.fieldRequired;
  if (!isGoogleUser) {
    final tokens = value.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.length < 2) return s.enterFullDualName;
  } else {
    // Google users: lenient — only check length >= 2
    if (value.length < 2) return s.nameTooShort;
  }
  return null;
}

void main() {
  final sAr = S(AppLanguage.arabic);
  final sEn = S(AppLanguage.english);
  final sFr = S(AppLanguage.french);

  group('Name validator — non-Google user (dual name required)', () {
    test('null value returns fieldRequired', () {
      expect(validateName(null, isGoogleUser: false, s: sEn), equals(AppStringsEn.fieldRequired));
    });

    test('empty value returns fieldRequired', () {
      expect(validateName('', isGoogleUser: false, s: sEn), equals(AppStringsEn.fieldRequired));
    });

    test('single word returns enterFullDualName error', () {
      expect(validateName('Mohamed', isGoogleUser: false, s: sEn), isNotNull);
      expect(validateName('Mohamed', isGoogleUser: false, s: sEn), equals(AppStringsEn.enterFullDualName));
    });

    test('single word with trailing spaces returns enterFullDualName error', () {
      expect(validateName('  Mohamed  ', isGoogleUser: false, s: sEn), isNotNull);
    });

    test('two words returns null (valid)', () {
      expect(validateName('Mohamed Bardouni', isGoogleUser: false, s: sEn), isNull);
    });

    test('two words with extra spaces returns null (valid)', () {
      expect(validateName('  Mohamed   Bardouni  ', isGoogleUser: false, s: sEn), isNull);
    });

    test('three words returns null (valid)', () {
      expect(validateName('Mohamed Ali Bardouni', isGoogleUser: false, s: sEn), isNull);
    });

    test('Arabic single word returns enterFullDualName in Arabic', () {
      final result = validateName('محمد', isGoogleUser: false, s: sAr);
      expect(result, isNotNull);
      expect(result, equals(AppStrings.enterFullDualName));
    });

    test('Arabic two-word name returns null (valid)', () {
      expect(validateName('محمد البردوني', isGoogleUser: false, s: sAr), isNull);
    });

    test('French single word returns enterFullDualName in French', () {
      final result = validateName('Mohamed', isGoogleUser: false, s: sFr);
      expect(result, isNotNull);
      expect(result, equals(AppStringsFr.enterFullDualName));
    });
  });

  group('Name validator — Google user (lenient, only length check)', () {
    test('null value returns fieldRequired', () {
      expect(validateName(null, isGoogleUser: true, s: sEn), equals(AppStringsEn.fieldRequired));
    });

    test('empty value returns fieldRequired', () {
      expect(validateName('', isGoogleUser: true, s: sEn), equals(AppStringsEn.fieldRequired));
    });

    test('single char returns nameTooShort', () {
      expect(validateName('M', isGoogleUser: true, s: sEn), equals(AppStringsEn.nameTooShort));
    });

    test('single word with length >= 2 returns null (valid for Google)', () {
      expect(validateName('Mohamed', isGoogleUser: true, s: sEn), isNull);
    });

    test('two-word name returns null (valid for Google)', () {
      expect(validateName('Mohamed Bardouni', isGoogleUser: true, s: sEn), isNull);
    });
  });

  group('String keys exist in all locales', () {
    test('AppStrings.enterFullDualName exists and is non-empty', () {
      expect(AppStrings.enterFullDualName, isNotEmpty);
    });

    test('AppStringsEn.enterFullDualName exists and is non-empty', () {
      expect(AppStringsEn.enterFullDualName, isNotEmpty);
    });

    test('AppStringsFr.enterFullDualName exists and is non-empty', () {
      expect(AppStringsFr.enterFullDualName, isNotEmpty);
    });

    test('S.enterFullDualName getter exists in Arabic', () {
      expect(sAr.enterFullDualName, equals(AppStrings.enterFullDualName));
    });

    test('S.enterFullDualName getter exists in English', () {
      expect(sEn.enterFullDualName, equals(AppStringsEn.enterFullDualName));
    });

    test('S.enterFullDualName getter exists in French', () {
      expect(sFr.enterFullDualName, equals(AppStringsFr.enterFullDualName));
    });
  });
}
