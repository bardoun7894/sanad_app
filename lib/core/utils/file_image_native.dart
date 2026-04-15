import 'dart:io';
import 'package:flutter/material.dart';

/// Native implementation - uses dart:io File
Widget buildFileImageWidget(
  String filePath, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return Image.file(
    File(filePath),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}
