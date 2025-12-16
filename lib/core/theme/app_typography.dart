import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Font Families
  static String get displayFont => GoogleFonts.tajawal().fontFamily!;
  static String get bodyFont => GoogleFonts.inter().fontFamily!;

  // Display Styles (Tajawal - for Arabic & headings)
  static TextStyle displayLarge = GoogleFonts.tajawal(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textLight,
  );

  static TextStyle displayMedium = GoogleFonts.tajawal(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
  );

  static TextStyle displaySmall = GoogleFonts.tajawal(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
  );

  // Heading Styles
  static TextStyle headingLarge = GoogleFonts.tajawal(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
  );

  static TextStyle headingMedium = GoogleFonts.tajawal(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
  );

  static TextStyle headingSmall = GoogleFonts.tajawal(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
  );

  // Body Styles (Inter - for body text)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  // Label Styles
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textLight,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  // Caption Style
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // Button Text Styles
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
