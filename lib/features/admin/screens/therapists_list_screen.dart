import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../providers/admin_therapist_provider.dart';
import '../widgets/therapist_form_dialog.dart';
import '../../therapist_portal/models/therapist_profile.dart';

// Filter state provider
final therapistsFilterProvider = StateProvider<TherapistsFilter>(
  (ref) => TherapistsFilter(),
);

class TherapistsFilter {
  final String searchQuery;
  final String? specialtyFilter;
  final bool? availableOnly;

  TherapistsFilter({
    this.searchQuery = '',
    this.specialtyFilter,
    this.availableOnly,
  });

  TherapistsFilter copyWith({
    String? searchQuery,
    String? specialtyFilter,
    bool? availableOnly,
    bool clearSpecialty = false,
    bool clearAvailable = false,
  }) {
    return TherapistsFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      specialtyFilter: clearSpecialty
          ? null
          : (specialtyFilter ?? this.specialtyFilter),
      availableOnly: clearAvailable
          ? null
          : (availableOnly ?? this.availableOnly),
    );
  }
}

class TherapistsListScreen extends ConsumerStatefulWidget {
  const TherapistsListScreen({super.key});

  @override
  ConsumerState<TherapistsListScreen> createState() =>
      _TherapistsListScreenState();
}

class _TherapistsListScreenState extends ConsumerState<TherapistsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(adminTherapistProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminTherapistProvider);
    final filter = ref.watch(therapistsFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        _buildTherapistsView(
                          _filterTherapists(state.pendingTherapists, filter),
                          isDark,
                          'pending',
                        ),
                        _buildTherapistsView(
                          _filterTherapists(state.approvedTherapists, filter),
                          isDark,
                          'approved',
                        ),
                        _buildTherapistsView(
                          _filterTherapists(state.rejectedTherapists, filter),
                          isDark,
                          'rejected',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<TherapistProfile> _filterTherapists(
    List<TherapistProfile> therapists,
    TherapistsFilter filter,
  ) {
    return therapists.where((therapist) {
      // Search filter
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final nameMatch = therapist.name.toLowerCase().contains(query);
        final titleMatch =
            therapist.title?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !titleMatch) return false;
      }

      // Specialty filter
      if (filter.specialtyFilter != null) {
        final hasSpecialty = therapist.specialties.any(
          (s) => s.name.toLowerCase() == filter.specialtyFilter,
        );
        if (!hasSpecialty) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildHeader(bool isDark, AdminTherapistState state) {
    final isMobile = AdminResponsive.isMobile(context);
    final totalCount = state.therapists.length;
    final approvedCount = state.approvedTherapists.length;
    final pendingCount = state.pendingTherapists.length;

    final titleAndStats = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.adminClinicians,
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
              '$totalCount total',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            _StatDot(
              label: '$approvedCount active',
              color: AppColors.statusSuccess,
            ),
            _StatDot(
              label: '$pendingCount pending',
              color: AppColors.statusWarning,
            ),
          ],
        ),
      ],
    );

    final actions = Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
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
                icon: Icons.grid_view_rounded,
                isActive: _isGridView,
                isDark: isDark,
                onTap: () => setState(() => _isGridView = true),
              ),
              _ViewToggleButton(
                icon: Icons.list_rounded,
                isActive: !_isGridView,
                isDark: isDark,
                onTap: () => setState(() => _isGridView = false),
              ),
            ],
          ),
        ),
        _ActionButton(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          isDark: isDark,
          onPressed: () =>
              ref.read(adminTherapistProvider.notifier).refresh(),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Add Therapist'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => TherapistFormDialog(
                onSaved: (profile) async {
                  final adminId =
                      FirebaseAuth.instance.currentUser?.uid ?? '';
                  try {
                    await ref
                        .read(adminTherapistProvider.notifier)
                        .createTherapist(profile, adminId);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '"${profile.name}" created. They need admin approval before appearing to users.',
                        ),
                        backgroundColor: AppColors.statusWarning,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to create therapist: $e'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleAndStats,
          const SizedBox(height: 12),
          actions,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleAndStats),
        actions,
      ],
    );
  }

  Widget _buildSearchAndFilters(bool isDark, TherapistsFilter filter) {
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
                ref.read(therapistsFilterProvider.notifier).state = filter
                    .copyWith(searchQuery: value);
              },
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search clinicians by name or specialty...',
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
                          ref.read(therapistsFilterProvider.notifier).state =
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
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Specialty',
                  value: filter.specialtyFilter,
                  isDark: isDark,
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All Specialties'),
                    ),
                    DropdownMenuItem(value: 'anxiety', child: Text('Anxiety')),
                    DropdownMenuItem(
                      value: 'depression',
                      child: Text('Depression'),
                    ),
                    DropdownMenuItem(value: 'trauma', child: Text('Trauma')),
                    DropdownMenuItem(
                      value: 'relationships',
                      child: Text('Relationships'),
                    ),
                    DropdownMenuItem(
                      value: 'stress',
                      child: Text('Stress Management'),
                    ),
                  ],
                  onChanged: (value) {
                    ref
                        .read(therapistsFilterProvider.notifier)
                        .state = value == null
                        ? filter.copyWith(clearSpecialty: true)
                        : filter.copyWith(specialtyFilter: value);
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
                ref.read(therapistsFilterProvider.notifier).state = filter
                    .copyWith(searchQuery: value);
              },
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search clinicians by name or specialty...',
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
                          ref.read(therapistsFilterProvider.notifier).state =
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

        // Specialty Filter
        _FilterDropdown(
          label: 'Specialty',
          value: filter.specialtyFilter,
          isDark: isDark,
          items: const [
            DropdownMenuItem(value: null, child: Text('All Specialties')),
            DropdownMenuItem(value: 'anxiety', child: Text('Anxiety')),
            DropdownMenuItem(value: 'depression', child: Text('Depression')),
            DropdownMenuItem(value: 'trauma', child: Text('Trauma')),
            DropdownMenuItem(
              value: 'relationships',
              child: Text('Relationships'),
            ),
            DropdownMenuItem(value: 'stress', child: Text('Stress Management')),
          ],
          onChanged: (value) {
            ref.read(therapistsFilterProvider.notifier).state = value == null
                ? filter.copyWith(clearSpecialty: true)
                : filter.copyWith(specialtyFilter: value);
          },
        ),
      ],
    );
  }

  Widget _buildTabs(bool isDark, AdminTherapistState state) {
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
            label: 'Pending Review',
            count: state.pendingTherapists.length,
            color: AppColors.statusWarning,
          ),
          _TabWithBadge(
            label: 'Approved',
            count: state.approvedTherapists.length,
            color: AppColors.statusSuccess,
          ),
          _TabWithBadge(
            label: 'Rejected',
            count: state.rejectedTherapists.length,
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
            'Error loading clinicians',
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
            onPressed: () =>
                ref.read(adminTherapistProvider.notifier).refresh(),
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

  Widget _buildTherapistsView(
    List<TherapistProfile> therapists,
    bool isDark,
    String status,
  ) {
    if (therapists.isEmpty) {
      return _buildEmptyState(isDark, status);
    }

    if (_isGridView) {
      return _buildGridView(therapists, isDark, status);
    } else {
      return _buildListView(therapists, isDark, status);
    }
  }

  Widget _buildEmptyState(bool isDark, String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'pending':
        message = 'No pending applications';
        icon = Icons.pending_actions_rounded;
        break;
      case 'rejected':
        message = 'No rejected applications';
        icon = Icons.block_rounded;
        break;
      default:
        message = 'No clinicians found';
        icon = Icons.medical_services_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? AppColors.adminTextSecondary : AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
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

  Widget _buildGridView(
    List<TherapistProfile> therapists,
    bool isDark,
    String status,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 900
            ? 3
            : 2;

        return GridView.builder(
          padding: const EdgeInsets.only(top: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: status == 'pending'
                ? 360
                : 280, // Fixed height prevents overflow
          ),
          itemCount: therapists.length,
          itemBuilder: (context, index) {
            final therapist = therapists[index];
            return _TherapistCard(
              therapist: therapist,
              isDark: isDark,
              status: status,
              onTap: () =>
                  context.pushNamed('adminTherapistDetail', extra: therapist),
              onApprove: status == 'pending'
                  ? () => _handleApprove(therapist)
                  : null,
              onReject: status == 'pending'
                  ? () => _handleReject(therapist)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildListView(
    List<TherapistProfile> therapists,
    bool isDark,
    String status,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: ListView.separated(
        itemCount: therapists.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
        itemBuilder: (context, index) {
          final therapist = therapists[index];
          return _TherapistListItem(
            therapist: therapist,
            isDark: isDark,
            status: status,
            onTap: () =>
                context.pushNamed('adminTherapistDetail', extra: therapist),
            onApprove: status == 'pending'
                ? () => _handleApprove(therapist)
                : null,
            onReject: status == 'pending'
                ? () => _handleReject(therapist)
                : null,
          );
        },
      ),
    );
  }

  void _handleApprove(TherapistProfile therapist) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Admin not authenticated'),
            backgroundColor: AppColors.statusDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await ref
        .read(adminTherapistProvider.notifier)
        .approveTherapist(therapist.id, adminId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${therapist.name} has been approved'),
          backgroundColor: AppColors.statusSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleReject(TherapistProfile therapist) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error: Admin not authenticated'),
            backgroundColor: AppColors.statusDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    const reason = 'Admin decision'; // Placeholder

    await ref
        .read(adminTherapistProvider.notifier)
        .rejectTherapist(therapist.id, reason, adminId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${therapist.name} has been rejected'),
          backgroundColor: AppColors.statusDanger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Therapist Card Widget (Grid View)
class _TherapistCard extends StatelessWidget {
  final TherapistProfile therapist;
  final bool isDark;
  final String status;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _TherapistCard({
    required this.therapist,
    required this.isDark,
    required this.status,
    required this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with status indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        (therapist.photoUrl != null &&
                            therapist.photoUrl!.isNotEmpty)
                        ? NetworkImage(therapist.photoUrl!)
                        : null,
                    child:
                        (therapist.photoUrl == null ||
                            therapist.photoUrl!.isEmpty)
                        ? Text(
                            therapist.name.isNotEmpty
                                ? therapist.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.adminBackground
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Name and Title inside Flexible to prevent overflow
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      therapist.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      therapist.title ?? 'Mental Health Professional',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.adminTextSecondary
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    if (therapist.specialties.isNotEmpty)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: therapist.specialties
                            .take(2)
                            .map(
                              (spec) => _SpecialtyChip(
                                label: spec.name,
                                isDark: isDark,
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatItem(
                    icon: Icons.payments_outlined,
                    value: '${therapist.sessionPrice}',
                    label: 'Session',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 16),
                  _StatItem(
                    icon: Icons.star_outline,
                    value: '${therapist.rating.toStringAsFixed(1)}',
                    label: 'Rating',
                    isDark: isDark,
                  ),
                ],
              ),

              if (status == 'pending' &&
                  onApprove != null &&
                  onReject != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusDanger,
                          side: const BorderSide(color: AppColors.statusDanger),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusSuccess,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'approved':
        return AppColors.statusSuccess;
      case 'rejected':
        return AppColors.statusDanger;
      default:
        return AppColors.statusWarning;
    }
  }
}

// Therapist List Item Widget (List View)
class _TherapistListItem extends StatelessWidget {
  final TherapistProfile therapist;
  final bool isDark;
  final String status;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _TherapistListItem({
    required this.therapist,
    required this.isDark,
    required this.status,
    required this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        (therapist.photoUrl != null &&
                            therapist.photoUrl!.isNotEmpty)
                        ? NetworkImage(therapist.photoUrl!)
                        : null,
                    child:
                        (therapist.photoUrl == null ||
                            therapist.photoUrl!.isEmpty)
                        ? Text(
                            therapist.name.isNotEmpty
                                ? therapist.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: status == 'approved'
                            ? AppColors.statusSuccess
                            : status == 'rejected'
                            ? AppColors.statusDanger
                            : AppColors.statusWarning,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.adminBackground
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      therapist.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      therapist.title ?? 'Mental Health Professional',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.adminTextSecondary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Specializations
              if (therapist.specialties.isNotEmpty)
                Flexible(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: therapist.specialties
                        .take(2)
                        .map(
                          (spec) => Chip(
                            label: Text(spec.name),
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            labelStyle: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(width: 16),

              // Rating
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.statusWarning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    therapist.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Actions
              if (status == 'pending' && onApprove != null && onReject != null)
                Row(
                  children: [
                    IconButton(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.statusDanger,
                      tooltip: 'Reject',
                    ),
                    IconButton(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded),
                      color: AppColors.statusSuccess,
                      tooltip: 'Approve',
                    ),
                  ],
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Specialty Chip Widget
class _SpecialtyChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SpecialtyChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.statusInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.statusInfo,
        ),
      ),
    );
  }
}

// Stat Item Widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Tab with Badge Widget
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

// View Toggle Button Widget
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

// Stat Dot Widget
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

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? AppColors.adminGlass.withValues(alpha: 0.5)
          : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.adminBorder : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.adminTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Filter Dropdown Widget
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
