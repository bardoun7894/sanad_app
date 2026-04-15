import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/admin_booking_provider.dart';
import '../../therapist_portal/models/therapist_booking.dart';
import '../../therapists/models/therapist.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive.dart';

// Filter state provider
final bookingsFilterProvider = StateProvider<BookingsFilter>(
  (ref) => BookingsFilter(),
);

class BookingsFilter {
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? sessionTypeFilter;

  BookingsFilter({
    this.searchQuery = '',
    this.startDate,
    this.endDate,
    this.sessionTypeFilter,
  });

  BookingsFilter copyWith({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? sessionTypeFilter,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearSessionType = false,
  }) {
    return BookingsFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      sessionTypeFilter: clearSessionType
          ? null
          : (sessionTypeFilter ?? this.sessionTypeFilter),
    );
  }
}

class BookingsListScreen extends ConsumerStatefulWidget {
  const BookingsListScreen({super.key});

  @override
  ConsumerState<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends ConsumerState<BookingsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isTableView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() => ref.read(adminBookingProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminBookingProvider);
    final filter = ref.watch(bookingsFilterProvider);
    final isDark = false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: AdminResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(isDark, state),
            const SizedBox(height: 24),

            // Search and Filters
            _buildSearchAndFilters(isDark, filter),
            const SizedBox(height: 20),

            // Tabs with counts
            _buildTabs(isDark, state),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                  ? _buildErrorState(state.error!, isDark)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBookingsView(
                          _filterBookings(
                            [
                              ...state.upcomingBookings,
                              ...state.completedBookings,
                              ...state.cancelledBookings,
                            ]..sort(
                              (a, b) =>
                                  b.scheduledTime.compareTo(a.scheduledTime),
                            ),
                            filter,
                          ),
                          isDark,
                        ),
                        _buildBookingsView(
                          _filterBookings(state.upcomingBookings, filter),
                          isDark,
                        ),
                        _buildBookingsView(
                          _filterBookings(state.completedBookings, filter),
                          isDark,
                        ),
                        _buildBookingsView(
                          _filterBookings(state.cancelledBookings, filter),
                          isDark,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<TherapistBooking> _filterBookings(
    List<TherapistBooking> bookings,
    BookingsFilter filter,
  ) {
    return bookings.where((booking) {
      // Search filter
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final clientMatch = booking.clientName.toLowerCase().contains(query);
        if (!clientMatch) return false;
      }

      // Date range filter
      if (filter.startDate != null) {
        if (booking.scheduledTime.isBefore(filter.startDate!)) return false;
      }
      if (filter.endDate != null) {
        if (booking.scheduledTime.isAfter(filter.endDate!)) return false;
      }

      // Session type filter
      if (filter.sessionTypeFilter != null) {
        if (booking.sessionType.firestoreValue != filter.sessionTypeFilter)
          return false;
      }

      return true;
    }).toList();
  }

