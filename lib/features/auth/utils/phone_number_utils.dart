/// Pure helpers for composing and splitting E.164 phone numbers.
///
/// The profile-completion form stores the dial code in a country selector and
/// the rest of the number in a text field. Firebase Auth, however, hands back
/// full E.164 numbers ("+971..."), so any path that blindly prepends the
/// selected dial code produces doubled codes like "+966+971...". Every save
/// path must go through [composeE164], and prefills through [splitE164].
class PhoneNumberUtils {
  PhoneNumberUtils._();

  /// Compose an E.164 string from the selected [dialCode] and the raw field
  /// text. Raw text that already carries a country code ("+..." or "00...")
  /// is returned normalized instead of getting [dialCode] prepended again.
  static String composeE164(String dialCode, String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('00')) return '+${cleaned.substring(2)}';
    return '+$dialCode$cleaned';
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
