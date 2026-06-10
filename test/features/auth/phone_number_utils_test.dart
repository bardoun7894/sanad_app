import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/auth/utils/phone_number_utils.dart';

void main() {
  group('composeE164', () {
    test('prepends dial code to a bare local number', () {
      expect(
        PhoneNumberUtils.composeE164('966', '533316144'),
        '+966533316144',
      );
    });

    test('returns empty string for blank input', () {
      expect(PhoneNumberUtils.composeE164('966', '   '), '');
    });

    test('does not double-prepend when raw already starts with + '
        '(the +966+971 bug)', () {
      expect(
        PhoneNumberUtils.composeE164('966', '+9713316144'),
        '+9713316144',
      );
    });

    test('normalizes 00-prefixed international numbers', () {
      expect(
        PhoneNumberUtils.composeE164('966', '00971554503909'),
        '+971554503909',
      );
    });

    test('strips spaces, dashes and parentheses', () {
      expect(
        PhoneNumberUtils.composeE164('971', '055 450-3909'),
        '+9710554503909',
      );
    });
  });

  group('splitE164', () {
    const codes = ['966', '971', '1', '212', '20'];

    test('splits a +-prefixed number on the longest matching dial code', () {
      final r = PhoneNumberUtils.splitE164('+9713316144', codes);
      expect(r?.dialCode, '971');
      expect(r?.local, '3316144');
    });

    test('returns null for a local number without country code', () {
      expect(PhoneNumberUtils.splitE164('0533316144', codes), isNull);
    });

    test('handles the 00 international prefix', () {
      final r = PhoneNumberUtils.splitE164('00966533316144', codes);
      expect(r?.dialCode, '966');
      expect(r?.local, '533316144');
    });

    test('returns null when no known dial code matches', () {
      expect(PhoneNumberUtils.splitE164('+99912345', ['966', '971']), isNull);
    });

    test('prefers the longer dial code when both match', () {
      final r = PhoneNumberUtils.splitE164('+2126612345', codes);
      expect(r?.dialCode, '212');
      expect(r?.local, '6612345');
    });
  });
}
