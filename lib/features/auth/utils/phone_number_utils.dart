/// Pure helpers for composing and splitting E.164 phone numbers.
///
/// The profile-completion form stores the dial code in a country selector and
/// the rest of the number in a text field. Firebase Auth, however, hands back
/// full E.164 numbers ("+971..."), so any path that blindly prepends the
/// selected dial code produces doubled codes like "+966+971...". Every save
/// path must go through [composeE164], and prefills through [splitE164].
enum PhoneIssue { empty, wrongLength }

class PhoneNumberUtils {
  PhoneNumberUtils._();

  /// Mobile number length after the dial code, without the local trunk zero,
  /// for the countries Sanad's users actually sign up from. Countries not
  /// listed fall back to a 7-12 digit range in [validate].
  static const Map<String, int> _localLengths = {
    '249': 9, // Sudan
    '966': 9, // Saudi Arabia
    '971': 9, // UAE
    '962': 9, // Jordan
    '212': 9, // Morocco
    '213': 9, // Algeria
    '211': 9, // South Sudan
    '20': 10, // Egypt
    '964': 10, // Iraq
    '974': 8, // Qatar
    '965': 8, // Kuwait
    '973': 8, // Bahrain
    '968': 8, // Oman
    '216': 8, // Tunisia
  };

  static int? expectedLocalLength(String dialCode) => _localLengths[dialCode];

  static String _clean(String raw) => raw.replaceAll(RegExp(r'[\s\-()]'), '');

  /// Compose an E.164 string from the selected [dialCode] and the raw field
  /// text. Raw text that already carries a country code ("+..." or "00...")
  /// is returned normalized instead of getting [dialCode] prepended again.
  /// A local trunk zero ("0935...") is dropped — "+2490935..." is not dialable.
  static String composeE164(String dialCode, String raw) {
    final cleaned = _clean(raw);
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('00')) return '+${cleaned.substring(2)}';
    return '+$dialCode${cleaned.replaceFirst(RegExp(r'^0+'), '')}';
  }

  /// Validate a phone field. Returns null when the number is acceptable.
  static PhoneIssue? validate(String dialCode, String raw) {
    final cleaned = _clean(raw);
    if (cleaned.isEmpty) return PhoneIssue.empty;

    // Typed with its own international prefix: the selected country doesn't
    // apply, so only the overall E.164 length can be checked.
    if (cleaned.startsWith('+') || cleaned.startsWith('00')) {
      final digits = composeE164(dialCode, cleaned).substring(1);
      return digits.length >= 10 && digits.length <= 15
          ? null
          : PhoneIssue.wrongLength;
    }

    final local = cleaned.replaceFirst(RegExp(r'^0+'), '');
    final expected = _localLengths[dialCode];
    final ok = expected != null
        ? local.length == expected
        : local.length >= 7 && local.length <= 12;
    return ok ? null : PhoneIssue.wrongLength;
  }

  /// Split an international number into its dial code and local part using
  /// [knownDialCodes], longest code first. Returns null when the number has
  /// no international prefix or no known code matches.
  static ({String dialCode, String local})? splitE164(
    String e164,
    Iterable<String> knownDialCodes,
  ) {
    var digits = e164.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    } else if (digits.startsWith('00')) {
      digits = digits.substring(2);
    } else {
      return null;
    }

    final codes = knownDialCodes.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final code in codes) {
      if (digits.startsWith(code) && digits.length > code.length) {
        return (dialCode: code, local: digits.substring(code.length));
      }
    }
    return null;
  }
}
