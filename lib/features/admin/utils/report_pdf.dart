import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a patient report (the markdown subset the report generator emits:
/// #, ##, ###, "- " bullets, "> " notes, paragraphs and **bold**) to a PDF.
///
/// The patient name is added here, client-side, so it never reaches the AI.
class ReportPdf {
  static pw.Font? _regular;
  static pw.Font? _bold;

  // IBM Plex Sans Arabic carries Arabic and Latin glyphs in one font. A separate Latin
  // fallback font makes the pdf package reverse Latin runs inside RTL text.
  static Future<void> _loadFonts() async {
    if (_regular != null) return;
    Future<pw.Font> load(String name) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/report/$name'));
    _regular = await load('IBMPlexSansArabic-Regular.ttf');
    _bold = await load('IBMPlexSansArabic-Bold.ttf');
  }

  static const _primary = PdfColor.fromInt(0xFF2E7D7A);
  static const _muted = PdfColor.fromInt(0xFF5F6B6D);
  static const _noteBg = PdfColor.fromInt(0xFFFFF4E0);
  static const _sectionBg = PdfColor.fromInt(0xFFE8F3F2);

  static Future<Uint8List> build({
    required String markdown,
    required String locale,
    String? patientName,
    String nameLabel = 'Name',
  }) async {
    await _loadFonts();
    final rtl = locale == 'ar';
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: _regular!, bold: _bold!),
    );

    final body = _parse(
      rtl ? _fixRtl(markdown) : markdown,
      patientName: patientName == null || !rtl ? patientName : _fixRtl(patientName),
      nameLabel: nameLabel,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Sanad Therapy  •  ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        ),
        build: (_) => body,
      ),
    );
    return doc.save();
  }

  static final _harakat = RegExp('[\u064B-\u0652\u0670]');
  static final _isoDate = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
  static const _arMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  /// The pdf package mis-places Arabic diacritics and reorders hyphenated
  /// dates inside RTL lines (and draws bidi control marks as boxes), so drop
  /// the optional harakat and write ISO dates as "10 أكتوبر 2026".
  static String _fixRtl(String s) => s
      .replaceAll(_harakat, '')
      .replaceAllMapped(_isoDate, (m) {
        final month = int.parse(m[2]!);
        if (month < 1 || month > 12) return m[0]!;
        return '${int.parse(m[3]!)} ${_arMonths[month - 1]} ${m[1]}';
      });

  static List<pw.Widget> _parse(
    String markdown, {
    String? patientName,
    required String nameLabel,
  }) {
    final out = <pw.Widget>[];
    var titleDone = false;
    for (final raw in markdown.split('\n')) {
      final line = raw.trimRight();
      final t = line.trim();
      if (t.isEmpty) {
        out.add(pw.SizedBox(height: 4));
        continue;
      }
      if (t.startsWith('# ')) {
        out.add(pw.Text(_plain(t.substring(2)),
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _primary)));
        out.add(pw.Divider(color: _primary, thickness: 1.2));
        if (!titleDone && patientName != null && patientName.trim().isNotEmpty) {
          out.add(_rich('**$nameLabel:** ${patientName.trim()}', 11));
        }
        titleDone = true;
      } else if (t.startsWith('## ')) {
        out.add(pw.SizedBox(height: 8));
        out.add(pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: const pw.BoxDecoration(
            color: _sectionBg,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(_plain(t.substring(3)),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primary)),
        ));
        out.add(pw.SizedBox(height: 4));
      } else if (t.startsWith('### ')) {
        out.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
          child: pw.Text(_plain(t.substring(4)),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ));
      } else if (t.startsWith('> ')) {
        out.add(pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          margin: const pw.EdgeInsets.symmetric(vertical: 4),
          decoration: const pw.BoxDecoration(
            color: _noteBg,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: _rich(t.substring(2), 10),
        ));
      } else if (t.startsWith('- ') || t.startsWith('* ')) {
        out.add(pw.Padding(
          padding: const pw.EdgeInsetsDirectional.only(start: 8, bottom: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('•  ', style: const pw.TextStyle(fontSize: 11, color: _primary)),
              pw.Expanded(child: _rich(t.substring(2), 11)),
            ],
          ),
        ));
      } else {
        out.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: _rich(t, 11),
        ));
      }
    }
    return out;
  }

  /// Strips markdown emphasis markers.
  static String _plain(String s) => s.replaceAll('**', '').replaceAll(RegExp(r'(?<!\w)[*_](?!\s)|(?<!\s)[*_](?!\w)'), '');

  /// Text with **bold** spans.
  static pw.Widget _rich(String s, double size) {
    final parts = s.split('**');
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(fontSize: size, lineSpacing: 3, wordSpacing: 1.5),
        children: [
          for (var i = 0; i < parts.length; i++)
            if (parts[i].isNotEmpty)
              pw.TextSpan(
                text: _plain(parts[i]),
                style: i.isOdd ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
              ),
        ],
      ),
    );
  }
}
