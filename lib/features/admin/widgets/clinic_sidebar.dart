import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_unread_provider.dart';

/// Admin navigation sidebar supporting expanded (desktop/drawer) and compact
/// rail (tablet) modes with solid Sanad Teal active pill indicators.
class ClinicSidebar extends ConsumerWidget {
  final bool compact;

  const ClinicSidebar({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.adminTextPrimary
        : AppColors.textPrimary;
    final lang = ref.watch(languageProvider).language;
    final isAr = lang == AppLanguage.arabic;
    final s = S(lang);

    return Column(
      children: [
        // Logo Area (aligned with 66px top bar)
        Container(
          height: 66,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 18),
          alignment: compact
              ? Alignment.center
              : AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.adminBorder : const Color(0xFFE6ECF1),
              ),
            ),
          ),
          child: compact
              ? Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppColors.adminPrimaryGradient,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                )
              : Row(
                  children: [
                    Container(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'سند' : 'Sanad',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              height: 1.1,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAr ? 'لوحة إدارة العيادة' : 'Clinical Admin',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.adminTextSecondary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 16),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
              const SizedBox(height: 20),
              _SidebarCategory(title: s.sidebarCommunication, compact: compact),
              _SidebarItem(
                icon: Icons.chat_rounded,
                label: s.sidebarSupportChat,
                route: '/admin/chat',
                compact: compact,
                badgeLabel: unreadBadgeLabel(
                  ref.watch(adminTotalUnreadProvider).valueOrNull ?? 0,
                ),
              ),
              _SidebarItem(
                icon: Icons.forum_rounded,
                label: s.community,
                route: '/admin/community',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.mood_rounded,
                label: isAr ? 'المشاعر' : 'Moods',
                route: '/admin/moods',
                compact: compact,
              ),

              // INSIGHTS Section
              const SizedBox(height: 20),
              _SidebarCategory(title: s.sidebarInsights, compact: compact),
              _SidebarItem(
                icon: Icons.analytics_rounded,
                label: s.analytics,
                route: '/admin/analytics',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.psychology_outlined,
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
              const SizedBox(height: 20),
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
                label: isAr ? 'الصفحات الثابتة' : 'Static Pages',
                route: '/admin/cms/pages',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.help_outline_rounded,
                label: isAr ? 'الأسئلة الشائعة' : 'FAQs',
                route: '/admin/cms/faqs',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.psychology_rounded,
                label: isAr ? 'الاختبارات النفسية' : 'Psych Tests',
                route: '/admin/cms/psych-tests',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.menu_book_rounded,
                label: isAr ? 'تمارين التدوين' : 'Journaling Prompts',
                route: '/admin/cms/journaling',
                compact: compact,
              ),
              _SidebarItem(
                icon: Icons.spa_rounded,
                label: isAr ? 'نصائح المزاج' : 'Mood Advice',
                route: '/admin/cms/mood-advice',
                compact: compact,
              ),

              // SYSTEM Section
              const SizedBox(height: 20),
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
}

class _SidebarCategory extends StatelessWidget {
  final String title;
  final bool compact;

  const _SidebarCategory({required this.title, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, bottom: 8, top: 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          letterSpacing: 0.6,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.adminTextSecondary.withValues(alpha: 0.75)
              : AppColors.textMuted,
          fontWeight: FontWeight.w700,
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

  /// Badge label to show on the icon (e.g. "3", "9+"). Empty string = hidden.
  final String badgeLabel;

  const _SidebarItem({
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

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
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
                  const SizedBox(width: 12),
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
  }
}
