import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// =============================================================================
// REUSABLE ANIMATION WIDGETS FOR SUBSCRIPTION FEATURE
// =============================================================================
//
// This file provides reusable animation widgets following Material Design
// motion guidelines. All widgets support RTL layouts and customizable
// animation parameters.
//
// Usage Examples:
//
// 1. FadeSlideCard - Entrance animation with fade + slide up
//    FadeSlideCard(
//      child: SubscriptionCard(...),
//      delay: const Duration(milliseconds: 200),
//    )
//
// 2. PressableCard - Card with tap feedback animation
//    PressableCard(
//      onTap: () => selectPlan(plan),
//      child: PlanCard(...),
//    )
//
// 3. AnimatedSelectionIndicator - Smooth checkmark animation
//    AnimatedSelectionIndicator(
//      isSelected: isSelected,
//      color: AppColors.primary,
//    )
//
// 4. StaggeredList - Wrapper for staggered entrance animations
//    StaggeredList(
//      itemCount: plans.length,
//      itemBuilder: (context, index) => PlanCard(...),
//    )
//
// =============================================================================

/// Material Design animation durations
class AnimationDurations {
  AnimationDurations._();

  /// Quick feedback (button presses, toggles)
  static const Duration quick = Duration(milliseconds: 150);

  /// Standard transitions
  static const Duration standard = Duration(milliseconds: 300);

  /// Complex transitions
  static const Duration complex = Duration(milliseconds: 500);

  /// Entrance animations
  static const Duration entrance = Duration(milliseconds: 400);

  /// Stagger delay between items
  static const Duration staggerDelay = Duration(milliseconds: 50);
}

/// Material Design animation curves
class AnimationCurves {
  AnimationCurves._();

  /// Standard curve for most animations
  static const Curve standard = Curves.easeInOut;

  /// Decelerate curve for entrance animations
  static const Curve decelerate = Curves.easeOutCubic;

  /// Accelerate curve for exit animations
  static const Curve accelerate = Curves.easeInCubic;

  /// Spring curve for playful interactions
  static const Curve spring = Curves.elasticOut;

  /// Bounce curve for attention
  static const Curve bounce = Curves.bounceOut;
}

// =============================================================================
// 1. FADE SLIDE CARD - Entrance animation with fade + slide up
// =============================================================================

/// A widget that animates its child with a fade-in and slide-up effect.
///
/// This is ideal for card entrance animations in subscription screens.
/// The animation plays automatically when the widget is first built.
///
/// Example:
/// ```dart
/// FadeSlideCard(
///   child: SubscriptionPlanCard(...),
///   delay: const Duration(milliseconds: 200),
///   duration: const Duration(milliseconds: 500),
/// )
/// ```
class FadeSlideCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double slideOffset;

  const FadeSlideCard({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = AnimationCurves.decelerate,
    this.slideOffset = 30.0,
  });

  @override
  State<FadeSlideCard> createState() => _FadeSlideCardState();
}

class _FadeSlideCardState extends State<FadeSlideCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Start animation after delay
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

// =============================================================================
// 2. PRESSABLE CARD - Card with tap feedback animation
// =============================================================================

