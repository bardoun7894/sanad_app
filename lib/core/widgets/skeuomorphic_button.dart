import 'package:flutter/material.dart';
import 'package:sanad_app/core/theme/app_colors.dart';

class SkeuomorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color baseColor;
  final double height;
  final double? width;

  const SkeuomorphicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.baseColor = AppColors.primary,
    this.height = 50,
    this.width,
  });

  @override
  State<SkeuomorphicButton> createState() => _SkeuomorphicButtonState();
}

class _SkeuomorphicButtonState extends State<SkeuomorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(0, _isPressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isPressed
                ? [
                    _darken(widget.baseColor, 0.1),
                    _darken(widget.baseColor, 0.15),
                  ]
                : [_lighten(widget.baseColor, 0.1), widget.baseColor],
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: _darken(widget.baseColor, 0.4),
                    blurRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 8),
                  ),
                ],
          border: Border.all(color: _lighten(widget.baseColor, 0.2), width: 1),
        ),
        alignment: Alignment.center,
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }

  Color _darken(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color _lighten(Color color, [double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }
}
