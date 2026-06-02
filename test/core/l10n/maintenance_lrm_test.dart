import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/app_strings.dart';
import 'package:sanad_app/core/l10n/app_strings_fr.dart';

void main() {
  group('LRM markers in maintenance body strings', () {
    test(
      'AR maintenanceBody wraps email with LRM so it stays LTR in RTL prose',
      () {
        const lrm = '‎';
        expect(
          AppStrings.maintenanceBody,
          contains('${lrm}support@sanadtherapy.com$lrm'),
        );
      },
    );

    test(
      'FR maintenanceBody wraps email with LRM for consistent bidi handling',
      () {
        const lrm = '‎';
        expect(
          AppStringsFr.maintenanceBody,
          contains('${lrm}support@sanadtherapy.com$lrm'),
        );
      },
    );
  });

  group('New App Gates l10n keys exist', () {
    test('AR has maintenanceEnableConfirmTitle', () {
      expect(AppStrings.maintenanceEnableConfirmTitle, isNotEmpty);
    });

    test('AR has maintenanceEnableConfirmBody', () {
      expect(AppStrings.maintenanceEnableConfirmBody, isNotEmpty);
    });

    test('AR has minVersionConfirmTitle', () {
      expect(AppStrings.minVersionConfirmTitle, isNotEmpty);
    });

    test('AR has minVersionConfirmBody', () {
      expect(AppStrings.minVersionConfirmBody, isNotEmpty);
    });

    test('AR has minVersionInvalid', () {
      expect(AppStrings.minVersionInvalid, isNotEmpty);
    });

    test('AR has appGatesSectionTitle', () {
      expect(AppStrings.appGatesSectionTitle, isNotEmpty);
    });

    test('AR has appGatesSectionWarning', () {
      expect(AppStrings.appGatesSectionWarning, isNotEmpty);
    });

    test('AR has currentPublishedVersion', () {
      expect(AppStrings.currentPublishedVersion, isNotEmpty);
    });

    test('AR has settingsLoadFailed', () {
      expect(AppStrings.settingsLoadFailed, isNotEmpty);
    });

    test('AR has settingsSaveFailed', () {
      expect(AppStrings.settingsSaveFailed, isNotEmpty);
    });
  });
}