/// A card widget that provides visual feedback when pressed.
///
/// The card scales down slightly when pressed and returns to normal
/// when released, providing tactile feedback to the user.
///
/// Example:
/// ```dart
/// PressableCard(
///   onTap: () => Navigator.pushNamed(context, '/plan-details'),
///   child: PlanSummaryCard(...),
///   scaleFactor: 0.96,
/// )
/// ```
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final Curve curve;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.duration = AnimationDurations.quick,
    this.curve = AnimationCurves.standard,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.boxShadow,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              padding: widget.padding,
              decoration: BoxDecoration(
                color:
                    widget.backgroundColor ??
                    (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                border: widget.border,
                boxShadow:
                    widget.boxShadow ??
                    [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// 3. ANIMATED SELECTION INDICATOR - Smooth checkmark animation
// =============================================================================

/// An animated checkmark indicator that smoothly appears/disappears.
///
/// Perfect for showing selection state in subscription plan cards
/// or any multi-select interface.
///
/// Example:
/// ```dart
/// AnimatedSelectionIndicator(
///   isSelected: selectedPlan == plan.id,
///   color: AppColors.primary,
///   size: 28,
/// )
/// ```
class AnimatedSelectionIndicator extends StatefulWidget {
  final bool isSelected;
  final Color color;
  final double size;
  final Duration duration;
  final Curve curve;

  const AnimatedSelectionIndicator({
    super.key,
    required this.isSelected,
    this.color = AppColors.primary,
    this.size = 28.0,
    this.duration = AnimationDurations.standard,
    this.curve = AnimationCurves.spring,
  });

  @override
  State<AnimatedSelectionIndicator> createState() =>
      _AnimatedSelectionIndicatorState();
}

class _AnimatedSelectionIndicatorState extends State<AnimatedSelectionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: widget.curve),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedSelectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.isSelected ? widget.color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSelected ? widget.color : AppColors.border,
              width: 2,
            ),
          ),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _CheckmarkPainter(
                progress: _checkAnimation.value,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for animated checkmark
class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Checkmark coordinates
    final startX = centerX - size.width * 0.25;
    final startY = centerY;
    final midX = centerX - size.width * 0.08;
    final midY = centerY + size.height * 0.15;
    final endX = centerX + size.width * 0.25;
    final endY = centerY - size.height * 0.15;

    // Animate the checkmark drawing
    if (progress < 0.5) {
      // First segment (start to middle)
      final segmentProgress = progress * 2;
      final currentX = startX + (midX - startX) * segmentProgress;
      final currentY = startY + (midY - startY) * segmentProgress;
      path.moveTo(startX, startY);
      path.lineTo(currentX, currentY);
    } else {
      // Complete first segment + second segment
      final segmentProgress = (progress - 0.5) * 2;
      path.moveTo(startX, startY);
      path.lineTo(midX, midY);
      final currentX = midX + (endX - midX) * segmentProgress;
      final currentY = midY + (endY - midY) * segmentProgress;
      path.lineTo(currentX, currentY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =============================================================================
// 4. STAGGERED LIST - Wrapper for staggered entrance animations
// =============================================================================

/// A list widget that animates its children with staggered entrance animations.
///
/// Each item fades and slides in with a slight delay after the previous one,
/// creating a polished, professional appearance.
///
/// Example:
/// ```dart
/// StaggeredList(
///   itemCount: subscriptionPlans.length,
///   itemBuilder: (context, index) => PlanCard(
///     plan: subscriptionPlans[index],
///   ),
///   staggerDelay: const Duration(milliseconds: 100),
/// )
/// ```
class StaggeredList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Curve curve;
  final double slideOffset;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Axis scrollDirection;
  final ScrollController? controller;

  const StaggeredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.staggerDelay = AnimationDurations.staggerDelay,
    this.itemDuration = AnimationDurations.entrance,
    this.curve = AnimationCurves.decelerate,
    this.slideOffset = 30.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding,
      scrollDirection: scrollDirection,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return FadeSlideCard(
          delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
          duration: itemDuration,
          curve: curve,
          slideOffset: slideOffset,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

/// A grid variant of StaggeredList for grid layouts
class StaggeredGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int crossAxisCount;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Curve curve;
  final double slideOffset;
  final EdgeInsetsGeometry? padding;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;

  const StaggeredGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.staggerDelay = AnimationDurations.staggerDelay,
    this.itemDuration = AnimationDurations.entrance,
    this.curve = AnimationCurves.decelerate,
    this.slideOffset = 30.0,
    this.padding,
    this.mainAxisSpacing = 16.0,
    this.crossAxisSpacing = 16.0,
    this.childAspectRatio = 1.0,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return FadeSlideCard(
          delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
          duration: itemDuration,
          curve: curve,
          slideOffset: slideOffset,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

// =============================================================================
// ADDITIONAL UTILITY WIDGETS
// =============================================================================

/// A pulse animation widget for drawing attention to elements.
///
/// Example:
/// ```dart
/// PulseAnimation(
///   child: PremiumBadge(),
///   duration: const Duration(seconds: 2),
/// )
/// ```
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool repeat;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 1.0,
    this.maxScale = 1.05,
    this.repeat = true,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: widget.minScale,
          end: widget.maxScale,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: widget.maxScale,
          end: widget.minScale,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// A shimmer loading effect widget.
///
/// Example:
/// ```dart
/// ShimmerEffect(
///   child: Container(
///     width: 200,
///     height: 100,
///     decoration: BoxDecoration(
///       color: Colors.grey[300],
///       borderRadius: BorderRadius.circular(8),
///     ),
///   ),
/// )
/// ```
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? shimmerColor;
  final bool isLoading;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.shimmerColor,
    this.isLoading = true,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor =
        widget.shimmerColor ??
        (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                shimmerColor.withValues(alpha: 0.0),
                shimmerColor.withValues(alpha: 0.5),
                shimmerColor.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value * 3.14159 / 4),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// A slide-in animation widget for page transitions or reveals.
///
/// Supports all four directions and RTL layouts automatically.
class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double offset;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.direction = SlideDirection.left,
    this.duration = AnimationDurations.standard,
    this.delay = Duration.zero,
    this.curve = AnimationCurves.decelerate,
    this.offset = 50.0,
  });

  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

enum SlideDirection { left, right, up, down }

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Determine slide direction
    Offset beginOffset;
    switch (widget.direction) {
      case SlideDirection.left:
        beginOffset = Offset(-widget.offset / 100, 0);
        break;
      case SlideDirection.right:
        beginOffset = Offset(widget.offset / 100, 0);
        break;
      case SlideDirection.up:
        beginOffset = Offset(0, -widget.offset / 100);
        break;
      case SlideDirection.down:
        beginOffset = Offset(0, widget.offset / 100);
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);

    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Adjust horizontal directions for RTL
    Offset adjustedOffset = _slideAnimation.value;
    if (isRtl &&
        (widget.direction == SlideDirection.left ||
            widget.direction == SlideDirection.right)) {
      adjustedOffset = Offset(-adjustedOffset.dx, adjustedOffset.dy);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: widget.child,
      ),
    );
  }
}

/// A widget that animates the count up of a number.
///
/// Example:
/// ```dart
/// CountUpAnimation(
///   end: 99.99,
///   duration: const Duration(seconds: 2),
///   prefix: '\$',
///   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
/// )
/// ```
class CountUpAnimation extends StatefulWidget {
  final double end;
  final double begin;
  final Duration duration;
  final Curve curve;
  final String? prefix;
  final String? suffix;
  final TextStyle? style;
  final int decimalPlaces;

  const CountUpAnimation({
    super.key,
    required this.end,
    this.begin = 0,
    this.duration = AnimationDurations.complex,
    this.curve = AnimationCurves.decelerate,
    this.prefix,
    this.suffix,
    this.style,
    this.decimalPlaces = 2,
  });

  @override
  State<CountUpAnimation> createState() => _CountUpAnimationState();
}

class _CountUpAnimationState extends State<CountUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _controller.forward();
  }

  @override
  void didUpdateWidget(CountUpAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.end != oldWidget.end) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.end,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value.toStringAsFixed(widget.decimalPlaces);
        return Text(
          '${widget.prefix ?? ''}$value${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}
