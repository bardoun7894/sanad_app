import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/more/static_page_screen.dart';

void main() {
  const data = {
    'content_ar': 'نص مشترك',
    'content_ar_ios': 'نص أبل',
    'content_en': 'shared',
    'content_en_ios': 'apple',
  };

  test('Android reads the shared fields', () {
    expect(pickStaticPageContent(data, AppLanguage.arabic, apple: false), 'نص مشترك');
    expect(pickStaticPageContent(data, AppLanguage.english, apple: false), 'shared');
  });

  test('Apple build prefers the _ios fields', () {
    expect(pickStaticPageContent(data, AppLanguage.arabic, apple: true), 'نص أبل');
    expect(pickStaticPageContent(data, AppLanguage.english, apple: true), 'apple');
    expect(pickStaticPageContent(data, AppLanguage.french, apple: true), 'apple');
  });

  test('Apple build falls back to shared text when _ios is missing or blank', () {
    const noIos = {'content_ar': 'نص مشترك', 'content_ar_ios': '  ', 'content_en': 'shared'};
    expect(pickStaticPageContent(noIos, AppLanguage.arabic, apple: true), 'نص مشترك');
    expect(pickStaticPageContent(noIos, AppLanguage.english, apple: true), 'shared');
  });

  test('missing document gives empty text', () {
    expect(pickStaticPageContent(null, AppLanguage.arabic, apple: true), '');
  });
}
