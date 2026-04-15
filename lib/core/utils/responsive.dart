import 'package:flutter/widgets.dart';

/// Centralized responsive breakpoints and helpers for the admin dashboard.
///
/// Breakpoints:
/// - Mobile:  < 768px
/// - Tablet:  768px – 1023px
/// - Desktop: >= 1024px
/// - Compact: < 600px  (small phones)
class AdminResponsive {
  AdminResponsive._();

  // ── Breakpoints ──────────────────────────────────────────────
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double compactBreakpoint = 600;

  // ── Queries ──────────────────────────────────────────────────
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      width(context) < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      width(context) >= mobileBreakpoint && width(context) < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      width(context) >= tabletBreakpoint;

  static bool isCompact(BuildContext context) =>
      width(context) < compactBreakpoint;

  // ── Adaptive Values ──────────────────────────────────────────
  /// Returns [mobile] / [tablet] / [desktop] depending on screen width.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }

  /// Responsive padding that adapts to screen size.
  static EdgeInsets pagePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20);
    }
    return const EdgeInsets.all(24);
  }

  /// Header horizontal padding.
  static double headerPadding(BuildContext context) {
    if (isMobile(context)) return 12;
    return 24;
  }
}
