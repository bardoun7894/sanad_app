import 'package:flutter/material.dart';
import '../../core/utils/file_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sanad_button.dart';
import '../../core/widgets/quick_actions_settings.dart';
import '../../core/l10n/language_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../subscription/models/subscription_status.dart';
import '../subscription/providers/subscription_provider.dart';
import '../subscription/widgets/premium_badge.dart';
import 'providers/profile_provider.dart';
import '../../core/providers/system_settings_provider.dart';
import 'widgets/profile_widgets.dart';
import '../home/widgets/profile_progress_card.dart';
import '../therapist_chat/providers/therapist_chat_access_provider.dart';

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
        onSave: (name, email, phone, avatarUrl) {
          ref
              .read(profileProvider.notifier)
              .updateProfile(
                name: name,
                email: email,
                phone: phone,
                avatarUrl: avatarUrl,
              );
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

  void _showHelpCenter(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.read(stringsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.helpCenter,
                      style: AppTypography.headingSmall.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // FAQ List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildFaqItem(context, isDark, s.faqBookSessionQ, s.faqBookSessionA),
                    _buildFaqItem(context, isDark, s.faqPrivacyQ, s.faqPrivacyA),
                    _buildFaqItem(context, isDark, s.faqAiChatQ, s.faqAiChatA),
                    _buildFaqItem(context, isDark, s.faqSubscriptionPlansQ, s.faqSubscriptionPlansA),
                    _buildFaqItem(context, isDark, s.faqCancelSubscriptionQ, s.faqCancelSubscriptionA),
                    _buildFaqItem(context, isDark, s.faqBecomeTherapistQ, s.faqBecomeTherapistA),
                    _buildFaqItem(context, isDark, s.faqCrisisQ, s.faqCrisisA),
                    const SizedBox(height: 20),
                    // Contact support button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/chat/support');
                        },
                        icon: const Icon(Icons.chat_outlined),
                        label: Text(s.contactSupport),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context,
    bool isDark,
    String question,
    String answer,
  ) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        question,
        style: AppTypography.labelLarge.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      iconColor: AppColors.primary,
      collapsedIconColor: isDark ? Colors.white54 : Colors.black54,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            answer,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openComplaintsWhatsApp(BuildContext context, S s) async {
    // Phone number stored in international format without the leading '+' or
    // '00' for the wa.me deep link.
    const number = '971554503909';
    final uri = Uri.parse('https://wa.me/$number');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.whatsappLaunchError)),
      );
    }
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
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
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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
                            // Router will auto-redirect to login via
                            // AuthRefreshListenable when state becomes
                            // unauthenticated. As a safeguard, explicitly
                            // navigate to login.
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
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingXl,
            0,
            AppTheme.spacingXl,
            AppTheme.spacingXl,
          ), // Remove top padding to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title
              Text(
                s.profile,
                style: AppTypography.headingLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Profile header card
              ProfileHeader(
                name: user.name,
                email: user.email,
                avatarUrl: user.avatarUrl,
                subscriptionStatus: ref.watch(subscriptionStatusProvider),
                onEditProfile: () => _showEditProfileSheet(context, ref),
              ),
              const SizedBox(height: 12),

              if (ref.read(currentUserProvider) != null &&
                  !ref.read(currentUserProvider)!.isGuest) ...[
                ProfileProgressCard(
                  progress: ref
                      .read(currentUserProvider)!
                      .profileCompletionPercentage,
                  showWhenComplete: false, // Don't show if 100% complete
                  margin: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
              ],
              // Premium badge
              if (ref.watch(isPremiumProvider)) ...{
                PremiumBadgeWithDetails(),
                const SizedBox(height: 12),
              },
              const SizedBox(height: 12),

              // "Your therapist" card — visible only when admin or paid
              // booking has assigned one. Tapping → chat. Reads
              // assignedTherapistId from the auth user (UserProfile here
              // is settings/preferences, not the canonical role state).
              Builder(builder: (ctx) {
                final authUser = ref.watch(currentUserProvider);
                final tid = authUser?.assignedTherapistId ?? '';
                if (tid.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AssignedTherapistCard(
                    therapistId: tid,
                    cachedName: authUser?.assignedTherapistName ?? '',
                    userId: authUser!.uid,
                    isDark: isDark,
                  ),
                );
              }),

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
                    iconColor: AppColors.moodHappyIcon,
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
                    iconColor: AppColors.moodCalmIcon,
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
                    icon: ref.watch(isPremiumProvider)
                        ? Icons.stars_rounded
                        : Icons.card_giftcard_outlined,
                    iconColor: ref.watch(isPremiumProvider)
                        ? const Color(0xFFFFD700)
                        : AppColors.primary,
                    title: ref.watch(isPremiumProvider)
                        ? s.premiumPlan
                        : s.subscription,
                    subtitle: _localizedStatus(
                      ref.watch(subscriptionStatusProvider).state,
                      s,
                    ),
                    onTap: () => context.push('/subscription'),
                  ),
                  SettingsMenuItem(
                    icon: Icons.history_rounded,
                    iconColor: AppColors.primary,
                    title: s.subscriptionHistory,
                    subtitle: s.viewPastPayments,
                    onTap: () => context.push('/subscription-history'),
                  ),
                  SettingsMenuItem(
                    icon: Icons.dashboard_customize_rounded,
                    iconColor: AppColors.moodHappyIcon,
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
                    onTap: () => _showHelpCenter(context, ref),
                  ),
                  SettingsMenuItem(
                    icon: Icons.chat_outlined,
                    iconColor: AppColors.moodCalmIcon,
                    title: s.complaintsAndSuggestions,
                    subtitle: s.shareYourFeedbackOnWhatsApp,
                    onTap: () => _openComplaintsWhatsApp(context, s),
                  ),
                  SettingsMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppColors.moodAnxiousIcon,
                    title: s.privacyPolicy,
                    onTap: () => context.push('/privacy-policy'),
                  ),
                  SettingsMenuItem(
                    icon: Icons.description_outlined,
                    title: s.termsOfService,
                    onTap: () => context.push('/terms-of-service'),
                  ),
                  SettingsMenuItem(
                    icon: Icons.gavel_outlined,
                    title: s.knowYourRights,
                    onTap: () => context.push('/know-your-rights'),
                  ),
                  SettingsMenuItem(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.primary,
                    title: s.aboutSanad,
                    onTap: () => context.push('/about-sanad'),
                  ),
                  // Conditionally show "Become a Therapist"
                  Consumer(
                    builder: (context, ref, child) {
                      final settingsAsync = ref.watch(systemSettingsProvider);
                      final isTherapist = ref.watch(isTherapistProvider);

                      return settingsAsync.maybeWhen(
                        data: (settings) {
                          // Hide if disabled via config OR user is already a therapist
                          if (!settings.enableTherapistApplication ||
                              isTherapist) {
                            return const SizedBox.shrink();
                          }
                          return SettingsMenuItem(
                            icon: Icons.psychology_outlined,
                            iconColor: AppColors.primary,
                            title: s.becomeTherapist,
                            subtitle: s.becomeTherapistDesc,
                            onTap: () => context.push('/therapist/register'),
                            showDivider: false,
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
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

              // Therapist Dashboard (Only for Approved Therapists)
              if (ref.watch(isApprovedTherapistProvider))
                SettingsSection(
                  title: 'Therapist',
                  children: [
                    SettingsMenuItem(
                      icon: Icons.medical_services_outlined,
                      iconColor: AppColors.primary,
                      title: 'Therapist Dashboard',
                      subtitle: 'Manage appointments and patients',
                      onTap: () => context.push(AppRoutes.therapistDashboard),
                      showDivider: false,
                    ),
                  ],
                ),
              if (ref.watch(isApprovedTherapistProvider))
                const SizedBox(height: 24),

              // Admin Access (Admins Only)
              if (ref.watch(isAdminProvider))
                SettingsSection(
                  title: 'Admin',
                  children: [
                    SettingsMenuItem(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: AppColors.primary,
                      title: 'Admin Dashboard',
                      subtitle: 'Manage content and users',
                      onTap: () => context.push('/admin/dashboard'),
                      showDivider: false,
                    ),
                  ],
                ),
              if (ref.watch(isAdminProvider)) const SizedBox(height: 24),

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

String _localizedStatus(SubscriptionState state, S s) {
  switch (state) {
    case SubscriptionState.free:
      return s.subscriptionFree;
    case SubscriptionState.active:
      return s.subscriptionActive;
    case SubscriptionState.cancelled:
      return s.subscriptionCancelled;
    case SubscriptionState.expired:
      return s.subscriptionExpired;
    case SubscriptionState.pending:
      return s.pending;
    case SubscriptionState.error:
      return s.errorOccurred;
  }
}

class _EditProfileSheet extends StatefulWidget {
  final dynamic user;
  final Function(String name, String email, String? phone, String? avatarUrl)
  onSave;

  const _EditProfileSheet({required this.user, required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _selectedAvatarUrl;

  static final List<String> _avatarPaths = List.generate(
    64,
    (i) => 'assets/images/avatars/avatar_${i + 1}.png',
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _selectedAvatarUrl = widget.user.avatarUrl;
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
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Avatar picker
                Center(
                  child: Column(
                    children: [
                      // Main selected avatar with upload overlay
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setState(
                              () => _selectedAvatarUrl = 'file://${image.path}',
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: AppShadows.soft,
                              ),
                              child: ClipOval(child: _buildSelectedAvatar()),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.surfaceDark
                                        : Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to upload photo',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pre-defined avatars selection
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Or choose an avatar',
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 60,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _avatarPaths.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final path = _avatarPaths[index];
                            final isSelected = _selectedAvatarUrl == path;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedAvatarUrl = path);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: ClipOval(
                                  child: Container(
                                    color: isDark
                                        ? AppColors.surfaceDark
                                        : AppColors.backgroundLight,
                                    child: Image.asset(
                                      path,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

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
                      _selectedAvatarUrl,
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

  Widget _buildSelectedAvatar() {
    if (_selectedAvatarUrl == null || _selectedAvatarUrl!.isEmpty) {
      return const Icon(
        Icons.person_rounded,
        size: 50,
        color: AppColors.textMuted,
      );
    }

    // Legacy avatar_url values point at assets/images/avatars/avatar_N.svg;
    // only the .png variants ship now. Rewrite so old accounts still render.
    var url = _selectedAvatarUrl!;
    if (url.startsWith('assets/images/avatars/avatar_') &&
        url.toLowerCase().endsWith('.svg')) {
      url = url.replaceFirst(RegExp(r'\.svg$', caseSensitive: false), '.png');
    }

    if (url.startsWith('assets/')) {
      if (url.toLowerCase().endsWith('.svg')) {
        return SvgPicture.asset(
          url,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => const Icon(Icons.person, size: 50),
        );
      }
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50),
      );
    }

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50),
      );
    }

    final filePath = url.replaceFirst('file://', '');
    return buildFileImageWidget(
      filePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50),
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
            color: isDark ? Colors.white : AppColors.textPrimary,
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
              color: isDark ? Colors.white : AppColors.textPrimary,
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

class _AssignedTherapistCard extends ConsumerWidget {
  final String therapistId;
  final String cachedName;
  final String userId;
  final bool isDark;

  const _AssignedTherapistCard({
    required this.therapistId,
    required this.cachedName,
    required this.userId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatAccess = ref
            .watch(therapistChatAccessProvider(therapistId))
            .valueOrNull ??
        TherapistChatAccess.full;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('therapists')
          .doc(therapistId)
          .snapshots(),
      builder: (context, snap) {
        String name = cachedName;
        String title = '';
        String photo = '';
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() ?? const {};
          final live =
              (d['name'] ?? d['display_name'] ?? d['full_name'] ?? '')
                  .toString();
          if (live.isNotEmpty) name = live;
          title = (d['title'] ?? '').toString();
          photo = (d['photo_url'] ?? d['avatar_url'] ?? '').toString();
        }
        if (name.isEmpty) name = 'Your therapist';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.adminBorder : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty
                    ? Text(
                        name.characters.isNotEmpty
                            ? name.characters.first.toUpperCase()
                            : '?',
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.headingSmall.copyWith(
                        fontSize: 16,
                        color:
                            isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isDark ? Colors.white60 : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Open chat',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                onPressed: () {
                  if (chatAccess == TherapistChatAccess.none) {
                    final s = ref.read(stringsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.chatLockedPayPrompt)),
                    );
                    return;
                  }
                  context.push('/chat/therapist/${therapistId}_$userId');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
