import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sanad_button.dart';
import '../../core/widgets/quick_actions_settings.dart';
import '../../core/l10n/language_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../subscription/providers/subscription_provider.dart';
import '../subscription/widgets/premium_badge.dart';
import 'providers/profile_provider.dart';
import 'widgets/profile_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileSheet(BuildContext context, WidgetRef ref) {
    final state = ref.read(profileProvider);
    if (state.user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(
        user: state.user!,
        onSave: (name, email, phone) {
          ref
              .read(profileProvider.notifier)
              .updateProfile(name: name, email: email, phone: phone);
        },
      ),
    );
  }

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
                      color: isDark ? Colors.white : AppColors.textLight,
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
                        color: isDark ? Colors.white : AppColors.textLight,
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
                        color: isDark ? Colors.white : AppColors.textLight,
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
            color: isDark ? Colors.white : AppColors.textLight,
          ),
        ),
        content: Text(
          s.logOutConfirm,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textDark : AppColors.textLight,
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
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
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
    final state = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    if (state.user == null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = state.user!;
    final settings = user.settings;
    final stats = state.stats;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              Text(
                s.profile,
                style: AppTypography.headingLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 24),

              // Profile header card
              ProfileHeader(
                name: user.name,
                email: user.email,
                avatarUrl: user.avatarUrl,
                onEditProfile: () => _showEditProfileSheet(context, ref),
              ),
              const SizedBox(height: 12),
              // Premium badge
              if (ref.watch(isPremiumProvider)) ...{
                PremiumBadgeWithDetails(),
                const SizedBox(height: 12),
              },
              const SizedBox(height: 12),

              // Stats card
              StatsCard(
                sessions: stats.totalSessions,
                moodEntries: stats.moodEntriesCount,
                streakDays: stats.streakDays,
                communityPosts: stats.communityPosts,
              ),
              const SizedBox(height: 24),

              // Notifications section
              SettingsSection(
                title: s.notifications,
                children: [
                  SettingsToggleItem(
                    icon: Icons.notifications_outlined,
                    title: s.pushNotifications,
                    subtitle: s.receiveAlerts,
                    value: settings.notificationsEnabled,
                    onChanged: (value) {
                      ref
                          .read(profileProvider.notifier)
                          .toggleNotifications(value);
                    },
                  ),
                  SettingsToggleItem(
                    icon: Icons.wb_sunny_outlined,
                    iconColor: AppColors.moodHappy,
                    title: s.dailyReminders,
                    subtitle: s.morningCheckins,
                    value: settings.dailyReminders,
                    onChanged: (value) {
                      ref
                          .read(profileProvider.notifier)
                          .toggleDailyReminders(value);
                    },
                  ),
                  SettingsToggleItem(
                    icon: Icons.emoji_emotions_outlined,
                    iconColor: AppColors.moodCalm,
                    title: s.moodReminders,
                    subtitle: s.dailyMoodPrompts,
                    value: settings.moodTrackingReminders,
                    onChanged: (value) {
                      ref
                          .read(profileProvider.notifier)
                          .toggleMoodReminders(value);
                    },
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Preferences section
              SettingsSection(
                title: s.preferences,
                children: [
                  SettingsMenuItem(
                    icon: Icons.card_giftcard_outlined,
                    iconColor: AppColors.primary,
                    title: s.subscription,
                    subtitle: ref.watch(subscriptionStatusProvider).state.name,
                    onTap: () => context.push('/subscription'),
                  ),
                  SettingsMenuItem(
                    icon: Icons.dashboard_customize_rounded,
                    iconColor: AppColors.moodHappy,
                    title: s.quickActions,
                    subtitle: s.customizePlusButton,
                    onTap: () => showQuickActionsSettings(context),
                  ),
                  SettingsToggleItem(
                    icon: Icons.dark_mode_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    title: s.darkMode,
                    subtitle: s.switchDarkTheme,
                    value: settings.darkMode,
                    onChanged: (value) {
                      ref.read(profileProvider.notifier).toggleDarkMode(value);
                    },
                  ),
                  SettingsMenuItem(
                    icon: Icons.language_rounded,
                    iconColor: AppColors.primary,
                    title: s.languageLabel,
                    trailing: ref.watch(languageProvider).displayName,
                    onTap: () => _showLanguageSelector(context, ref),
                  ),
                  SettingsToggleItem(
                    icon: Icons.visibility_off_outlined,
                    iconColor: AppColors.textMuted,
                    title: s.anonymousInCommunity,
                    subtitle: s.hideNameInPosts,
                    value: settings.anonymousInCommunity,
                    onChanged: (value) {
                      ref.read(profileProvider.notifier).toggleAnonymous(value);
                    },
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Support section
              SettingsSection(
                title: s.support,
                children: [
                  SettingsMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: s.helpCenter,
                    subtitle: s.faqsAndArticles,
                    onTap: () {
                      // TODO: Navigate to help center
                    },
                  ),
                  SettingsMenuItem(
                    icon: Icons.chat_outlined,
                    iconColor: AppColors.moodCalm,
                    title: s.contactSupport,
                    subtitle: s.getHelpFromTeam,
                    onTap: () {
                      // TODO: Open support chat
                    },
                  ),
                  SettingsMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppColors.moodAnxious,
                    title: s.privacyPolicy,
                    onTap: () {
                      // TODO: Show privacy policy
                    },
                  ),
                  SettingsMenuItem(
                    icon: Icons.description_outlined,
                    title: s.termsOfService,
                    onTap: () {
                      // TODO: Show terms
                    },
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Account section
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
              const SizedBox(height: 32),

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

class _EditProfileSheet extends StatefulWidget {
  final dynamic user;
  final Function(String name, String email, String? phone) onSave;

  const _EditProfileSheet({required this.user, required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer(
      builder: (context, ref, _) {
        final s = ref.watch(stringsProvider);

        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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

                // Header
                Text(
                  s.editProfile,
                  style: AppTypography.headingMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Name field
                _InputField(
                  label: s.fullName,
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Email field
                _InputField(
                  label: s.email,
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Phone field
                _InputField(
                  label: s.phoneNumber,
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),

                // Save button
                SanadButton(
                  text: s.saveChanges,
                  icon: Icons.check_rounded,
                  onPressed: () {
                    widget.onSave(
                      _nameController.text,
                      _emailController.text,
                      _phoneController.text.isNotEmpty
                          ? _phoneController.text
                          : null,
                    );
                    Navigator.pop(context);
                  },
                  isFullWidth: true,
                  size: SanadButtonSize.large,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool isDark;

  const _InputField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
