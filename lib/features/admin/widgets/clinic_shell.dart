import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/admin_unread_provider.dart';
import 'admin_bento_ui.dart';
import 'breadcrumb_nav.dart';
import 'broadcast_notification_dialog.dart';
import 'clinic_sidebar.dart';
import 'dashboard/ai_assistant_panel.dart';
import 'global_search_bar.dart';
import 'mood_alert_bell.dart';
import 'notification_bell.dart';
import 'profile_menu.dart';

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  // Default collapsed so the primary Bento dashboard renders at full width on
  // 1280px–1440px laptops; toggleable via the top-bar AI Assistant pill.
  bool _showRightPanel = false;
  bool _sidebarCollapsed = false;

  /// Previous unread total — used to detect increases. Null = first emission
  /// (initialize silently, never toast on first load).
  int? _prevUnread;

  /// Whether the current route is the admin chat / support-chat screen.
  bool _isOnChatScreen(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return location.startsWith('/admin/chat');
  }

  @override
  Widget build(BuildContext context) {
    // Listen for increases in total unread — show a toast when appropriate.
    ref.listen<AsyncValue<int>>(adminTotalUnreadProvider, (_, next) {
      next.whenData((total) {
        final onChat = _isOnChatScreen(context);
        if (shouldShowNewMessageToast(
          prev: _prevUnread,
          next: total,
          onChatScreen: onChat,
        )) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'رسالة جديدة',
                textDirection: TextDirection.rtl,
              ),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'فتح',
                onPressed: () => context.go('/admin/chat'),
              ),
            ),
          );
        }
        _prevUnread = total;
      });
    });

    final userPref = ref.watch(profileProvider).user?.settings.darkMode;
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = userPref ?? (platformBrightness == Brightness.dark);
    final adminTheme = AdminBento.buildAdminTheme(
      isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      isDark,
    );

    return Theme(
      data: adminTheme,
      child: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;
          final isDesktop = size.width >= 1024;
          final isTablet = size.width >= 768 && size.width < 1024;
          final isMobile = !isDesktop && !isTablet;

          return Scaffold(
            backgroundColor: AdminBento.canvas(isDark),
            drawer: isMobile
                ? Drawer(
                    backgroundColor: AdminBento.surface(isDark),
                    child: const ClinicSidebar(),
                  )
                : null,
            endDrawer: (!isDesktop)
                ? Drawer(
                    width: 340,
                    backgroundColor: AdminBento.surface(isDark),
                    child: const AiAssistantPanel(),
                  )
                : null,
            body: Builder(
              builder: (scaffoldContext) => SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // Column 1: Navigation Sidebar (collapsible on desktop)
                    if (isDesktop || isTablet)
                      _buildSidebar(scaffoldContext, isDesktop),

                    // Column 2: Main Content
                    Expanded(
                      child: Column(
                        children: [
                          _buildHeader(scaffoldContext, ref, isMobile),
                          Expanded(
                            child: ClipRRect(child: widget.child),
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final langState = ref.watch(languageProvider);
    final isAr = langState.language == AppLanguage.arabic;
    final s = S(langState.language);
    final aiActive = _showRightPanel && isDesktop;

    return Container(
      height: isMobile ? 60 : 66,
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      decoration: BoxDecoration(
        color: AdminBento.surface(isDark),
        border: Border(bottom: BorderSide(color: AdminBento.border(isDark))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availWidth = constraints.maxWidth;
          final showInlineSearch = !isMobile && availWidth >= 680;
          final searchWidth = availWidth >= 960 ? 250.0 : 185.0;
          final showAiPill = isDesktop && availWidth >= 820;
          final showLangPill = !isMobile && availWidth >= 560;

          return Row(
            children: [
              if (showMenu)
                AdminHeaderIconButton(
                  icon: Icons.menu_rounded,
                  tooltip: isAr ? 'القائمة' : 'Menu',
                  onTap: () => Scaffold.of(context).openDrawer(),
                ),
              if (!showMenu && !isMobile)
                const Expanded(child: BreadcrumbNav()),
              if (showMenu || isMobile) const Spacer(),

              GlobalSearchBar(
                width: searchWidth,
                forceCompact: !showInlineSearch,
              ),

              if (!isMobile) _HeaderDivider(isDark: isDark),
              if (isMobile) SizedBox(width: isCompact ? 4 : 6),

              AdminHeaderIconButton(
                icon: Icons.campaign_rounded,
                tooltip: isAr ? 'إرسال إشعار جماعي' : 'Broadcast notification',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const BroadcastNotificationDialog(),
                ),
              ),
              SizedBox(width: isCompact ? 4 : 6),
              const NotificationBell(),
              SizedBox(width: isCompact ? 4 : 6),
              const MoodAlertBell(),

              if (!isMobile) _HeaderDivider(isDark: isDark),
              if (isMobile) SizedBox(width: isCompact ? 4 : 6),

              if (showAiPill)
                _AiAssistantHeaderPill(
                  label: s.aiAssistant,
                  isActive: aiActive,
                  isDark: isDark,
                  onTap: () =>
                      setState(() => _showRightPanel = !_showRightPanel),
                )
              else
                AdminHeaderIconButton(
                  icon: Icons.auto_awesome_rounded,
                  tooltip: s.aiAssistant,
                  isActive: aiActive,
                  onTap: () {
                    if (isDesktop) {
                      setState(() => _showRightPanel = !_showRightPanel);
                    } else {
                      Scaffold.of(context).openEndDrawer();
                    }
                  },
                ),

              if (showLangPill) ...[
                const SizedBox(width: 6),
                _LanguageHeaderPill(
                  isAr: isAr,
                  isDark: isDark,
                  onTap: () =>
                      ref.read(languageProvider.notifier).toggleLanguage(),
                ),
              ],

              if (!isMobile) ...[
                const SizedBox(width: 6),
                AdminHeaderIconButton(
                  icon: isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  tooltip: isDark
                      ? (isAr ? 'الوضع النهاري' : 'Light mode')
                      : (isAr ? 'الوضع الليلي' : 'Dark mode'),
                  onTap: () => ref
                      .read(profileProvider.notifier)
                      .toggleDarkMode(!isDark),
                ),
              ],

              if (!isCompact) ...[
                SizedBox(width: isMobile ? 6 : 8),
                const ProfileMenu(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compact = !isDesktop || _sidebarCollapsed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: compact ? 76 : 254,
      decoration: BoxDecoration(
        color: AdminBento.surface(isDark),
        border: BorderDirectional(
          end: BorderSide(color: AdminBento.border(isDark)),
        ),
      ),
      child: ClinicSidebar(
        compact: compact,
        onToggleCollapse: isDesktop
            ? () => setState(() => _sidebarCollapsed = !_sidebarCollapsed)
            : null,
      ),
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 344,
      decoration: BoxDecoration(
        color: AdminBento.surface(isDark),
        border: BorderDirectional(
          start: BorderSide(color: AdminBento.border(isDark)),
        ),
      ),
      child: const AiAssistantPanel(),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  final bool isDark;

  const _HeaderDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AdminBento.border(isDark),
    );
  }
}

class _AiAssistantHeaderPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _AiAssistantHeaderPill({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? AppColors.primary.withValues(alpha: 0.12)
          : AdminBento.surfaceMuted(isDark),
      borderRadius: BorderRadius.circular(AdminBento.controlRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminBento.controlRadius),
        child: Container(
          height: AdminBento.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminBento.controlRadius),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AdminBento.borderStrong(isDark),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: isActive
                    ? AppColors.primary
                    : AdminBento.textSecondary(isDark),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? AppColors.primary
                      : AdminBento.textPrimary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageHeaderPill extends StatelessWidget {
  final bool isAr;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageHeaderPill({
    required this.isAr,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isAr ? 'Switch to English' : 'التبديل إلى العربية',
      child: Material(
        color: AdminBento.surfaceMuted(isDark),
        borderRadius: BorderRadius.circular(AdminBento.controlRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AdminBento.controlRadius),
          child: Container(
            height: AdminBento.controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AdminBento.controlRadius),
              border: Border.all(color: AdminBento.borderStrong(isDark)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 15,
                  color: AdminBento.textSecondary(isDark),
                ),
                const SizedBox(width: 5),
                Text(
                  isAr ? 'EN' : 'AR',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AdminBento.textPrimary(isDark),
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
