import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

class SanadCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const SanadCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.border,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null
            ? (backgroundColor ??
                (isDark ? AppColors.surfaceDark : AppColors.surfaceLight))
            : null,
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusXl),
        boxShadow: boxShadow ?? AppShadows.soft,
        border: border ??
            Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingLg),
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

// Gradient Card variant for quote card
class SanadGradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Gradient gradient;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const SanadGradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusXl),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
            ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacing2xl),
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
