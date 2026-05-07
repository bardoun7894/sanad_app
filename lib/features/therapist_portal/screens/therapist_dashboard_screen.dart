import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../providers/therapist_dashboard_provider.dart';
import '../providers/therapist_analytics_provider.dart';
import '../widgets/booking_card.dart';
import '../widgets/therapist_header.dart';
import '../widgets/charts/kpi_sparkline_card.dart';
import '../widgets/charts/session_volume_chart.dart';
import '../widgets/charts/earnings_chart.dart';
import '../widgets/charts/patient_distribution_chart.dart';
import '../widgets/charts/chart_utils.dart';

class TherapistDashboardScreen extends ConsumerStatefulWidget {
  const TherapistDashboardScreen({super.key});

  @override
  ConsumerState<TherapistDashboardScreen> createState() =>
      _TherapistDashboardScreenState();
}

class _TherapistDashboardScreenState
    extends ConsumerState<TherapistDashboardScreen> {
  ChartPeriod _sessionVolumePeriod = ChartPeriod.week;
  ChartPeriod _earningsPeriod = ChartPeriod.week;
  DistributionCategory _distributionCategory = DistributionCategory.sessionType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Any initialization if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(therapistDashboardProvider);
    final notifier = ref.read(therapistDashboardProvider.notifier);
    final strings = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: () => notifier.refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Header
                      TherapistHeader(
                        profile: state.profile,
                        isOnline: state.isActive,
                        onToggleOnline: () => notifier.toggleActive(),
                        onProfileTap: () =>
                            context.push(AppRoutes.therapistSettings),
                      ),

                      const SizedBox(height: 24),

                      // KPI Sparkline Cards Row
                      _buildKPISection(ref, state, strings),

                      const SizedBox(height: 32),

                      // Session Volume Chart
                      _buildSessionVolumeChart(ref),

                      const SizedBox(height: 24),

                      // Two-column charts row (Earnings + Distribution)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Stack vertically on mobile, side-by-side on tablet+
                          if (constraints.maxWidth < 800) {
                            return Column(
                              children: [
                                _buildEarningsChart(ref),
                                const SizedBox(height: 24),
                                _buildDistributionChart(ref),
                              ],
                            );
                          } else {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildEarningsChart(ref)),
                                const SizedBox(width: 24),
                                Expanded(child: _buildDistributionChart(ref)),
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 32),

                      // Urgent Alerts Section
                      if (state.hasUrgentAlerts) ...[
                        _buildSectionHeader(
                          context,
                          title: '⚠️ ${strings.urgentAlerts}',
                          actionText: strings.viewAll,
                          onAction: () => context.push('/therapist/chats'),
                          isDark: isDark,
                          isUrgent: true,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: state.urgentChats.take(3).map((chat) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_rounded,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${chat.userName} - waiting ${_formatWaitTime(chat.lastMessageTime, strings)}',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.push(
                                        '/therapist/chat/${chat.chatId}',
                                      ),
                                      child: Text(strings.reply),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Waiting Queue Section (Users who paid, waiting for session)
                      if (state.hasWaitingUsers) ...[
                        _buildSectionHeader(
                          context,
                          title: '🕐 ${strings.waitingQueue}',
                          actionText: strings.viewAll,
                          onAction: () => context.push('/therapist/bookings'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: state.waitingQueue.take(3).map((booking) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.blue.withValues(
                                        alpha: 0.1,
                                      ),
                                      child: Text(
                                        booking.clientName.isNotEmpty
                                            ? booking.clientName[0]
                                                  .toUpperCase()
                                            : 'C',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                booking.clientName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              if (booking.clientAge !=
                                                  null) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? Colors.white10
                                                        : Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${booking.clientAge}${strings.yearAbbr}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isDark
                                                          ? Colors.white60
                                                          : Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (booking.primaryComplaint !=
                                              null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              booking.primaryComplaint!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => context.push(
                                        '/therapist/booking/${booking.id}',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: Text(strings.start),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Pending Requests Section
                      if (state.hasPendingRequests) ...[
                        _buildSectionHeader(
                          context,
                          title: strings.pendingRequests,
                          actionText: strings.viewAll,
                          onAction: () => context.push('/therapist/bookings'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        ...state.pendingBookings.take(3).map((booking) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: BookingCard(
                              booking: booking,
                              showActions: true,
                              onAccept: () =>
                                  notifier.acceptBooking(booking.id),
                              onReject: () => _showRejectDialog(
                                context,
                                notifier,
                                booking.id,
                                strings,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // Today's Schedule Section
                      _buildSectionHeader(
                        context,
                        title: strings.todaysSchedule,
                        actionText: strings.manageAvailability,
                        onAction: () => context.push('/therapist/availability'),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      if (state.todaysBookings.isEmpty)
                        _buildEmptyState(context, strings, isDark)
                      else
                        ...state.todaysBookings.map((booking) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: BookingCard(
                              booking: booking,
                              showActions: false,
                              onTap: () => context.push(
                                '/therapist/booking/${booking.id}',
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 32),

                      // Quick Actions Section
                      Text(
                        strings.quickActions,
                        style: AppTypography.headingMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActionsGrid(context, strings, isDark),

                      const SizedBox(height: 100), // Bottom padding for nav bar
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNav(context, strings),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String actionText,
    required VoidCallback onAction,
    required bool isDark,
    bool isUrgent = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: AppTypography.headingMedium.copyWith(
              color: isUrgent
                  ? Colors.red
                  : (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionText,
            style: AppTypography.labelLarge.copyWith(
              color: isUrgent ? Colors.red : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Format wait time for urgent alerts
  String _formatWaitTime(DateTime? lastMessageTime, S s) {
    if (lastMessageTime == null) return 'unknown';
    final diff = DateTime.now().difference(lastMessageTime);
    if (diff.inHours > 0) {
      return '${diff.inHours}${s.hourAbbr} ${diff.inMinutes % 60}${s.minuteAbbr}';
    }
    return '${diff.inMinutes}${s.minuteAbbr}';
  }

  Widget _buildEmptyState(BuildContext context, S strings, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : const Color(0xFFF1F5F9), // Slate-100
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 32,
              color: isDark
                  ? Colors.white60
                  : const Color(0xFF94A3B8), // Slate-400
            ),
          ),
          const SizedBox(height: 16),
          Text(
            strings.noSessionsToday,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? Colors.white70
                  : const Color(0xFF64748B), // Slate-500
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, S strings, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard(
          context,
          icon: Icons.chat_bubble_outline_rounded,
          label: strings.messages,
          color: const Color(0xFF10B981), // Emerald
          onTap: () => context.push('/therapist/messages'),
          isDark: isDark,
        ),
        _buildActionCard(
          context,
          icon: Icons.calendar_month_rounded,
          label: strings.availability,
          color: const Color(0xFF3B82F6), // Blue
          onTap: () => context.push('/therapist/availability'),
          isDark: isDark,
        ),
        _buildActionCard(
          context,
          icon: Icons.list_alt_rounded,
          label: strings.allBookings,
          color: const Color(0xFF8B5CF6), // Violet
          onTap: () => context.push('/therapist/bookings'),
          isDark: isDark,
        ),
        _buildActionCard(
          context,
          icon: Icons.person_outline_rounded,
          label: strings.profile,
          color: const Color(0xFFEC4899), // Pink
          onTap: () => context.push(AppRoutes.therapistSettings),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, S strings) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -8),
            blurRadius: 30,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: strings.dashboard,
                  isSelected: true,
                  onTap: () {}, // Already on dashboard
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.calendar_today_rounded,
                  label: strings.bookings,
                  isSelected: false,
                  onTap: () => context.push('/therapist/bookings'),
                ),
              ),
              Expanded(child: _buildCenterButton(context)),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.people_rounded,
                  label: strings.patientsLabel,
                  isSelected: false,
                  onTap: () => context.push(AppRoutes.therapistPatients),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.person_outline_rounded,
                  label: strings.profile,
                  isSelected: false,
                  onTap: () => context.push(AppRoutes.therapistSettings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/therapist/messages'),
      child: Transform.translate(
        offset: const Offset(0, -24),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
            border: Border.all(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              width: 4,
            ),
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    TherapistDashboardNotifier notifier,
    String bookingId,
    S strings,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.rejectBooking),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.rejectBookingConfirm),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: strings.reason,
                hintText: strings.optionalReason,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.rejectBooking(bookingId, reasonController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(strings.reject),
          ),
        ],
      ),
    );
  }

  /// Build KPI section with real Firebase data
  Widget _buildKPISection(
    WidgetRef ref,
    TherapistDashboardState state,
    S strings,
  ) {
    final kpiMetricsAsync = ref.watch(therapistKPIMetricsProvider);

    return kpiMetricsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (metrics) {
        // Calculate percentage changes from trend data
        final ratingChange = metrics.ratingTrend.length >= 2
            ? ((metrics.ratingTrend.last - metrics.ratingTrend.first) /
                  metrics.ratingTrend.first *
                  100)
            : 0.0;

        final responseChange = metrics.responseTrend.length >= 2
            ? ((metrics.responseTrend.last - metrics.responseTrend.first) /
                  metrics.responseTrend.first *
                  100)
            : 0.0;

        final completionChange = metrics.completionTrend.length >= 2
            ? ((metrics.completionTrend.last - metrics.completionTrend.first) /
                  metrics.completionTrend.first *
                  100)
            : 0.0;

        final rebookingChange = metrics.rebookingTrend.length >= 2
            ? ((metrics.rebookingTrend.last - metrics.rebookingTrend.first) /
                  metrics.rebookingTrend.first *
                  100)
            : 0.0;

        return KPISparklineRow(
          kpiData: [
            KPIData(
              label: strings.avgRating,
              value: metrics.avgRating > 0
                  ? metrics.avgRating.toStringAsFixed(1)
                  : 'N/A',
              percentageChange: ratingChange,
              trendData: metrics.ratingTrend.isNotEmpty
                  ? metrics.ratingTrend
                  : [0],
              icon: Icons.star_rounded,
              color: const Color(0xFFF59E0B),
            ),
            KPIData(
              label: strings.responseTime,
              value: metrics.avgResponseMinutes > 0
                  ? '${metrics.avgResponseMinutes.toStringAsFixed(1)}m'
                  : 'N/A',
              percentageChange: responseChange,
              trendData: metrics.responseTrend.isNotEmpty
                  ? metrics.responseTrend
                  : [0],
              icon: Icons.access_time_rounded,
              color: const Color(0xFF06B6D4),
            ),
            KPIData(
              label: strings.completion,
              value: metrics.completionRate > 0
                  ? '${metrics.completionRate.toStringAsFixed(0)}%'
                  : 'N/A',
              percentageChange: completionChange,
              trendData: metrics.completionTrend.isNotEmpty
                  ? metrics.completionTrend
                  : [0],
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
            ),
            KPIData(
              label: strings.rebooking,
              value: metrics.rebookingRate > 0
                  ? '${metrics.rebookingRate.toStringAsFixed(0)}%'
                  : 'N/A',
              percentageChange: rebookingChange,
              trendData: metrics.rebookingTrend.isNotEmpty
                  ? metrics.rebookingTrend
                  : [0],
              icon: Icons.refresh_rounded,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        );
      },
    );
  }

  /// Build session volume chart with real Firebase data
  Widget _buildSessionVolumeChart(WidgetRef ref) {
    final sessionVolumeAsync = ref.watch(
      sessionVolumeDataProvider(_sessionVolumePeriod),
    );

    return sessionVolumeAsync.when(
      loading: () => const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        return SessionVolumeChart(
          data: data,
          selectedPeriod: _sessionVolumePeriod,
          onPeriodChanged: (period) {
            setState(() => _sessionVolumePeriod = period);
          },
        );
      },
    );
  }

  /// Build earnings chart with real Firebase data
  Widget _buildEarningsChart(WidgetRef ref) {
    final earningsAsync = ref.watch(earningsDataProvider(_earningsPeriod));

    return earningsAsync.when(
      loading: () => const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        return EarningsChart(
          data: data,
          selectedPeriod: _earningsPeriod,
          currency: 'SAR',
          onPeriodChanged: (period) {
            setState(() => _earningsPeriod = period);
          },
        );
      },
    );
  }

  /// Build patient distribution chart with real Firebase data
  Widget _buildDistributionChart(WidgetRef ref) {
    final distributionAsync = ref.watch(
      patientDistributionDataProvider(_distributionCategory),
    );

    return distributionAsync.when(
      loading: () => const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        return PatientDistributionChart(
          data: data,
          selectedCategory: _distributionCategory,
          onCategoryChanged: (category) {
            setState(() => _distributionCategory = category);
          },
        );
      },
    );
  }
}
