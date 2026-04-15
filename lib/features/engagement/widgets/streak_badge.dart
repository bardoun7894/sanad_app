import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/streak_provider.dart';

/// Animated streak badge showing current streak count
class StreakBadge extends ConsumerWidget {
  final double size;
  final bool showLabel;

  const StreakBadge({
    super.key,
    this.size = 40,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakData = ref.watch(streakProvider);
    final streak = streakData.currentStreak;
    final isActive = streakData.isStreakActive;

    if (streak == 0) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StreakIcon(
          streak: streak,
          size: size,
          isActive: isActive,
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            '$streak day${streak > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? const Color(0xFFF97316)
                  : Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}

class _StreakIcon extends StatefulWidget {
  final int streak;
  final double size;
  final bool isActive;

  const _StreakIcon({
    required this.streak,
    required this.size,
    required this.isActive,
  });

  @override
  State<_StreakIcon> createState() => _StreakIconState();
}

class _StreakIconState extends State<_StreakIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StreakIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
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
        return Transform.scale(
          scale: widget.isActive ? _scaleAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.isActive
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFBBF24),
                        Color(0xFFF97316),
                        Color(0xFFEF4444),
                      ],
                    )
                  : null,
              color: widget.isActive ? null : Colors.grey.shade300,
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF97316)
                            .withValues(alpha: 0.3 + (_glowAnimation.value * 0.3)),
                        blurRadius: 8 + (_glowAnimation.value * 8),
                        spreadRadius: 1 + (_glowAnimation.value * 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: widget.size * 0.6,
                  color: widget.isActive ? Colors.white : Colors.grey,
                ),
                Positioned(
                  bottom: widget.size * 0.1,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.size * 0.12,
                      vertical: widget.size * 0.04,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? Colors.white
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(widget.size * 0.15),
                    ),
                    child: Text(
                      '${widget.streak}',
                      style: TextStyle(
                        fontSize: widget.size * 0.25,
                        fontWeight: FontWeight.bold,
                        color: widget.isActive
                            ? const Color(0xFFF97316)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact streak indicator for headers
class StreakIndicator extends ConsumerWidget {
  const StreakIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakData = ref.watch(streakProvider);
    final streak = streakData.currentStreak;

    if (streak == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
