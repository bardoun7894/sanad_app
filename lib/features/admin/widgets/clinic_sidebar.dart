import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_unread_provider.dart';
import 'admin_bento_ui.dart';
import 'clinic_sidebar_items.dart';

/// 2026 Bento admin navigation sidebar supporting expanded (desktop/drawer) and
/// compact rail (tablet or collapsed desktop) modes with hover highlights,
/// tooltips, and collapsible desktop footer control.
class ClinicSidebar extends ConsumerWidget {
  final bool compact;
  final VoidCallback? onToggleCollapse;

  const ClinicSidebar({
    super.key,
    this.compact = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AdminBento.textPrimary(isDark);
    final lang = ref.watch(languageProvider).language;
    final isAr = lang == AppLanguage.arabic;
    final s = S(lang);
    final unread = ref.watch(adminTotalUnreadProvider).valueOrNull ?? 0;

    return Column(
      children: [
        // Brand Header (aligned with 66px top bar)
        Container(
          height: 66,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
          alignment: compact
              ? Alignment.center
              : AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AdminBento.border(isDark)),
            ),
          ),
          child: compact
              ? Tooltip(
                  message: isAr ? 'سند — لوحة الإدارة' : 'Sanad Clinical Admin',
                  child: InkWell(
                    onTap: () => context.go('/admin/dashboard'),
                    borderRadius: BorderRadius.circular(11),
                    child: const SidebarBrandMark(),
                  ),
                )
              : Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/admin/dashboard'),
                      borderRadius: BorderRadius.circular(11),
                      child: const SidebarBrandMark(),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isAr ? 'سند' : 'Sanad',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17.5,
                                    height: 1.1,
                                    letterSpacing: -0.2,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: isDark ? 0.2 : 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.statusSuccess,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  isAr ? 'العيادة متصلة' : 'Clinic Online',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AdminBento.textSecondary(isDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: 14,
            ),
            children: [
              // MAIN Section
              SidebarCategory(title: s.sidebarMain, compact: compact),
              SidebarNavItem(
                icon: Icons.dashboard_rounded,
                label: s.dashboard,
                route: '/admin/dashboard',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.people_alt_rounded,
                label: s.sidebarUsers,
                route: '/admin/users',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.medical_services_rounded,
                label: s.sidebarClinicians,
                route: '/admin/therapists',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.calendar_month_rounded,
                label: s.sidebarAppointments,
                route: '/admin/bookings',
                compact: compact,
              ),

              // COMMUNICATION Section
              SidebarDivider(compact: compact),
              SidebarCategory(title: s.sidebarCommunication, compact: compact),
              SidebarNavItem(
                icon: Icons.chat_rounded,
                label: s.sidebarSupportChat,
                route: '/admin/chat',
                compact: compact,
                badgeLabel: unreadBadgeLabel(unread),
              ),
              SidebarNavItem(
                icon: Icons.forum_rounded,
                label: s.community,
                route: '/admin/community',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.mood_rounded,
                label: isAr ? 'المشاعر' : 'Moods',
                route: '/admin/moods',
                compact: compact,
              ),

              // INSIGHTS Section
              SidebarDivider(compact: compact),
              SidebarCategory(title: s.sidebarInsights, compact: compact),
              SidebarNavItem(
                icon: Icons.analytics_rounded,
                label: s.analytics,
                route: '/admin/analytics',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.psychology_outlined,
                label: s.aiAnalytics,
                route: '/admin/ai-analytics',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.assessment_rounded,
                label: s.sidebarReports,
                route: '/admin/reports',
                compact: compact,
              ),

              // CONTENT Section
              SidebarDivider(compact: compact),
              SidebarCategory(title: s.content, compact: compact),
              SidebarNavItem(
                icon: Icons.library_books_rounded,
                label: s.content,
                route: '/admin/cms/content',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.format_quote_rounded,
                label: s.dailyQuotes,
                route: '/admin/cms/quotes',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.flag_rounded,
                label: s.challenges,
                route: '/admin/cms/challenges',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.pages_rounded,
                label: isAr ? 'الصفحات الثابتة' : 'Static Pages',
                route: '/admin/cms/pages',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.help_outline_rounded,
                label: isAr ? 'الأسئلة الشائعة' : 'FAQs',
                route: '/admin/cms/faqs',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.psychology_rounded,
                label: isAr ? 'الاختبارات النفسية' : 'Psych Tests',
                route: '/admin/cms/psych-tests',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.menu_book_rounded,
                label: isAr ? 'تمارين التدوين' : 'Journaling Prompts',
                route: '/admin/cms/journaling',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.spa_rounded,
                label: isAr ? 'نصائح المزاج' : 'Mood Advice',
                route: '/admin/cms/mood-advice',
                compact: compact,
              ),

              // SYSTEM Section
              SidebarDivider(compact: compact),
              SidebarCategory(title: s.sidebarSystem, compact: compact),
              SidebarNavItem(
                icon: Icons.payments_rounded,
                label: s.sidebarBilling,
                route: '/admin/payments',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.dataset_rounded,
                label: s.sidebarDataManagement,
                route: '/admin/data-management',
                compact: compact,
              ),
              SidebarNavItem(
                icon: Icons.settings_rounded,
                label: s.appSettings,
                route: '/admin/settings',
                compact: compact,
              ),
            ],
          ),
        ),

        // Bottom Collapse Toggle Footer (Desktop)
        if (onToggleCollapse != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AdminBento.border(isDark))),
            ),
            child: Material(
              color: AdminBento.surfaceMuted(isDark),
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                onTap: onToggleCollapse,
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  height: 36,
                  padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AdminBento.border(isDark)),
                  ),
                  child: Row(
                    mainAxisAlignment: compact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!compact)
                        Text(
                          isAr ? 'تصغير القائمة' : 'Collapse sidebar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AdminBento.textSecondary(isDark),
                          ),
                        ),
                      Icon(
                        compact
                            ? Icons.keyboard_double_arrow_right_rounded
                            : Icons.keyboard_double_arrow_left_rounded,
                        size: 17,
                        color: AdminBento.textSecondary(isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
