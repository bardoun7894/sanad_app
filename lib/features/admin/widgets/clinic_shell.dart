import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/theme_switcher.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/admin_unread_provider.dart';
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
  bool _showRightPanel = true;

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

    return Theme(
      data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;
          final isDesktop = size.width >= 1024;
          final isTablet = size.width >= 768 && size.width < 1024;
          final theme = Theme.of(context);
          final isMobile = !isDesktop && !isTablet;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            drawer: isMobile
                ? Drawer(
                    backgroundColor: theme.cardColor,
                    child: const ClinicSidebar(),
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
              builder: (scaffoldContext) => SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // Column 1: Navigation Sidebar
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
    final s = S(ref.watch(languageProvider).language);
    final aiActive = _showRightPanel && isDesktop;

    return Container(
      height: isMobile ? 60 : 66,
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.adminBorder : const Color(0xFFE6ECF1),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenu)
            IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: isDark
                    ? AppColors.adminTextPrimary
                    : AppColors.textPrimary,
                size: 24,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          if (!showMenu && !isMobile) const Expanded(child: BreadcrumbNav()),
          if (showMenu || isMobile) const Spacer(),
          const GlobalSearchBar(),
          SizedBox(width: isCompact ? 4 : (isMobile ? 8 : 12)),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const BroadcastNotificationDialog(),
            ),
            icon: Icon(
              Icons.campaign_rounded,
              size: isMobile ? 20 : 21,
              color: isDark
                  ? AppColors.adminTextPrimary
                  : AppColors.textPrimary,
            ),
            tooltip: 'Send notification',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          SizedBox(width: isCompact ? 2 : (isMobile ? 4 : 6)),
          const NotificationBell(),
          SizedBox(width: isCompact ? 2 : (isMobile ? 4 : 6)),
          const MoodAlertBell(),
          SizedBox(width: isCompact ? 2 : (isMobile ? 4 : 10)),
          if (isDesktop)
            Material(
              color: aiActive
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : (isDark
                        ? AppColors.adminGlass.withValues(alpha: 0.5)
                        : const Color(0xFFF4F7FA)),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () =>
                    setState(() => _showRightPanel = !_showRightPanel),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: aiActive
                          ? AppColors.primary.withValues(alpha: 0.35)
                          : (isDark
                                ? AppColors.adminBorder
                                : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: aiActive
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.adminTextSecondary
                                  : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.aiAssistant,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: aiActive
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.adminTextPrimary
                                    : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              icon: Icon(
                Icons.auto_awesome_rounded,
                size: isMobile ? 20 : 22,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
              tooltip: s.aiAssistant,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          if (!isMobile) ...[
            const SizedBox(width: 10),
            ThemeSwitcher(
              isDark: isDark,
              onToggle: () => ref
                  .read(profileProvider.notifier)
                  .toggleDarkMode(!isDark),
            ),
          ],
          if (!isCompact) ...[
            SizedBox(width: isMobile ? 4 : 10),
            const ProfileMenu(),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, bool isWide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: isWide ? 256 : 78,
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        border: BorderDirectional(
          end: BorderSide(
            color: isDark ? AppColors.adminBorder : const Color(0xFFE6ECF1),
          ),
        ),
      ),
      child: ClinicSidebar(compact: !isWide),
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        border: BorderDirectional(
          start: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),
        ),
      ),
      child: const AiAssistantPanel(),
    );
  }
}
