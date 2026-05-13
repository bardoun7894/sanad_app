import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===========================================================================
  // STANDARD APP THEME (Light / Mobile)
  // ===========================================================================

  // Primary (Shared)
  static const Color primary = Color(0xFF117A8D);
  static const Color secondary = Color(0xFF1594AC);
  static const Color accent = Color(0xFF0C5A67);

  // Backgrounds (Light Default)
  static const Color background = Color(0xFFF3F6F8);
  static const Color backgroundLight = Color(0xFFF3F6F8);
  static const Color backgroundDark = Color(
    0xFF0B0F19,
  ); // Roobin Dark (Deep Blue/Black)

  // Surfaces
  static const Color surface = Colors.white;
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF151B2B); // Roobin Surface

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLightSecondary = Color(
    0xFF94A3B8,
  ); // Alias to textMuted for consistency
  static const Color textMutedLight = Color(0xFFCBD5E1); // Restored
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Standard Gradients (Restored)
  static const Color gradientStart = Color(0xFF1594AC);
  static const Color gradientEnd = Color(0xFF117A8D);
  static const Color softBlue = Color(0xFFEFF6FF);

  // ===========================================================================
  // ADMIN DASHBOARD THEME ("Roobin Mood" - Dark/Glass)
  // ===========================================================================

  static const Color adminBackground = Color(0xFF0B0F19); // Deep Blue/Black
  static const Color adminSurface = Color(0xFF151B2B);
  static const Color adminGlass = Color(0xFF1F2937);
  static const Color adminTextPrimary = Colors.white;
  static const Color adminTextSecondary = Color(0xFF94A3B8);

  // Admin-specific variants of primary if needed
  static const Color primaryDark = Color(0xFF0C5A67);
  static const Color primaryLight = Color(0xFF3A9DB2);

  static const LinearGradient adminPrimaryGradient = LinearGradient(
    colors: [primary, Color(0xFF0C5A67)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient adminGlassGradient = LinearGradient(
    colors: [Color(0xCC1F2937), Color(0x66111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================================================
  // SHARED UTILITIES
  // ===========================================================================

  // Mood Colors (Standard Pastel for Mobile)
  static const Color moodHappy = Color(0xFFFEF3C7);
  static const Color moodCalm = Color(0xFFD1FAE5);
  static const Color moodAnxious = Color(0xFFFCE7F3);
  static const Color moodSad = Color(0xFFDBEAFE);
  static const Color moodTired = Color(0xFFF3E8FF);
  static const Color moodEnergetic = Color(0xFFFFC107); // Amber
  static const Color moodAngry = Color(0xFFFEE2E2);

  // Mood Icon Colors (darker variants for icon foregrounds)
  static const Color moodHappyIcon = Color(0xFFD97706);
  static const Color moodCalmIcon = Color(0xFF059669);
  static const Color moodAnxiousIcon = Color(0xFFDB2777);
  static const Color moodSadIcon = Color(0xFF2563EB);
  static const Color moodAngryIcon = Color(0xFFDC2626);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Status Colors (Enhanced for Admin Dashboard)
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusDanger = Color(0xFFEF4444);
  static const Color statusInfo = Color(0xFF3B82F6);
  static const Color statusPending = Color(0xFF8B5CF6);

  // Risk Level Colors (For Patient Risk Assessment)
  static const Color riskLow = Color(0xFF10B981);
  static const Color riskModerate = Color(0xFFF59E0B);
  static const Color riskHigh = Color(0xFFF97316);
  static const Color riskCritical = Color(0xFFEF4444);

  // Admin Card Colors
  static const Color adminCard = Color(0xFF242B35);
  static const Color adminBorder = Color(0xFF2E3744);

  // Borders
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFF374151);

  // Navigation
  static const Color navBarBackground = Colors.white;
  static const Color navBarSelected = primary;
  static const Color navBarUnselected = Color(0xFF94A3B8);
  static const Color navActive = navBarSelected;
  static const Color navInactive = navBarUnselected;

  // Explicitly defined simply to avoid access errors if they were used in the Admin redesign
  // Ideally, admin code should switch to `adminGlass`, but for quick fix:
  static const Color surfaceGlass = adminGlass;

  // Re-adding missing colors for Admin Dashboard
  static const Color surfaceCurve = Color(0xFF1E293B);
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color darkOutline = Color(0xFF334155);
  static const Color lightOutline = Color(0xFFE2E8F0);
  static const Color darkBackground = adminBackground;
  static const Color lightBackground = background;
}
