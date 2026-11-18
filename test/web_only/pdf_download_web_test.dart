@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/utils/pdf_download_web.dart';

void main() {
  test('savePdf triggers a browser download without the printing plugin', () async {
    final bytes = Uint8List.fromList('%PDF-1.4\n%%EOF\n'.codeUnits);
    await savePdf(bytes, 'sanad_report_test.pdf');
  });
}
