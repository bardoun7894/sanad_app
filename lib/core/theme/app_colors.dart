import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF0066A3);
  static const Color secondary = Color(0xFF0080CC);
  static const Color accent = Color(0xFF004D7A);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF3F6F8);
  static const Color backgroundDark = Color(0xFF111827);

  // Surface Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1F2937);

  // Text Colors
  static const Color textLight = Color(0xFF1E293B);
  static const Color textDark = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textMutedLight = Color(0xFFCBD5E1);

  // Soft Blue
  static const Color softBlue = Color(0xFFEFF6FF);

  // Mood Colors
  static const Color moodHappy = Color(0xFFFEF3C7); // yellow-100
  static const Color moodCalm = Color(0xFFD1FAE5); // green-100
  static const Color moodAnxious = Color(0xFFFCE7F3); // pink-100
  static const Color moodSad = Color(0xFFDBEAFE); // blue-100
  static const Color moodTired = Color(0xFFF3E8FF); // purple-100

  // Gradient Colors (for quote card)
  static const Color gradientStart = Color(0xFF0080CC);
  static const Color gradientEnd = Color(0xFF0066A3);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Border Colors
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFF374151);

  // Navigation Colors
  static const Color navActive = primary;
  static const Color navInactive = Color(0xFF94A3B8);
}
