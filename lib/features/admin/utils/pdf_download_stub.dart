import 'dart:typed_data';

import 'package:printing/printing.dart';

/// Mobile/desktop: hand the PDF to the system share sheet.
Future<void> savePdf(Uint8List bytes, String filename) =>
    Printing.sharePdf(bytes: bytes, filename: filename);
