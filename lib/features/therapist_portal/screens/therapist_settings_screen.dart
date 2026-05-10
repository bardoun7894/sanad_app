import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/widgets/profile_widgets.dart'; // Reuse user profile widgets
import '../providers/therapist_dashboard_provider.dart';

class TherapistSettingsScreen extends ConsumerWidget {
  const TherapistSettingsScreen({super.key});

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final langState = ref.watch(languageProvider);
          final strings = ref.watch(stringsProvider);
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.selectLanguage,
                    style: AppTypography.headingMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Arabic option
                  ListTile(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(languageProvider.notifier)
                          .setLanguage(AppLanguage.arabic);
                      Navigator.pop(context);
                    },
                    leading: Icon(
                      Icons.language_rounded,
                      color: langState.language == AppLanguage.arabic
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    title: Text(
                      'العربية',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    trailing: langState.language == AppLanguage.arabic
                        ? Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                  ),
                  // English option
                  ListTile(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(languageProvider.notifier)
                          .setLanguage(AppLanguage.english);
                      Navigator.pop(context);
                    },
                    leading: Icon(
                      Icons.language_rounded,
                      color: langState.language == AppLanguage.english
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    title: Text(
                      'English',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    trailing: langState.language == AppLanguage.english
                        ? Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.read(stringsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          s.logOut,
          style: AppTypography.headingSmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          s.logOutConfirm,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              s.cancel,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(signOutAndCleanupProvider)();
            },
            child: Text(
              s.logOut,
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(therapistDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final profile = dashboardState.profile;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.profile),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTypography.headingLarge.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Profile header card
              if (profile != null)
                ProfileHeader(
                  name: profile.name,
                  email:
                      profile.title ??
                      '', // Using title as subtitle since email isn't in profile model directly usually
                  avatarUrl: profile.photoUrl ?? '',
                  onEditProfile: () =>
                      context.push(AppRoutes.therapistProfileEdit),
                )
              else
                const Center(child: CircularProgressIndicator()),

              const SizedBox(height: 24),

              // Account section
              SettingsSection(
                title: s.account,
                children: [
                  SettingsMenuItem(
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.primary,
                    title: s
                        .editProfile, // Reuse localized string or 'Personal Information'
                    subtitle: s.basicInformation,
                    onTap: () => context.push(AppRoutes.therapistProfileEdit),
                  ),
                  SettingsMenuItem(
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.secondary,
                    title: s.availability,
                    onTap: () => context.push(AppRoutes.therapistAvailability),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Preferences section
              SettingsSection(
                title: s.preferences,
                children: [
                  SettingsMenuItem(
                    // We don't have a toggle provider for this screen easily accessible without duplicating logic, simplified for now
                    icon: Icons.language_rounded,
                    iconColor: AppColors.primary,
                    title: s.languageLabel,
                    trailing: ref.watch(languageProvider).displayName,
                    onTap: () => _showLanguageSelector(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // About + legal section — same in-app static pages the user
              // role uses, so therapist sees identical content.
              SettingsSection(
                title: s.support,
                children: [
                  SettingsMenuItem(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.primary,
                    title: s.aboutSanad,
                    onTap: () => context.push(AppRoutes.aboutSanad),
                  ),
                  SettingsMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppColors.moodAnxious,
                    title: s.privacyPolicy,
                    onTap: () => context.push(AppRoutes.privacyPolicy),
                  ),
                  SettingsMenuItem(
                    icon: Icons.description_outlined,
                    title: s.termsOfService,
                    onTap: () => context.push(AppRoutes.termsOfService),
                  ),
                  SettingsMenuItem(
                    icon: Icons.gavel_outlined,
                    title: s.knowYourRights,
                    onTap: () => context.push(AppRoutes.knowYourRights),
                  ),
                  SettingsMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: s.faqs,
                    onTap: () => context.push(AppRoutes.faqs),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Account Actions
              SettingsSection(
                title: s.account,
                children: [
                  SettingsMenuItem(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    title: s.logOut,
                    onTap: () => _showLogoutConfirmation(context, ref),
                    isDestructive: true,
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // App version
              Center(
                child: Text(
                  '${s.appName} v1.0.0',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
