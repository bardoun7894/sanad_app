import 'package:flutter/material.dart';
import 'package:sanad_app/core/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool hasGlow;
  final Gradient? gradient;
  final bool useBorder;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.onTap,
    this.hasGlow = false,
    this.gradient,
    this.useBorder = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = isDark ? AppColors.adminSurface : Colors.white;
    final borderColor = isDark
        ? AppColors.adminBorder
        : const Color(0xFFE6ECF1);

    final Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? fallbackColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: useBorder
            ? Border.all(color: borderColor, width: 1.0)
            : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          if (hasGlow)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.12),
              blurRadius: 24,
              spreadRadius: -8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: content),
      );
    }

    return content;
  }
}
