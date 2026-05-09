import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/theme_switcher.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../profile/providers/profile_provider.dart';

import 'breadcrumb_nav.dart';
import 'broadcast_notification_dialog.dart';
import 'global_search_bar.dart';
import 'notification_bell.dart';
import 'dashboard/ai_assistant_panel.dart';
import 'profile_menu.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  bool _showRightPanel = true;

  @override
  Widget build(BuildContext context) {
    final userPref = ref.watch(profileProvider).user?.settings.darkMode;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = userPref ?? (platformBrightness == Brightness.dark);

    // Override the theme for this subtree
    return Theme(
      data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;
          final isDesktop = size.width >= 1024;
          final isTablet = size.width >= 768 && size.width < 1024;
          // Use the local theme we just set
          final theme = Theme.of(context);
          final isDarkTheme = theme.brightness == Brightness.dark;

          final isMobile = !isDesktop && !isTablet;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            drawer: isMobile
                ? Drawer(
                    backgroundColor: theme.cardColor,
                    child: _buildSidebarContent(context, ref),
                  )
                : null,
            endDrawer: (!isDesktop)
                ? Drawer(
                    width: 300,
                    backgroundColor: theme.cardColor,
                    child: const AiAssistantPanel(),
                  )
                : null,
            body: Builder(
              builder: (scaffoldContext) => Stack(
                children: [
                  // Ambient Background Glow (Dark Mode Only)
                  if (isDarkTheme)
                    Positioned(
                      top: -100,
                      left: -100,
                      child: Container(
                        width: 500,
                        height: 500,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),

                  SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        // Column 1: Navigation Sidebar (Glass)
                        if (isDesktop || isTablet)
                          _buildSidebar(scaffoldContext, ref, isDesktop),

                        // Column 2: Main Content
                        Expanded(
                          child: Column(
                            children: [
                              _buildHeader(scaffoldContext, ref, isMobile),
                              Expanded(
                                child: ClipRRect(
                                  child: widget.child, // The routed screen
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Column 3: AI Assistant Panel (Right Sidebar)
                        if (isDesktop && _showRightPanel)
                          _buildRightPanel(scaffoldContext),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool showMenu) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = AdminResponsive.isMobile(context);
    final isCompact = AdminResponsive.isCompact(context);
    final hPadding = AdminResponsive.headerPadding(context);

    return Container(
      height: isMobile ? 60 : 70,
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.border : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Mobile menu button
          if (showMenu)
            IconButton(
              icon: Icon(
                Icons.menu,
                color: isDark
                    ? AppColors.adminTextPrimary
                    : AppColors.textPrimary,
                size: 24,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),

          // Breadcrumb Navigation (hide on mobile — already has drawer)
          if (!showMenu && !isMobile) const Expanded(child: BreadcrumbNav()),

          if (showMenu || isMobile) const Spacer(),

          // Global Search Bar — adaptive width
          const GlobalSearchBar(),
          SizedBox(width: isCompact ? 4 : (isMobile ? 8 : 16)),

          // Send-Notification button (admin-only general announcement to bell).
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const BroadcastNotificationDialog(),
            ),
            icon: Icon(
              Icons.campaign_rounded,
              size: isMobile ? 20 : 22,
              color:
                  isDark ? AppColors.adminTextPrimary : AppColors.textPrimary,
            ),
            tooltip: 'Send notification',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          SizedBox(width: isCompact ? 2 : (isMobile ? 4 : 8)),

          // Notification Bell
          const NotificationBell(),
          SizedBox(width: isCompact ? 2 : (isMobile ? 4 : 12)),

          // AI Assistant Toggle
          IconButton(
            onPressed: () {
              if (MediaQuery.of(context).size.width >= 1024) {
                setState(() => _showRightPanel = !_showRightPanel);
              } else {
                Scaffold.of(context).openEndDrawer();
              }
            },
            icon: Icon(
              Icons.auto_awesome_rounded,
              size: isMobile ? 20 : 24,
              color:
                  _showRightPanel && MediaQuery.of(context).size.width >= 1024
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary),
            ),
            tooltip: S(ref.watch(languageProvider).language).aiAssistant,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          // Theme Switcher — hide on mobile to save space (accessible in drawer/settings)
          if (!isMobile) ...[
            const SizedBox(width: 12),
            ThemeSwitcher(
              isDark: isDark,
              onToggle: () => ref
                  .read(profileProvider.notifier)
                  .toggleDarkMode(!isDark),
            ),
          ],

          // Profile Menu — hide on compact mobile (accessible in drawer)
          if (!isCompact) ...[
            SizedBox(width: isMobile ? 4 : 12),
            const ProfileMenu(),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: isWide ? 260 : 80,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.8),
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.border : AppColors.borderLight,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: _buildSidebarContent(context, ref, compact: !isWide),
        ),
      ),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    WidgetRef ref, {
    bool compact = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.adminTextPrimary
        : AppColors.textPrimary;
    final s = S(ref.watch(languageProvider).language);

    return Column(
      children: [
        // Logo Area
        Container(
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.border : AppColors.borderLight,
              ),
            ),
          ),
          child: compact
              ? const Icon(
                  Icons.health_and_safety,
                  color: AppColors.primary,
                  size: 32,
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SANAD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: textColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 24),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // MAIN Section
              _SidebarCategory(title: s.sidebarMain, compact: compact),
              _SidebarItem(
                icon: Icons.dashboard_rounded,
                label: s.dashboard,
                route: '/admin/dashboard',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.people_alt_rounded,
                label: s.sidebarUsers,
                route: '/admin/users',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.medical_services_rounded,
                label: s.sidebarClinicians,
                route: '/admin/therapists',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.calendar_month_rounded,
                label: s.sidebarAppointments,
                route: '/admin/bookings',
                compact: compact,
              ),

              // COMMUNICATION Section
              const SizedBox(height: 24),
              _SidebarCategory(title: s.sidebarCommunication, compact: compact),
              _SidebarItem(
                icon: Icons.chat_rounded,
                label: s.sidebarSupportChat,
                route: '/admin/chat',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.forum_rounded,
                label: s.community,
                route: '/admin/community',
                compact: compact,
              ),

              // INSIGHTS Section
              const SizedBox(height: 24),
              _SidebarCategory(title: s.sidebarInsights, compact: compact),
              _SidebarItem(
                icon: Icons.analytics_rounded,
                label: s.analytics,
                route: '/admin/analytics',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.auto_awesome_rounded,
                label: s.aiAnalytics,
                route: '/admin/ai-analytics',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.assessment_rounded,
                label: s.sidebarReports,
                route: '/admin/reports',
                compact: compact,
              ),

              // CONTENT Section
              const SizedBox(height: 24),
              _SidebarCategory(title: s.content, compact: compact),
              _SidebarItem(
                icon: Icons.library_books_rounded,
                label: s.content,
                route: '/admin/cms/content',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.format_quote_rounded,
                label: s.dailyQuotes,
                route: '/admin/cms/quotes',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.flag_rounded,
                label: s.challenges,
                route: '/admin/cms/challenges',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.pages_rounded,
                label: 'Static Pages',
                route: '/admin/cms/pages',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.help_outline_rounded,
                label: 'FAQs',
                route: '/admin/cms/faqs',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.psychology_rounded,
                label: 'Psych Tests',
                route: '/admin/cms/psych-tests',
                compact: compact,
              ),

              // SYSTEM Section
              const SizedBox(height: 24),
              _SidebarCategory(title: s.sidebarSystem, compact: compact),
              _SidebarItem(
                icon: Icons.payments_rounded,
                label: s.sidebarBilling,
                route: '/admin/payments',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.dataset_rounded,
                label: s.sidebarDataManagement,
                route: '/admin/data-management',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.settings_rounded,
                label: s.appSettings,
                route: '/admin/settings',
                compact: compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.8),
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.border : AppColors.borderLight,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: const AiAssistantPanel(),
        ),
      ),
    );
  }
}

class _SidebarCategory extends StatelessWidget {
  final String title;
  final bool compact;

  const _SidebarCategory({required this.title, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.adminTextSecondary
              : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool compact;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    // Simple active check
    final isActive =
        location == route ||
        (location.isNotEmpty &&
            route != '/admin/dashboard' &&
            location.startsWith(route));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.adminTextSecondary
                            : AppColors.textSecondary),
                  size: 20,
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive
                          ? (isDark
                                ? AppColors.adminTextPrimary
                                : AppColors.textPrimary)
                          : (isDark
                                ? AppColors.adminTextSecondary
                                : AppColors.textSecondary),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
