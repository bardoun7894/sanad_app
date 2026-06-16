import 'package:sanad_app/features/admin/providers/admin_invoices_provider.dart';

/// Pure CSV builder for the invoices table.
///
/// This function is pure (no side-effects, no DateTime.now(), no Flutter/web
/// imports) so it is trivially unit-testable. The browser download is a
/// separate side-effect handled in the widget layer via [downloadInvoicesCsvWeb].
///
/// Columns (Arabic headers matching the on-screen table):
/// العميل | تاريخ الاشتراك | المعالج المخصص |
/// قيمة الاشتراك الإجمالية | حصة المعالج | حصة التطبيق | حصة الصيانة
///
/// Encoding: UTF-8 with BOM (U+FEFF) so Excel opens the file with correct
/// Arabic character display without manual encoding selection.
///
/// Escaping: RFC 4180 — fields containing commas or double-quotes are wrapped
/// in double-quotes; embedded double-quotes are doubled.
String buildInvoicesCsv(List<InvoiceRecord> invoices) {
  final buf = StringBuffer();

  // UTF-8 BOM — Excel needs this to auto-detect UTF-8 Arabic text.
  buf.write('﻿');

  // Header row.
  buf.writeln(_row([
    'العميل',
    'تاريخ الاشتراك',
    'المعالج المخصص',
    'قيمة الاشتراك الإجمالية',
    'حصة المعالج',
    'حصة التطبيق',
    'حصة الصيانة',
  ]));

  // Data rows — only the supplied (already-filtered) invoices.
  for (final inv in invoices) {
    buf.writeln(_row([
      inv.clientName,
      _formatDate(inv.date),
      inv.therapistName,
      inv.amount.toStringAsFixed(2),
      inv.shares.therapist.toStringAsFixed(2),
      inv.shares.app.toStringAsFixed(2),
      inv.shares.maintenance.toStringAsFixed(2),
    ]));
  }

  return buf.toString();
}

/// Formats a DateTime as ISO-8601 date (YYYY-MM-DD) — locale-neutral.
String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Joins [fields] as a single CSV row.
String _row(List<String> fields) => fields.map(_escape).join(',');

/// RFC 4180 cell escaping:
/// - Any field containing a comma (ASCII or Arabic ،), double-quote, or
///   newline is wrapped in double-quotes.
/// - Embedded double-quotes are escaped as two consecutive double-quotes ("").
///
/// Note: the Arabic decimal comma (U+060C ،) is treated the same as the ASCII
/// comma (U+002C ,) because Excel treats both as potential delimiters in RTL
/// content; wrapping them prevents mis-parsed columns.
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
