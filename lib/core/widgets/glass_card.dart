import 'dart:ui';
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
    final fallbackColor = isDark
        ? AppColors.surfaceGlass.withOpacity(0.6)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : AppColors.borderLight;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : Colors.black.withOpacity(0.06);
    final shadowBlur = isDark ? 20.0 : 12.0;

    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color ?? fallbackColor,
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              border: useBorder
                  ? Border.all(color: borderColor, width: 1.0)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: shadowBlur,
                  offset: Offset(0, isDark ? 10 : 4),
                ),
                if (hasGlow)
                  BoxShadow(
                    color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.12),
                    blurRadius: 30,
                    spreadRadius: -10,
                    offset: const Offset(0, 0),
                  ),
              ],
            ),
            child: child,
          ),
        ),
      ),
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
