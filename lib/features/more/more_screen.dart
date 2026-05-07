import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../routes/app_routes.dart';
import '../../features/auth/providers/auth_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          s.navMore, // "More"
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Services Section
            _buildSectionHeader(context, s.services, isDark),
            _buildIconGrid(
              children: [
                _MoreIconButton(
                  assetPath: 'assets/icons/more/therapists.png',
                  title: s.navTherapists,
                  onTap: () => context.push(AppRoutes.therapists),
                  isDark: isDark,
                ),
                _MoreIconButton(
                  assetPath: 'assets/icons/more/psych_tests.png',
                  title: s.psychTests,
                  onTap: () => context.push(AppRoutes.psychologicalTests),
                  isDark: isDark,
                ),
                _MoreIconButton(
                  assetPath: 'assets/icons/more/call_history.png',
                  title: s.callHistory,
                  onTap: () => context.push(AppRoutes.callHistory),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Content Section
            _buildSectionHeader(context, s.content, isDark),
            _buildIconGrid(
              children: [
                _MoreIconButton(
                  assetPath: 'assets/icons/more/blog.png',
                  title: s.blog,
                  onTap: () => context.push(AppRoutes.blog),
                  isDark: isDark,
                ),
                _MoreIconButton(
                  assetPath: 'assets/icons/more/podcast.png',
                  title: s.podcast,
                  onTap: () => context.push(AppRoutes.sanadPodcast),
                  isDark: isDark,
                ),
                _MoreIconButton(
                  assetPath: 'assets/icons/more/exercises.png',
                  title: s.exercises,
                  onTap: () => context.push(AppRoutes.exercises),
                  isDark: isDark,
                ),
                _MoreIconButton(
                  assetPath: 'assets/icons/more/sanad_tube.png',
                  title: 'سند تيوب',
                  onTap: () => context.push(AppRoutes.sanadTube),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Subscription Section
            _buildSectionHeader(context, s.subscription, isDark),
            _buildIconGrid(
              children: [
                _MoreIconButton(
                  assetPath: 'assets/icons/more/subscription.png',
                  title: s.subscriptionPackages,
                  onTap: () => context.push(AppRoutes.subscription),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // App Settings Section
            _buildSectionHeader(context, s.appSettings, isDark),
            _buildSettingsItem(
              context,
              icon: Icons.person_outline_rounded,
              title: s.navProfile,
              onTap: () => context.push(AppRoutes.profile),
              isDark: isDark,
            ),
            _buildSettingsItem(
              context,
              icon: Icons.language_rounded,
              title: s.languageLabel,
              onTap: () => ref.read(languageProvider.notifier).toggleLanguage(),
              isDark: isDark,
            ),
            _buildSettingsItem(
              context,
              icon: Icons.info_outline_rounded,
              title: s.aboutSanad,
              onTap: () => context.push(AppRoutes.aboutSanad),
              isDark: isDark,
            ),
            _buildSettingsItem(
              context,
              icon: Icons.privacy_tip_outlined,
              title: s.privacyPolicy,
              onTap: () => context.push(AppRoutes.privacyPolicy),
              isDark: isDark,
            ),
            _buildSettingsItem(
              context,
              icon: Icons.description_outlined,
              title: s.termsOfService,
              onTap: () => context.push(AppRoutes.termsOfService),
              isDark: isDark,
            ),
            _buildSettingsItem(
              context,
              icon: Icons.gavel_outlined,
              title: s.knowYourRights,
              onTap: () => context.push(AppRoutes.knowYourRights),
              isDark: isDark,
            ),
            _buildSettingsItem(
              context,
              icon: Icons.help_outline_rounded,
              title: s.faqs,
              onTap: () => context.push(AppRoutes.faqs),
              isDark: isDark,
            ),
            _buildSettingsItem(
              context,
              icon: Icons.insights_rounded,
              title: s.myInsights,
              onTap: () => context.push(AppRoutes.insights),
              isDark: isDark,
            ),
            _buildSettingsItem(
              context,
              icon: Icons.logout_rounded,
              title: s.logOut,
              onTap: () => _confirmLogout(context, ref),
              isDark: isDark,
              isDestructive: true,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '${s.appName} v1.0.0',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.read(stringsProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isLoggingOut = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                s.logOut,
                style: AppTypography.headingSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              content: isLoggingOut
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            s.loggingOut,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      s.logOutConfirm,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
              actions: isLoggingOut
                  ? null
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          s.cancel,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          setState(() => isLoggingOut = true);
                          try {
                            await ref.read(signOutAndCleanupProvider)();
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              context.go(AppRoutes.login);
                            }
                          } catch (e, st) {
                            debugPrint('Sign-out failed: $e\n$st');
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(s.errorOccurred),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          s.logOut,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTypography.headingSmall.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildIconGrid({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const int columns = 3;
        const double spacing = 12;
        final double itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.textSecondary,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: isDestructive
                ? AppColors.error
                : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
        trailing:
            trailing ??
            Icon(
              isRtl ? Icons.chevron_left : Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary,
            ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MoreIconButton — minimal icon + label, no card chrome
// ---------------------------------------------------------------------------

class _MoreIconButton extends StatefulWidget {
  const _MoreIconButton({
    this.icon,
    this.assetPath,
    required this.title,
    required this.onTap,
    required this.isDark,
  }) : assert(
         icon != null || assetPath != null,
         '_MoreIconButton requires either icon or assetPath',
       );

  final IconData? icon;
  final String? assetPath;
  final String title;
  final VoidCallback onTap;
  final bool isDark;

  @override
  State<_MoreIconButton> createState() => _MoreIconButtonState();
}

class _MoreIconButtonState extends State<_MoreIconButton> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) => setState(() => _pressed = false);
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final Color labelColor = widget.isDark
        ? Colors.white
        : AppColors.textPrimary;

    return Semantics(
      button: true,
      label: widget.title,
      child: AnimatedScale(
        scale: (_pressed && !reduceMotion) ? 0.92 : 1.0,
        duration: Duration(milliseconds: reduceMotion ? 0 : 120),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: widget.assetPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            widget.assetPath!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Icon(widget.icon, color: AppColors.primary, size: 67),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
