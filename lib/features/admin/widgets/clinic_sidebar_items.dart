import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_bento_ui.dart';

/// Sanad Admin gradient brand emblem used in both expanded and compact sidebar.
class SidebarBrandMark extends StatelessWidget {
  const SidebarBrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: AppColors.adminPrimaryGradient,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.health_and_safety_outlined,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

/// Hairline section divider in compact rail mode or subtle vertical gap when expanded.
class SidebarDivider extends StatelessWidget {
  final bool compact;

  const SidebarDivider({super.key, required this.compact});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Divider(height: 1, color: AdminBento.border(isDark)),
      );
    }
    return const SizedBox(height: 16);
  }
}

/// Uppercase section header label shown only in expanded sidebar mode.
class SidebarCategory extends StatelessWidget {
  final String title;
  final bool compact;

  const SidebarCategory({
    super.key,
    required this.title,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, bottom: 7, top: 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          letterSpacing: 0.65,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.adminTextSecondary.withValues(alpha: 0.72)
              : AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Individual Bento navigation item with active pill highlight, hover tint,
/// optional unread badge, compact tooltip, and automatic mobile drawer close.
class SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool compact;

  /// Badge label to show on the icon (e.g. "3", "9+"). Empty string = hidden.
  final String badgeLabel;

  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.route,
    this.compact = false,
    this.badgeLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isActive =
        location == route ||
        (location.isNotEmpty &&
            route != '/admin/dashboard' &&
            location.startsWith(route));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final item = Container(
      margin: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            context.go(route);
          },
          hoverColor: isActive
              ? Colors.transparent
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 0 : 12,
              vertical: 9.5,
            ),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.24),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      color: isActive
                          ? Colors.white
                          : (isDark
                                ? AppColors.adminTextSecondary
                                : AppColors.textSecondary),
                      size: 19,
                    ),
                    if (badgeLabel.isNotEmpty && compact)
                      PositionedDirectional(
                        top: -6,
                        end: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.statusDanger,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 14,
                          ),
                          child: Text(
                            badgeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : (isDark
                                  ? AppColors.adminTextSecondary
                                  : AppColors.textSecondary),
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (badgeLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.24)
                            : AppColors.statusDanger,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (compact) {
      return Tooltip(message: label, child: item);
    }
    return item;
  }
}
