import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/utils/report_pdf.dart';

const _md = '''# التقرير النفسي

**الفترة:** من 2026-10-10 إلى 2026-11-08 (30 يوماً)

**تاريخ الإصدار:** 2026-11-09

> لم تتم الموافقة على مشاركة البيانات التفصيلية للتحليل، لذلك يقتصر هذا التقرير على المزاج اليومي ونتائج الاختبارات ومستوى التفاعل مع التطبيق.

## 1. الملخص السريري

خلال هذه الفترة سُجِّل المزاج 12 مرة، وكانت الحالة الغالبة "قلق"، بمتوسط 2.8 من 5.

## 2. أنماط المزاج

- عدد تسجيلات المزاج: 12 (في 11 يوماً)
- **الحالات الأكثر تكراراً:** قلق (5)، هادئ (4)، حزين (3)

### المتوسط الأسبوعي

- أسبوع 2026-10-13: 3.2 من 5 (4 تسجيل)

## 3. نتائج الاختبارات النفسية

- 2026-10-20: PHQ-9، الدرجة 12، moderate

## 4. تقييم المخاطر

- **مستوى الخطر الحالي:** متوسط

## 5. مستوى التفاعل مع التطبيق

- أيام النشاط في التطبيق: 27 من 30 يوماً (90%): تفاعل منتظم

## 6. التوصيات

- تسجيل المزاج يومياً من التطبيق، حتى يكون التقرير القادم أدق.
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds an Arabic RTL report PDF with the patient name', () async {
    final bytes = await ReportPdf.build(
      markdown: _md,
      locale: 'ar',
      patientName: 'تسنيم عبدالله',
      nameLabel: 'الاسم',
    );
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    final out = Platform.environment['REPORT_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });

  test('builds an English LTR report PDF', () async {
    final bytes = await ReportPdf.build(
      markdown:
          '# Psychological Report\n\n## 1. Clinical Summary\n\n- **Risk:** low',
      locale: 'en',
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
