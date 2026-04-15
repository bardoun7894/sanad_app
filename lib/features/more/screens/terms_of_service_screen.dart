import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شروط الخدمة')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'شروط الخدمة\n\n(Draft)\n\nسيتم إضافة تفاصيل شروط الخدمة هنا لاحقاً.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
