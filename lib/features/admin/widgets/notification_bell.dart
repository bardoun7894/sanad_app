import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/providers/notification_provider.dart';

class NotificationBell extends ConsumerWidget {
  final VoidCallback? onTap;

  const NotificationBell({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S(ref.watch(languageProvider).language);
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.unreadCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => _showNotificationsPanel(context, ref, s),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.adminGlass.withValues(alpha: 0.5)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.border,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 22,
                color: isDark
                    ? AppColors.adminTextPrimary
                    : AppColors.textPrimary,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.adminBackground
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsPanel(BuildContext context, WidgetRef ref, S strings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AdminResponsive.isMobile(context);
    final notificationState = ref.read(notificationProvider);
    final notifications = List<AppNotification>.from(
      notificationState.notifications,
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // On mobile, use a bottom sheet instead of a positioned dialog
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _MobileNotificationSheet(
          isDark: isDark,
          strings: strings,
          notifications: notifications,
          ref: ref,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: 70,
            right: 100,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 360,
                constraints: const BoxConstraints(maxHeight: 480),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.adminSurface : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            strings.notifications,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.adminTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: notifications.isEmpty
                                ? null
                                : () => ref
                                      .read(notificationProvider.notifier)
                                      .markAllAsRead(),
                            child: Text(
                              strings.markAllRead,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                    // Notification Items
                    Flexible(
                      child: notificationState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : notifications.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  strings.noNotifications,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.adminTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                return _NotificationItem(
                                  icon: _iconForType(notification.type),
                                  iconColor: _colorForType(notification.type),
                                  title: notification.title,
                                  subtitle: notification.body,
                                  time: _formatTimeAgo(
                                    notification.createdAt,
                                    strings,
                                  ),
                                  isUnread: !notification.isRead,
                                  isDark: isDark,
                                  onTap: () {
                                    ref
                                        .read(notificationProvider.notifier)
                                        .markAsRead(notification.id);
                                    Navigator.pop(context);
                                    context.go(notification.resolvedRoute);
                                  },
                                );
                              },
                            ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          strings.viewAllNotifications,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.calendar_today_rounded;
      case NotificationType.message:
        return Icons.chat_rounded;
      case NotificationType.community:
        return Icons.forum_rounded;
      case NotificationType.mood:
        return Icons.mood_rounded;
      case NotificationType.therapist:
        return Icons.medical_services_rounded;
      case NotificationType.payment:
        return Icons.payments_rounded;
      case NotificationType.call:
        return Icons.call_rounded;
      case NotificationType.system:
        return Icons.notifications_rounded;
      case NotificationType.crisis:
        return Icons.warning_rounded;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return AppColors.statusInfo;
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.community:
        return AppColors.statusSuccess;
      case NotificationType.mood:
        return AppColors.statusWarning;
      case NotificationType.therapist:
        return AppColors.statusInfo;
      case NotificationType.payment:
        return AppColors.statusSuccess;
      case NotificationType.call:
        return Colors.orange;
      case NotificationType.system:
        return AppColors.statusDanger;
      case NotificationType.crisis:
        return AppColors.error;
    }
  }

  String _formatTimeAgo(DateTime time, S strings) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}${strings.minutesAgo}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}${strings.hoursAgo}';
    }
    return '${diff.inDays}${strings.daysAgo}';
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;
  final bool isDark;
  final VoidCallback? onTap;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isUnread,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: isUnread
            ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : AppColors.primary.withValues(alpha: 0.03))
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isDark
                                ? AppColors.adminTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.adminTextSecondary.withValues(alpha: 0.7)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet notification panel for mobile devices.
class _MobileNotificationSheet extends StatelessWidget {
  final bool isDark;
  final S strings;
  final List<AppNotification> notifications;
  final WidgetRef ref;

  const _MobileNotificationSheet({
    required this.isDark,
    required this.strings,
    required this.notifications,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  strings.notifications,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.adminTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: notifications.isEmpty
                      ? null
                      : () => ref
                            .read(notificationProvider.notifier)
                            .markAllAsRead(),
                  child: Text(
                    strings.markAllRead,
                    style: TextStyle(fontSize: 13, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          // Notification list
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        strings.noNotifications,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _NotificationItem(
                        icon: _iconForType(notification.type),
                        iconColor: _colorForType(notification.type),
                        title: notification.title,
                        subtitle: notification.body,
                        time: _formatTimeAgo(notification.createdAt, strings),
                        isUnread: !notification.isRead,
                        isDark: isDark,
                        onTap: () {
                          ref
                              .read(notificationProvider.notifier)
                              .markAsRead(notification.id);
                          Navigator.pop(context);
                          context.go(notification.resolvedRoute);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.calendar_today_rounded;
      case NotificationType.message:
        return Icons.chat_rounded;
      case NotificationType.community:
        return Icons.forum_rounded;
      case NotificationType.mood:
        return Icons.mood_rounded;
      case NotificationType.therapist:
        return Icons.medical_services_rounded;
      case NotificationType.payment:
        return Icons.payments_rounded;
      case NotificationType.call:
        return Icons.call_rounded;
      case NotificationType.system:
        return Icons.notifications_rounded;
      case NotificationType.crisis:
        return Icons.warning_rounded;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return AppColors.statusInfo;
      case NotificationType.message:
        return AppColors.primary;
      case NotificationType.community:
        return AppColors.statusSuccess;
      case NotificationType.mood:
        return AppColors.statusWarning;
      case NotificationType.therapist:
        return AppColors.statusInfo;
      case NotificationType.payment:
        return AppColors.statusSuccess;
      case NotificationType.call:
        return Colors.orange;
      case NotificationType.system:
        return AppColors.statusDanger;
      case NotificationType.crisis:
        return AppColors.error;
    }
  }

  String _formatTimeAgo(DateTime time, S strings) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}${strings.minutesAgo}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}${strings.hoursAgo}';
    }
    return '${diff.inDays}${strings.daysAgo}';
  }
}
