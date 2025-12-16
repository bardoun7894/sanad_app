import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  // Soft shadow for cards
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      offset: const Offset(0, 4),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];

  // Navigation bar shadow
  static List<BoxShadow> nav = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      offset: const Offset(0, -4),
      blurRadius: 20,
    ),
  ];

  // Glow effect for primary elements
  static List<BoxShadow> glow = [
    BoxShadow(
      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
      offset: Offset.zero,
      blurRadius: 15,
    ),
  ];

  // Button shadow
  static List<BoxShadow> button = [
    BoxShadow(
      color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  // Elevated shadow
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      offset: const Offset(0, 8),
      blurRadius: 30,
    ),
  ];

  // No shadow
  static List<BoxShadow> none = [];
}
