import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../mood/models/mood_enums.dart';
import '../models/mood_alert.dart';
import '../providers/mood_alerts_provider.dart';

/// Admin bell that surfaces recent negative-mood alerts.
///
/// Mirrors [NotificationBell] in chrome, badge logic, and panel UX.
/// - Bell icon: [Icons.sentiment_dissatisfied_rounded]
/// - Badge: red circle, count from [moodAlertsProvider], clamped to '9+'.
/// - Panel: desktop = showDialog popup; mobile = showModalBottomSheet.
/// - Each row has a trailing "Message" button that navigates to
///   `/admin/chat/detail/:userId` and closes the panel.
class MoodAlertBell extends ConsumerWidget {
  const MoodAlertBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertCount = ref.watch(moodAlertsProvider).value?.length ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMoodAlertsPanel(context, ref, isDark),
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
                Icons.sentiment_dissatisfied_rounded,
                size: 22,
                color: isDark
                    ? AppColors.adminTextPrimary
                    : AppColors.textPrimary,
              ),
              if (alertCount > 0)
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
                      alertCount > 9 ? '9+' : alertCount.toString(),
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

  void _showMoodAlertsPanel(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final isMobile = AdminResponsive.isMobile(context);

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _MobileMoodAlertsSheet(
          isDark: isDark,
          ref: ref,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(dialogContext),
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
                    color:
                        isDark ? AppColors.borderDark : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _MoodAlertsPanelBody(
                  isDark: isDark,
                  ref: ref,
                  dialogContext: dialogContext,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop panel body (shared between dialog and bottom sheet wrappers)
// ---------------------------------------------------------------------------

class _MoodAlertsPanelBody extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;
  final BuildContext dialogContext;

  const _MoodAlertsPanelBody({
    required this.isDark,
    required this.ref,
    required this.dialogContext,
  });

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(moodAlertsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.sentiment_dissatisfied_rounded,
                size: 18,
                color: isDark
                    ? AppColors.adminTextPrimary
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'تنبيهات المزاج',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.adminTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        // Body — handle all AsyncValue states
        Flexible(
          child: alertsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'تعذر تحميل التنبيهات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            data: (alerts) => alerts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'لا توجد تنبيهات',
                        textAlign: TextAlign.center,
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
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return _MoodAlertItem(
                        alert: alert,
                        isDark: isDark,
                        onMessage: () {
                          Navigator.pop(dialogContext);
                          dialogContext.go(
                            '/admin/chat/detail/${alert.userId}',
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Single alert row
// ---------------------------------------------------------------------------

class _MoodAlertItem extends StatelessWidget {
  final MoodAlert alert;
  final bool isDark;
  final VoidCallback onMessage;

  const _MoodAlertItem({
    required this.alert,
    required this.isDark,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = _colorForMood(alert.mood);
    final emoji = MoodTypeExtension.emoji(alert.mood);
    final label = MoodTypeExtension.label(alert.mood);
    final timeAgo = _formatTimeAgo(alert.date);
    final displayName = alert.userName ?? 'مستخدم';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.borderDark.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mood emoji in colored circle
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          // Name + label + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.adminTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
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
          // Message button
          IconButton(
            onPressed: onMessage,
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            tooltip: 'مراسلة',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Color _colorForMood(MoodType mood) {
    switch (mood) {
      case MoodType.anxious:
        return AppColors.statusWarning;
      case MoodType.sad:
        return AppColors.statusInfo;
      case MoodType.angry:
        return AppColors.statusDanger;
      default:
        return AppColors.statusWarning;
    }
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} دقيقة';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} ساعة';
    }
    return '${diff.inDays} يوم';
  }
}

// ---------------------------------------------------------------------------
// Mobile bottom sheet wrapper
// ---------------------------------------------------------------------------

class _MobileMoodAlertsSheet extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;

  const _MobileMoodAlertsSheet({
    required this.isDark,
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
                Icon(
                  Icons.sentiment_dissatisfied_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.adminTextPrimary
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'تنبيهات المزاج',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.adminTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          // Body
          Expanded(
            child: _MoodAlertsPanelBody(
              isDark: isDark,
              ref: ref,
              dialogContext: context,
            ),
          ),
        ],
      ),
    );
  }
}
