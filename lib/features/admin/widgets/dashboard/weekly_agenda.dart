import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/admin_booking_provider.dart';

class WeeklyAgenda extends ConsumerWidget {
  const WeeklyAgenda({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S(ref.watch(languageProvider).language);
    final bookingsState = ref.watch(adminBookingProvider);
    final today = DateTime.now();
    final dayNames = [s.mon, s.tue, s.wed, s.thu, s.fri, s.sat, s.sun];
    final weekDays = _getWeekDays(today);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.weeklyAgenda,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    s.viewAll,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),

          // Week days header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: weekDays.map((day) {
                final isToday = _isSameDay(day, today);
                return Expanded(
                  child: _DayHeader(
                    day: day,
                    dayName: dayNames[day.weekday - 1],
                    isToday: isToday,
                    isDark: isDark,
                  ),
                );
              }).toList(),
            ),
          ),

          // Appointments list
          Expanded(
            child: bookingsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bookingsState.bookings.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 48,
                            color: isDark
                                ? AppColors.adminTextSecondary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.noAppointmentsThisWeek,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.adminTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookingsState.bookings.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final booking = bookingsState.bookings[index];
                      return _AppointmentItem(
                        clientName: booking.clientName,
                        sessionType: _getSessionTypeLabel(
                          booking.sessionType.name,
                          s,
                        ),
                        time: booking.scheduledTime,
                        statusKey: booking.status.name,
                        statusLabel: _getStatusLabel(booking.status.name, s),
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getSessionTypeLabel(String raw, S strings) {
    switch (raw) {
      case 'audio':
        return strings.audioSession;
      case 'chat':
        return strings.chatSession;
      case 'video':
      default:
        return strings.videoSession;
    }
  }

  String _getStatusLabel(String raw, S strings) {
    switch (raw) {
      case 'pending':
        return strings.pending;
      case 'confirmed':
        return strings.confirmed;
      case 'rejected':
        return strings.rejected;
      case 'completed':
        return strings.completed;
      case 'cancelled':
        return strings.cancelled;
      case 'noShow':
      case 'no_show':
        return strings.noShow;
      default:
        return raw;
    }
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final String dayName;
  final bool isToday;
  final bool isDark;

  const _DayHeader({
    required this.day,
    required this.dayName,
    required this.isToday,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isToday
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                  color: isToday
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentItem extends StatelessWidget {
  final String clientName;
  final String sessionType;
  final DateTime time;
  final String statusKey;
  final String statusLabel;
  final bool isDark;

  const _AppointmentItem({
    required this.clientName,
    required this.sessionType,
    required this.time,
    required this.statusKey,
    required this.statusLabel,
    required this.isDark,
  });

  Color get _statusColor {
    switch (statusKey.toLowerCase()) {
      case 'confirmed':
        return AppColors.statusSuccess;
      case 'pending':
        return AppColors.statusWarning;
      case 'cancelled':
      case 'rejected':
      case 'no_show':
        return AppColors.statusDanger;
      case 'completed':
        return AppColors.statusInfo;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeString =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminSurface.withValues(alpha: 0.5)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border(left: BorderSide(color: _statusColor, width: 3)),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 50,
            child: Text(
              timeString,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.adminTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sessionType,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