  Widget _buildHeader(bool isDark, AdminBookingState state) {
    final isMobile = AdminResponsive.isMobile(context);
    final totalBookings = state.bookings.length;
    final upcomingCount = state.upcomingBookings.length;
    final todayCount = state.bookings.where((b) {
      final today = DateTime.now();
      return b.scheduledTime.year == today.year &&
          b.scheduledTime.month == today.month &&
          b.scheduledTime.day == today.day;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.adminAppointments,
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '$totalBookings total',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            _StatDot(label: '$todayCount today', color: AppColors.statusInfo),
            _StatDot(
              label: '$upcomingCount upcoming',
              color: AppColors.statusSuccess,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.adminGlass.withValues(alpha: 0.3)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.adminBorder : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ViewToggleButton(
                    icon: Icons.table_chart_outlined,
                    isActive: _isTableView,
                    isDark: isDark,
                    onTap: () => setState(() => _isTableView = true),
                  ),
                  _ViewToggleButton(
                    icon: Icons.view_agenda_outlined,
                    isActive: !_isTableView,
                    isDark: isDark,
                    onTap: () => setState(() => _isTableView = false),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: AppStrings.adminNewBookingComingSoon,
              child: _ActionButton(
                icon: Icons.add_rounded,
                label: AppStrings.adminNewBooking,
                isPrimary: true,
                isDark: isDark,
                onPressed: null,
                isDisabled: true,
              ),
            ),
            _ActionButton(
              icon: Icons.refresh_rounded,
              label: AppStrings.adminRefresh,
              isDark: isDark,
              onPressed: () =>
                  ref.read(adminBookingProvider.notifier).refresh(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(bool isDark, BookingsFilter filter) {
    final isMobile = AdminResponsive.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.adminGlass.withValues(alpha: 0.3)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.adminBorder : AppColors.border,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(bookingsFilterProvider.notifier).state = filter
                    .copyWith(searchQuery: value);
              },
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search by client name...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: filter.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(bookingsFilterProvider.notifier).state =
                              filter.copyWith(searchQuery: '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DateRangeButton(
            isDark: isDark,
            startDate: filter.startDate,
            endDate: filter.endDate,
            onDateRangeSelected: (start, end) {
              ref.read(bookingsFilterProvider.notifier).state = filter.copyWith(
                startDate: start,
                endDate: end,
              );
            },
            onClear: () {
              ref.read(bookingsFilterProvider.notifier).state = filter.copyWith(
                clearStartDate: true,
                clearEndDate: true,
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Type',
                  value: filter.sessionTypeFilter,
                  isDark: isDark,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'chat', child: Text('Chat')),
                    DropdownMenuItem(
                      value: 'in_person',
                      child: Text('In Person'),
                    ),
                  ],
                  onChanged: (value) {
                    ref
                        .read(bookingsFilterProvider.notifier)
                        .state = value == null
                        ? filter.copyWith(clearSessionType: true)
                        : filter.copyWith(sessionTypeFilter: value);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        // Search Bar
        Expanded(
          flex: 2,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.adminGlass.withValues(alpha: 0.3)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.adminBorder : AppColors.border,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(bookingsFilterProvider.notifier).state = filter
                    .copyWith(searchQuery: value);
              },
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search by client name...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textMuted,
                  size: 20,
                ),
                suffixIcon: filter.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(bookingsFilterProvider.notifier).state =
                              filter.copyWith(searchQuery: '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Date Range Picker
        _DateRangeButton(
          isDark: isDark,
          startDate: filter.startDate,
          endDate: filter.endDate,
          onDateRangeSelected: (start, end) {
            ref.read(bookingsFilterProvider.notifier).state = filter.copyWith(
              startDate: start,
              endDate: end,
            );
          },
          onClear: () {
            ref.read(bookingsFilterProvider.notifier).state = filter.copyWith(
              clearStartDate: true,
              clearEndDate: true,
            );
          },
        ),
        const SizedBox(width: 12),

        // Session Type Filter
        _FilterDropdown(
          label: 'Type',
          value: filter.sessionTypeFilter,
          isDark: isDark,
          items: const [
            DropdownMenuItem(value: null, child: Text('All Types')),
            DropdownMenuItem(value: 'video', child: Text('Video')),
            DropdownMenuItem(value: 'chat', child: Text('Chat')),
            DropdownMenuItem(value: 'in_person', child: Text('In Person')),
          ],
          onChanged: (value) {
            ref.read(bookingsFilterProvider.notifier).state = value == null
                ? filter.copyWith(clearSessionType: true)
                : filter.copyWith(sessionTypeFilter: value);
          },
        ),
      ],
    );
  }

  Widget _buildTabs(bool isDark, AdminBookingState state) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark
            ? AppColors.adminTextSecondary
            : AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          _TabWithBadge(
            label: 'All',
            count: state.bookings.length,
            color: AppColors.primary,
          ),
          _TabWithBadge(
            label: 'Upcoming',
            count: state.upcomingBookings.length,
            color: AppColors.statusInfo,
          ),
          _TabWithBadge(
            label: 'Completed',
            count: state.completedBookings.length,
            color: AppColors.statusSuccess,
          ),
          _TabWithBadge(
            label: 'Cancelled',
            count: state.cancelledBookings.length,
            color: AppColors.statusDanger,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.statusDanger,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading appointments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(adminBookingProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsView(List<TherapistBooking> bookings, bool isDark) {
    if (bookings.isEmpty) {
      return _buildEmptyState(isDark);
    }

    if (_isTableView) {
      return _buildTableView(bookings, isDark);
    } else {
      return _buildCardView(bookings, isDark);
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: isDark ? AppColors.adminTextSecondary : AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.adminNoAppointmentsFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.adminAdjustFilters,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(List<TherapistBooking> bookings, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableMinWidth = constraints.maxWidth < 700
            ? 700.0
            : constraints.maxWidth;
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
            children: [
              // Table Header
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableMinWidth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.adminSurface.withValues(alpha: 0.5)
                          : AppColors.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusLg - 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        _TableHeader('Client', flex: 2, isDark: isDark),
                        _TableHeader('Type', flex: 1, isDark: isDark),
                        _TableHeader('Date & Time', flex: 2, isDark: isDark),
                        _TableHeader('Status', flex: 1, isDark: isDark),
                        _TableHeader(
                          'Actions',
                          flex: 1,
                          isDark: isDark,
                          centered: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? AppColors.adminBorder : AppColors.borderLight,
              ),

              // Table Body
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableMinWidth,
                    child: ListView.separated(
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.adminBorder
                            : AppColors.borderLight,
                      ),
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return _BookingRow(
                          booking: booking,
                          isDark: isDark,
                          onTap: () => _showBookingDetails(booking),
                          onCancel:
                              booking.status == BookingStatus.pending ||
                                  booking.status == BookingStatus.confirmed
                              ? () => _handleCancelBooking(booking)
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardView(List<TherapistBooking> bookings, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _BookingCard(
            booking: booking,
            isDark: isDark,
            onTap: () => _showBookingDetails(booking),
            onCancel:
                booking.status == BookingStatus.pending ||
                    booking.status == BookingStatus.confirmed
                ? () => _handleCancelBooking(booking)
                : null,
          ),
        );
      },
    );
  }

  // New booking feature removed - button is disabled with tooltip

  void _showBookingDetails(TherapistBooking booking) {
    final isDark = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _BookingDetailSheet(booking: booking, isDark: isDark),
    );
  }

  void _handleCancelBooking(TherapistBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
          'Are you sure you want to cancel the appointment with ${booking.clientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(adminBookingProvider.notifier)
          .cancelBooking(booking.id, 'Cancelled by admin');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled'),
            backgroundColor: AppColors.statusDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Table Header Widget
class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;
  final bool isDark;
  final bool centered;

  const _TableHeader(
    this.label, {
    required this.flex,
    required this.isDark,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: centered ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.adminTextSecondary
              : AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Booking Row Widget
class _BookingRow extends StatelessWidget {
  final TherapistBooking booking;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _BookingRow({
    required this.booking,
    required this.isDark,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Client Info
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getSessionTypeColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getSessionTypeIcon(),
                        size: 18,
                        color: _getSessionTypeColor(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        booking.clientName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Type
              Expanded(
                flex: 1,
                child: Text(
                  booking.sessionType.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getSessionTypeColor(),
                  ),
                ),
              ),

              // Date & Time
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        dateFormat.format(booking.scheduledTime),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.adminTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        timeFormat.format(booking.scheduledTime),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status
              Expanded(flex: 1, child: _StatusBadge(status: booking.status)),

              // Actions
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: isDark
                            ? AppColors.adminTextSecondary
                            : AppColors.textSecondary,
                      ),
                      onPressed: onTap,
                      tooltip: 'View Details',
                    ),
                    if (onCancel != null)
                      IconButton(
                        icon: const Icon(
                          Icons.cancel_outlined,
                          size: 18,
                          color: AppColors.statusDanger,
                        ),
                        onPressed: onCancel,
                        tooltip: 'Cancel',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSessionTypeIcon() {
    switch (booking.sessionType) {
      case SessionType.chat:
        return Icons.chat_bubble_outline_rounded;
      case SessionType.audio:
        return Icons.phone_rounded;
      case SessionType.inPerson:
        return Icons.person_outline_rounded;
    }
  }

  Color _getSessionTypeColor() {
    switch (booking.sessionType) {
      case SessionType.chat:
        return AppColors.primary;
      case SessionType.audio:
        return Colors.orange;
      case SessionType.inPerson:
        return AppColors.statusSuccess;
    }
  }
}

// Booking Card Widget
class _BookingCard extends StatelessWidget {
  final TherapistBooking booking;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _BookingCard({
    required this.booking,
    required this.isDark,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Material(
      color: isDark
          ? AppColors.adminGlass.withValues(alpha: 0.3)
          : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.adminBorder : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getSessionTypeColor().withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getSessionTypeIcon(),
                            size: 20,
                            color: _getSessionTypeColor(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.clientName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              booking.sessionType.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getSessionTypeColor(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(booking.scheduledTime),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.adminTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(booking.scheduledTime),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              // Notes or Cancellation Reason
              if (booking.notes != null || booking.cancellationReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.adminSurface.withValues(alpha: 0.5)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (booking.notes != null)
                          Text(
                            'Notes: ${booking.notes}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.adminTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        if (booking.cancellationReason != null) ...[
                          if (booking.notes != null) const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 14,
                                color: AppColors.statusDanger,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Cancellation: ${booking.cancellationReason}',
                                  style: const TextStyle(
                                    color: AppColors.statusDanger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Actions
              if (onCancel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusDanger,
                          side: const BorderSide(color: AppColors.statusDanger),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSessionTypeIcon() {
    switch (booking.sessionType) {
      case SessionType.chat:
        return Icons.chat_bubble_outline_rounded;
      case SessionType.audio:
        return Icons.phone_rounded;
      case SessionType.inPerson:
        return Icons.person_outline_rounded;
    }
  }

  Color _getSessionTypeColor() {
    switch (booking.sessionType) {
      case SessionType.chat:
        return AppColors.primary;
      case SessionType.audio:
        return Colors.orange;
      case SessionType.inPerson:
        return AppColors.statusSuccess;
    }
  }
}

// Status Badge Widget
class _StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BookingStatus.confirmed:
        color = AppColors.statusSuccess;
        break;
      case BookingStatus.pending:
        color = AppColors.statusWarning;
        break;
      case BookingStatus.completed:
        color = AppColors.statusInfo;
        break;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
      case BookingStatus.noShow:
        color = AppColors.statusDanger;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// Booking Detail Sheet
class _BookingDetailSheet extends StatelessWidget {
  final TherapistBooking booking;
  final bool isDark;

  const _BookingDetailSheet({required this.booking, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getSessionTypeIcon(),
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.clientName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${booking.sessionType.name.toUpperCase()} Session',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: dateFormat.format(booking.scheduledTime),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: timeFormat.format(booking.scheduledTime),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Status',
                  value: booking.status.name.toUpperCase(),
                  valueColor: _getStatusColor(booking.status),
                  isDark: isDark,
                ),
                if (booking.notes != null) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.note_alt_outlined,
                    label: 'Notes',
                    value: booking.notes!,
                    isDark: isDark,
                  ),
                ],
                if (booking.cancellationReason != null) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.cancel_outlined,
                    label: 'Cancellation Reason',
                    value: booking.cancellationReason!,
                    valueColor: AppColors.statusDanger,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSessionTypeIcon() {
    switch (booking.sessionType) {
      case SessionType.chat:
        return Icons.chat_bubble_outline_rounded;
      case SessionType.audio:
        return Icons.phone_rounded;
      case SessionType.inPerson:
        return Icons.person_outline_rounded;
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppColors.statusSuccess;
      case BookingStatus.pending:
        return AppColors.statusWarning;
      case BookingStatus.completed:
        return AppColors.statusInfo;
      case BookingStatus.cancelled:
      case BookingStatus.rejected:
      case BookingStatus.noShow:
        return AppColors.statusDanger;
    }
  }
}

// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? AppColors.adminTextSecondary
              : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      valueColor ??
                      (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Helper Widgets
class _StatDot extends StatelessWidget {
  final String label;
  final Color color;

  const _StatDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive
              ? AppColors.primary
              : (isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isPrimary;
  final VoidCallback? onPressed;
  final bool isDisabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isPrimary = false,
    this.onPressed,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? AppColors.primary
          : (isDark
                ? AppColors.adminGlass.withValues(alpha: 0.5)
                : Colors.white),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: isPrimary
                  ? null
                  : Border.all(
                      color: isDark ? AppColors.adminBorder : AppColors.border,
                    ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isPrimary
                      ? Colors.white
                      : (isDark
                            ? AppColors.adminTextSecondary
                            : AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isPrimary
                        ? Colors.white
                        : (isDark
                              ? AppColors.adminTextPrimary
                              : AppColors.textPrimary),
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

class _TabWithBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TabWithBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final bool isDark;
  final List<DropdownMenuItem<String?>> items;
  final Function(String?) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.isDark,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textMuted,
            ),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? AppColors.adminTextSecondary : AppColors.textMuted,
          ),
          dropdownColor: isDark ? AppColors.adminSurface : Colors.white,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final bool isDark;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDateRangeSelected;
  final VoidCallback onClear;

  const _DateRangeButton({
    required this.isDark,
    this.startDate,
    this.endDate,
    required this.onDateRangeSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasDateRange = startDate != null || endDate != null;
    final dateFormat = DateFormat('MMM dd');

    return Material(
      color: isDark
          ? AppColors.adminGlass.withValues(alpha: 0.3)
          : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: () => _showDateRangePicker(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.adminBorder : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 18,
                color: hasDateRange
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Text(
                hasDateRange
                    ? '${startDate != null ? dateFormat.format(startDate!) : 'Start'} - ${endDate != null ? dateFormat.format(endDate!) : 'End'}'
                    : 'Date Range',
                style: TextStyle(
                  fontSize: 13,
                  color: hasDateRange
                      ? (isDark ? Colors.white : AppColors.textPrimary)
                      : (isDark
                            ? AppColors.adminTextSecondary
                            : AppColors.textMuted),
                ),
              ),
              if (hasDateRange) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeSelected(picked.start, picked.end);
    }
  }
}
