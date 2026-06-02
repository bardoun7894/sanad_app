import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/models/cms_models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // DailyQuote — English field round-trip
  // ---------------------------------------------------------------------------
  group('DailyQuote English fields', () {
    test('constructor stores textEn and authorEn', () {
      final q = DailyQuote(
        id: 'q1',
        text: 'نص عربي',
        textEn: 'English tip',
        author: 'مؤلف',
        authorEn: 'Author EN',
      );
      expect(q.textEn, 'English tip');
      expect(q.authorEn, 'Author EN');
    });

    test('toMap() writes text_en and author_en keys', () {
      final q = DailyQuote(
        id: 'q1',
        text: 'نص عربي',
        textEn: 'English tip',
        author: 'مؤلف',
        authorEn: 'Author EN',
      );
      final map = q.toMap();
      expect(map['text_en'], 'English tip');
      expect(map['author_en'], 'Author EN');
    });

    test('toMap() writes empty strings when English fields are omitted', () {
      final q = DailyQuote(id: 'q2', text: 'نص عربي');
      final map = q.toMap();
      expect(map['text_en'], '');
      expect(map['author_en'], '');
    });

    // -------------------------------------------------------------------------
    // localizedText — regression guard
    // -------------------------------------------------------------------------
    test('localizedText returns textEn for "en" locale when textEn non-empty', () {
      final q = DailyQuote(
        id: 'q1',
        text: 'نص عربي',
        textEn: 'English tip',
      );
      expect(q.localizedText('en'), 'English tip');
    });

    test('localizedText falls back to Arabic text when textEn is empty', () {
      final q = DailyQuote(id: 'q1', text: 'نص عربي', textEn: '');
      expect(q.localizedText('en'), 'نص عربي');
    });

    test('localizedText returns Arabic text for "ar" locale even if textEn set', () {
      final q = DailyQuote(
        id: 'q1',
        text: 'نص عربي',
        textEn: 'English tip',
      );
      expect(q.localizedText('ar'), 'نص عربي');
    });

    // -------------------------------------------------------------------------
    // localizedAuthor — regression guard (bug was: returned `text` not `author`)
    // -------------------------------------------------------------------------
    test('localizedAuthor returns authorEn for "en" locale when authorEn non-empty', () {
      final q = DailyQuote(
        id: 'q1',
        text: 'نص عربي',
        author: 'مؤلف عربي',
        authorEn: 'English Author',
      );
      expect(q.localizedAuthor('en'), 'English Author');
    });

    test('localizedAuthor falls back to Arabic author (not text!) when authorEn empty', () {
      final q = DailyQuote(
        id: 'q1',
        text: 'نص النصيحة',
        author: 'مؤلف عربي',
        authorEn: '',
      );
      // Must return `author`, never `text`
      expect(q.localizedAuthor('en'), 'مؤلف عربي');
      expect(q.localizedAuthor('en'), isNot('نص النصيحة'));
    });

    test('localizedAuthor returns Arabic author for "ar" locale', () {
      final q = DailyQuote(
        id: 'q1',
        text: 'نص عربي',
        author: 'مؤلف عربي',
        authorEn: 'English Author',
      );
      expect(q.localizedAuthor('ar'), 'مؤلف عربي');
    });

    test('authorEn empty string does NOT default to "Sanad" or any fallback', () {
      final q = DailyQuote(id: 'q1', text: 'نص', textEn: 'tip', authorEn: '');
      // Empty authorEn means localizedAuthor('en') falls back to Arabic author
      // (which itself may be empty string — that is correct behavior)
      expect(q.authorEn, '');
    });
  });
}
