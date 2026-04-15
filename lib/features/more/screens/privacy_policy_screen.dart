import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'سياسة الخصوصية\n\n(Draft)\n\nسيتم إضافة تفاصيل سياسة الخصوصية هنا لاحقاً.',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
