import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';

class BreadcrumbNav extends ConsumerWidget {
  const BreadcrumbNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final location = GoRouterState.of(context).uri.toString();
    final lang = ref.watch(languageProvider).language;
    final isAr = lang == AppLanguage.arabic;
    final s = S(lang);
    final segments = _parseRoute(location, s, isAr);

    return Row(
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                isRtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 16,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textMuted,
              ),
            ),
          Flexible(
            child: _BreadcrumbItem(
              label: segments[i].label,
              route: segments[i].route,
              isLast: i == segments.length - 1,
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }

  List<BreadcrumbSegment> _parseRoute(String location, S s, bool isAr) {
    final segments = <BreadcrumbSegment>[
      BreadcrumbSegment(label: s.dashboard, route: '/admin/dashboard'),
    ];

    if (location == '/admin/dashboard' || location == '/admin') {
      return segments;
    }

    final parts = location.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) {
      String currentPath = '';
      for (int i = 1; i < parts.length; i++) {
        currentPath += '/${parts[i]}';
        final label = _getRouteLabel(parts[i], s, isAr);
        if (label != null && parts[i] != 'admin' && parts[i] != 'dashboard') {
          segments.add(
            BreadcrumbSegment(label: label, route: '/admin$currentPath'),
          );
        }
      }
    }

    return segments;
  }

  String? _getRouteLabel(String segment, S s, bool isAr) {
    final labels = {
      'users': s.sidebarUsers,
      'patients': s.sidebarUsers,
      'therapists': s.sidebarClinicians,
      'clinicians': s.sidebarClinicians,
      'bookings': s.sidebarAppointments,
      'appointments': s.sidebarAppointments,
      'chat': s.sidebarSupportChat,
      'community': s.community,
      'moods': isAr ? 'المشاعر' : 'Moods',
      'analytics': s.analytics,
      'ai-analytics': s.aiAnalytics,
      'reports': s.sidebarReports,
      'payments': s.sidebarBilling,
      'billing': s.sidebarBilling,
      'crisis-alerts': s.crisisAlerts,
      'signup-health': isAr ? 'ملفات غير مكتملة' : 'Signup Health',
      'cms': s.content,
      'content': s.content,
      'quotes': s.dailyQuotes,
      'challenges': s.challenges,
      'pages': isAr ? 'الصفحات الثابتة' : 'Static Pages',
      'faqs': isAr ? 'الأسئلة الشائعة' : 'FAQs',
      'psych-tests': isAr ? 'الاختبارات النفسية' : 'Psych Tests',
      'journaling': isAr ? 'تمارين التدوين' : 'Journaling Prompts',
      'mood-advice': isAr ? 'نصائح المزاج' : 'Mood Advice',
      'settings': s.appSettings,
      'data-management': s.sidebarDataManagement,
    };
    return labels[segment];
  }
}

class BreadcrumbSegment {
  final String label;
  final String route;

  BreadcrumbSegment({required this.label, required this.route});
}

class _BreadcrumbItem extends StatelessWidget {
  final String label;
  final String route;
  final bool isLast;
  final bool isDark;

  const _BreadcrumbItem({
    required this.label,
    required this.route,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isLast
        ? (isDark ? AppColors.adminTextPrimary : AppColors.textPrimary)
        : (isDark ? AppColors.adminTextSecondary : AppColors.textSecondary);

    return InkWell(
      onTap: isLast ? null : () => context.go(route),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
