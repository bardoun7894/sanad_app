import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';

/// Shared 2026 Bento design tokens and primitives for the Sanad Admin portal.
class AdminBento {
  AdminBento._();

  static const double cardRadius = 18.0;
  static const double controlRadius = 12.0;
  static const double controlHeight = 38.0;

  static Color canvas(bool isDark) =>
      isDark ? AppColors.adminBackground : const Color(0xFFF6F8FB);

  static Color surface(bool isDark) =>
      isDark ? AppColors.adminSurface : Colors.white;

  static Color surfaceMuted(bool isDark) => isDark
      ? AppColors.adminGlass.withValues(alpha: 0.45)
      : const Color(0xFFF4F7FA);

  static Color border(bool isDark) =>
      isDark ? AppColors.adminBorder : const Color(0xFFE6ECF1);

  static Color borderStrong(bool isDark) =>
      isDark ? AppColors.adminBorder : const Color(0xFFDDE5EE);

  static Color textPrimary(bool isDark) =>
      isDark ? Colors.white : AppColors.textPrimary;

  static Color textSecondary(bool isDark) =>
      isDark ? AppColors.adminTextSecondary : AppColors.textSecondary;

  static List<BoxShadow> cardShadow(bool isDark) => isDark
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ];

  static BoxDecoration cardDecoration(
    bool isDark, {
    double radius = cardRadius,
    Color? color,
    Color? borderColor,
    double borderWidth = 1.0,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color ?? surface(isDark),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? border(isDark),
        width: borderWidth,
      ),
      boxShadow: elevated ? cardShadow(isDark) : null,
    );
  }

  /// Scoped ThemeData overrides applied inside [AdminShell] so every admin
  /// page (tables, dialogs, CMS AppBars, inputs, FABs) shares the exact 2026
  /// Bento visual language.
  static ThemeData buildAdminTheme(ThemeData base, bool isDark) {
    final surfaceColor = surface(isDark);
    final borderColor = border(isDark);
    final primaryText = textPrimary(isDark);
    final secondaryText = textSecondary(isDark);

    return base.copyWith(
      scaffoldBackgroundColor: canvas(isDark),
      dividerColor: borderColor,
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryText, size: 21),
        actionsIconTheme: IconThemeData(color: primaryText, size: 21),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: primaryText,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: borderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          isDark
              ? AppColors.adminGlass.withValues(alpha: 0.35)
              : const Color(0xFFF8FAFC),
        ),
        headingTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: secondaryText,
          letterSpacing: 0.2,
        ),
        dataTextStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: primaryText,
        ),
        dividerThickness: 1,
        horizontalMargin: 18,
        columnSpacing: 22,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        headingRowHeight: 46,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: surfaceMuted(isDark),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: borderStrong(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: borderStrong(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Unified 38x38 Bento icon button for the admin top bar.
class AdminHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final int badgeCount;
  final Color? badgeColor;
  final bool isActive;

  const AdminHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badgeCount = 0,
    this.badgeColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = Material(
      color: isActive
          ? AppColors.primary.withValues(alpha: 0.12)
          : AdminBento.surfaceMuted(isDark),
      borderRadius: BorderRadius.circular(AdminBento.controlRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminBento.controlRadius),
        child: Container(
          width: AdminBento.controlHeight,
          height: AdminBento.controlHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminBento.controlRadius),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AdminBento.borderStrong(isDark),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: isActive
                    ? AppColors.primary
                    : AdminBento.textPrimary(isDark),
              ),
              if (badgeCount > 0)
                PositionedDirectional(
                  end: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1.5,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor ?? AppColors.error,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark ? AppColors.adminSurface : Colors.white,
                        width: 1.8,
                      ),
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : badgeCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Crisp 2026 Bento card container for admin content panels.
class AdminBentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AdminBentoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = AdminBento.cardRadius,
    this.color,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final box = Container(
      margin: margin,
      decoration: AdminBento.cardDecoration(
        isDark,
        radius: radius,
        color: color,
        borderColor: borderColor,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(18),
                  child: child,
                ),
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(18),
                child: child,
              ),
      ),
    );
    return box;
  }
}

/// Consistent 2026 Bento command header for admin screens.
class AdminPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final List<Widget> actions;

  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AdminResponsive.isMobile(context);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AdminBento.textPrimary(isDark),
          ),
        ),
        if (subtitleWidget != null) ...[
          const SizedBox(height: 6),
          subtitleWidget!,
        ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13.5,
              color: AdminBento.textSecondary(isDark),
            ),
          ),
        ],
      ],
    );

    final actionWrap = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: actions,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          if (actions.isNotEmpty) ...[const SizedBox(height: 12), actionWrap],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        if (actions.isNotEmpty) ...[const SizedBox(width: 16), actionWrap],
      ],
    );
  }
}

/// Clean 2026 Bento primary or secondary pill/rounded action button.
class AdminBentoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final Color? color;

  const AdminBentoButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = color ?? AppColors.primary;

    return Material(
      color: primary ? accent : AdminBento.surface(isDark),
      borderRadius: BorderRadius.circular(AdminBento.controlRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AdminBento.controlRadius),
        child: Container(
          height: AdminBento.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminBento.controlRadius),
            border: primary
                ? null
                : Border.all(color: AdminBento.borderStrong(isDark)),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: primary ? Colors.white : AdminBento.textPrimary(isDark),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : AdminBento.textPrimary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
