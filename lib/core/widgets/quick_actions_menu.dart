import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class QuickActionsMenu extends StatefulWidget {
  final List<QuickAction> actions;
  final VoidCallback onClose;

  const QuickActionsMenu({
    super.key,
    required this.actions,
    required this.onClose,
  });

  @override
  State<QuickActionsMenu> createState() => _QuickActionsMenuState();
}

class _QuickActionsMenuState extends State<QuickActionsMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Staggered animations for each item
    _itemAnimations = List.generate(widget.actions.length, (index) {
      final start = index * 0.1;
      final end = start + 0.6;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: _fadeAnimation.value * 0.5),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _close,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Action items
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: widget.actions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final action = entry.value;

                      return AnimatedBuilder(
                        animation: _itemAnimations[index],
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              20 * (1 - _itemAnimations[index].value),
                            ),
                            child: Opacity(
                              opacity: _itemAnimations[index].value.clamp(
                                0.0,
                                1.0,
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ActionItem(
                            action: action,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _close();
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () {
                                  action.onTap();
                                },
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Close button
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _close();
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 28,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final QuickAction action;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionItem({
    required this.action,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                action.label,
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper to show the menu as an overlay
void showQuickActionsMenu(BuildContext context, List<QuickAction> actions) {
  HapticFeedback.mediumImpact();

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => QuickActionsMenu(
      actions: actions,
      onClose: () {
        overlayEntry.remove();
      },
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}
