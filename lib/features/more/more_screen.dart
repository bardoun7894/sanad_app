import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
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
            _buildGrid(
              children: [
                _buildCard(
                  context,
                  icon: Icons.people_outline,
                  color: Colors.blue,
                  title: s.navTherapists,
                  onTap: () => context.push(AppRoutes.therapists),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  icon: Icons.assignment_outlined,
                  color: Colors.purple,
                  title: s.psychTests,
                  onTap: () => context.push(AppRoutes.psychologicalTests),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  icon: Icons.call_rounded,
                  color: Colors.teal,
                  title: s.callHistory,
                  onTap: () => context.push(AppRoutes.callHistory),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Content Section
            _buildSectionHeader(context, s.content, isDark),
            _buildGrid(
              children: [
                _buildCard(
                  context,
                  icon: Icons.article_outlined,
                  color: Colors.orange,
                  title: s.blog,
                  onTap: () => context.push(AppRoutes.blog),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  icon: Icons.mic_none_outlined,
                  color: Colors.red,
                  title: s.podcast,
                  onTap: () => context.push(AppRoutes.podcast),
                  isDark: isDark,
                ),
                _buildCard(
                  context,
                  icon: Icons.fitness_center_outlined,
                  color: Colors.green,
                  title: s.exercises,
                  onTap: () => context.push(AppRoutes.exercises),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Subscription Section
            _buildSectionHeader(context, s.subscription, isDark),
            _buildListTile(
              context,
              icon: Icons.star_border_rounded,
              color: Colors.amber,
              title: s.subscriptionPackages,
              subtitle: s.upgradeToPremium,
              onTap: () => context.push(AppRoutes.subscription),
              isDark: isDark,
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
              icon: isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              title: s.themeLabel,
              onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
              isDark: isDark,
              trailing: Switch(
                value: isDark,
                onChanged: (_) =>
                    ref.read(themeProvider.notifier).toggleTheme(),
              ),
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
        return StatefulBuilder(
          builder: (ctx, setState) {
            bool isLoggingOut = false;

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
                            valueColor:
                                AlwaysStoppedAnimation(AppColors.primary),
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
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${s.errorOccurred}: $e'),
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

  Widget _buildGrid({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        // height: 100, // Removed fixed height to prevent overflow
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: isDestructive
                ? Colors.red
                : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
        trailing:
            trailing ??
            Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
