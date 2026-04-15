import 'package:flutter/material.dart';

/// Stub implementation for web - returns fallback widget
Widget buildFileImageWidget(
  String filePath, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  // On web, file images are not supported
  return SizedBox(
    width: width,
    height: height,
    child: const Icon(Icons.person, size: 40),
  );
}
