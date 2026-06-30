import '../providers/admin_users_provider.dart';

/// Pure CSV builder for the users table.
///
/// Pure (no side-effects, no DateTime.now(), no Flutter/web imports) so it is
/// trivially unit-testable. The browser download is a separate side-effect
/// handled in the widget layer via [downloadCsvOnWeb].
///
/// Columns (Arabic headers matching the on-screen table semantics):
/// الاسم | البريد الإلكتروني | الهاتف | واتساب | الجنس | الدور |
/// الاشتراك | حالة الاشتراك | المعالج المخصص | الملف مكتمل |
/// مزود الدخول | تاريخ التسجيل
///
/// Encoding: UTF-8 with BOM (U+FEFF) so Excel opens the file with correct
/// Arabic character display without manual encoding selection.
///
/// Escaping: RFC 4180 — fields containing commas or double-quotes are wrapped
/// in double-quotes; embedded double-quotes are doubled.
String buildUsersCsv(List<AdminUser> users) {
  final buf = StringBuffer();

  // UTF-8 BOM — Excel needs this to auto-detect UTF-8 Arabic text.
  buf.write('﻿');

  // Header row.
  buf.writeln(_row([
    'الاسم',
    'البريد الإلكتروني',
    'الهاتف',
    'واتساب',
    'الجنس',
    'الدور',
    'الاشتراك',
    'حالة الاشتراك',
    'المعالج المخصص',
    'الملف مكتمل',
    'مزود الدخول',
    'تاريخ التسجيل',
  ]));

  // Data rows — only the supplied (already-filtered) users.
  for (final u in users) {
    buf.writeln(_row([
      u.fullName ?? '',
      _clean(u.email),
      u.phoneNumber ?? '',
      u.whatsappNumber ?? '',
      u.gender ?? '',
      u.role,
      u.isPremium ? 'مدفوع' : 'مجاني',
      u.subscriptionStatus,
      u.assignedTherapistName ?? '',
      u.hasCompleteProfile ? 'نعم' : 'لا',
      u.authProvider ?? '',
      _formatDate(u.createdAt),
    ]));
  }

  return buf.toString();
}

/// Normalises the "No Email" placeholder back to an empty cell.
String _clean(String value) =>
    (value == 'No Email' || value.trim().isEmpty) ? '' : value;

/// Formats a DateTime as ISO-8601 date (YYYY-MM-DD) — locale-neutral.
/// Returns an empty string for missing dates.
String _formatDate(DateTime? dt) {
  if (dt == null) return '';
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Joins [fields] as a single CSV row.
String _row(List<String> fields) => fields.map(_escape).join(',');

/// RFC 4180 cell escaping — see [buildUsersCsv] docs. The Arabic decimal comma
/// (U+060C ،) is treated the same as the ASCII comma because Excel treats both
/// as potential delimiters in RTL content.
String _escape(String value) {
  const asciiComma = ',';
  const arabicComma = '،'; // U+060C — used in Arabic text
  final needsQuote = value.contains(asciiComma) ||
      value.contains(arabicComma) ||
      value.contains('"') ||
      value.contains('\n');
  if (!needsQuote) return value;
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}
