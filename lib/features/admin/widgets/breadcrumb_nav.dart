import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/language_provider.dart';

class BreadcrumbNav extends ConsumerWidget {
  const BreadcrumbNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = false;
    final location = GoRouterState.of(context).uri.toString();
    final s = S(ref.watch(languageProvider).language);
    final segments = _parseRoute(location, s);

    return Row(
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          _BreadcrumbItem(
            label: segments[i].label,
            route: segments[i].route,
            isLast: i == segments.length - 1,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  List<BreadcrumbSegment> _parseRoute(String location, S s) {
    final segments = <BreadcrumbSegment>[];

    // Always start with Dashboard
    segments.add(
      BreadcrumbSegment(label: s.dashboard, route: '/admin/dashboard'),
    );

    if (location == '/admin/dashboard' || location == '/admin') {
      return segments;
    }

    // Parse remaining segments
    final parts = location.split('/').where((p) => p.isNotEmpty).toList();

    if (parts.length > 1) {
      String currentPath = '';
      for (int i = 1; i < parts.length; i++) {
        currentPath += '/${parts[i]}';
        final label = _getRouteLabel(parts[i], s);
        if (label != null && parts[i] != 'admin' && parts[i] != 'dashboard') {
          segments.add(
            BreadcrumbSegment(label: label, route: '/admin$currentPath'),
          );
        }
      }
    }

    return segments;
  }

  String? _getRouteLabel(String segment, S s) {
    final labels = {
      'users': s.sidebarUsers,
      'patients': s.sidebarUsers,
      'therapists': s.sidebarClinicians,
      'clinicians': s.sidebarClinicians,
      'bookings': s.sidebarAppointments,
      'appointments': s.sidebarAppointments,
      'chat': s.sidebarSupportChat,
      'community': s.community,
      'analytics': s.analytics,
      'reports': s.sidebarReports,
      'payments': s.sidebarBilling,
      'billing': s.sidebarBilling,
      'cms': s.content,
      'content': s.content,
      'quotes': s.dailyQuotes,
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
