import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

enum SanadButtonSize { small, medium, large }

enum SanadButtonVariant { primary, secondary, outline, ghost }

class SanadButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final SanadButtonSize size;
  final SanadButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;

  const SanadButton({
    super.key,
    required this.text,
    this.onPressed,
    this.size = SanadButtonSize.medium,
    this.variant = SanadButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<SanadButton> createState() => _SanadButtonState();
}

class _SanadButtonState extends State<SanadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case SanadButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case SanadButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
      case SanadButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 18);
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case SanadButtonSize.small:
        return AppTypography.buttonSmall;
      case SanadButtonSize.medium:
        return AppTypography.buttonMedium;
      case SanadButtonSize.large:
        return AppTypography.buttonLarge;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case SanadButtonSize.small:
        return 16;
      case SanadButtonSize.medium:
        return 20;
      case SanadButtonSize.large:
        return 24;
    }
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) return widget.backgroundColor!;

    switch (widget.variant) {
      case SanadButtonVariant.primary:
        return AppColors.primary;
      case SanadButtonVariant.secondary:
        return AppColors.softBlue;
      case SanadButtonVariant.outline:
      case SanadButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (widget.textColor != null) return widget.textColor!;

    switch (widget.variant) {
      case SanadButtonVariant.primary:
        return Colors.white;
      case SanadButtonVariant.secondary:
      case SanadButtonVariant.outline:
      case SanadButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  Border? _getBorder() {
    switch (widget.variant) {
      case SanadButtonVariant.outline:
        return Border.all(color: AppColors.primary, width: 2);
      default:
        return null;
    }
  }

  List<BoxShadow>? _getBoxShadow() {
    switch (widget.variant) {
      case SanadButtonVariant.primary:
        return AppShadows.button;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null ? (_) => _controller.reverse() : null,
      onTapCancel:
          widget.onPressed != null ? () => _controller.reverse() : null,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          padding: _getPadding(),
          decoration: BoxDecoration(
            color: widget.onPressed == null
                ? _getBackgroundColor().withValues(alpha: 0.5)
                : _getBackgroundColor(),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: _getBorder(),
            boxShadow: widget.onPressed != null ? _getBoxShadow() : null,
          ),
          child: Row(
            mainAxisSize:
                widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: _getIconSize(),
                  height: _getIconSize(),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: _getIconSize(),
                    color: _getTextColor(),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: _getTextStyle().copyWith(color: _getTextColor()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Icon-only button variant
class SanadIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const SanadIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: AppShadows.soft,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor ??
              (isDark ? AppColors.textMuted : AppColors.textSecondary),
        ),
      ),
    );
  }
}
