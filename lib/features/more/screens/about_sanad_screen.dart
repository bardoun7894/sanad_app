import 'package:flutter/material.dart';
import '../../../core/l10n/language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutSanadScreen extends ConsumerWidget {
  const AboutSanadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.aboutSanad)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Text(
          '(Draft)\n\nسيتم إضافة تفاصيل "تعرف على سند" هنا لاحقاً.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
