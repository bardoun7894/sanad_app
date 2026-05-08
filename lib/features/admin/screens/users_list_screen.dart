import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../providers/admin_users_provider.dart';
import '../../subscription/models/subscription_product.dart';
import '../services/admin_chat_service.dart';

// Filter state provider
final usersFilterProvider = StateProvider<UsersFilter>((ref) => UsersFilter());

class UsersFilter {
  final String searchQuery;
  final String? roleFilter;
  final String? statusFilter;
  final String? riskFilter;

  UsersFilter({
    this.searchQuery = '',
    this.roleFilter,
    this.statusFilter,
    this.riskFilter,
  });

  UsersFilter copyWith({
    String? searchQuery,
    String? roleFilter,
    String? statusFilter,
    String? riskFilter,
    bool clearRole = false,
    bool clearStatus = false,
    bool clearRisk = false,
  }) {
    return UsersFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: clearRole ? null : (roleFilter ?? this.roleFilter),
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      riskFilter: clearRisk ? null : (riskFilter ?? this.riskFilter),
    );
  }
}

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUsersProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    final filter = ref.watch(usersFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter users based on search and filters
    final filteredUsers = state.users.where((user) {
      // Search filter
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final nameMatch =
            user.displayName?.toLowerCase().contains(query) ?? false;
        final emailMatch = user.email.toLowerCase().contains(query);
        if (!nameMatch && !emailMatch) return false;
      }

      // Role filter
      if (filter.roleFilter != null && user.role != filter.roleFilter) {
        return false;
      }

      // Status filter
      if (filter.statusFilter != null) {
        if (filter.statusFilter == 'premium' && !user.isPremium) return false;
        if (filter.statusFilter == 'free' && user.isPremium) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: AdminResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(isDark, state.users.length, filteredUsers.length),
            const SizedBox(height: 24),

            // Search and Filter Bar
            _buildSearchAndFilters(isDark, filter),
            const SizedBox(height: 16),

            // Filter Chips
            _buildFilterChips(isDark, filter),
            const SizedBox(height: 16),

            // Error View
            if (state.error != null) _buildErrorBanner(state.error!),

            // Users Table
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildUsersTable(isDark, filteredUsers),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, int totalCount, int filteredCount) {
    final isMobile = AdminResponsive.isMobile(context);

    final titleAndStats = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.adminUsers,
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$filteredCount of $totalCount users',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: AppStrings.adminExportComingSoon,
          child: _ActionButton(
            icon: Icons.file_download_outlined,
            label: AppStrings.adminExport,
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
              ref.read(adminUsersProvider.notifier).loadUsers(),
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

  Widget _buildSearchAndFilters(bool isDark, UsersFilter filter) {
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
                ref.read(usersFilterProvider.notifier).state = filter.copyWith(
                  searchQuery: value,
                );
              },
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
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
                          ref.read(usersFilterProvider.notifier).state = filter
                              .copyWith(searchQuery: '');
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
                  label: 'Role',
                  value: filter.roleFilter,
                  isDark: isDark,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Roles')),
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(
                      value: 'therapist',
                      child: Text('Therapist'),
                    ),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    ref.read(usersFilterProvider.notifier).state = value == null
                        ? filter.copyWith(clearRole: true)
                        : filter.copyWith(roleFilter: value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterDropdown(
                  label: 'Status',
                  value: filter.statusFilter,
                  isDark: isDark,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Status')),
                    DropdownMenuItem(value: 'premium', child: Text('Premium')),
                    DropdownMenuItem(value: 'free', child: Text('Free')),
                  ],
                  onChanged: (value) {
                    ref.read(usersFilterProvider.notifier).state = value == null
                        ? filter.copyWith(clearStatus: true)
                        : filter.copyWith(statusFilter: value);
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
                ref.read(usersFilterProvider.notifier).state = filter.copyWith(
                  searchQuery: value,
                );
              },
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
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
                          ref.read(usersFilterProvider.notifier).state = filter
                              .copyWith(searchQuery: '');
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
        _FilterDropdown(
          label: 'Role',
          value: filter.roleFilter,
          isDark: isDark,
          items: const [
            DropdownMenuItem(value: null, child: Text('All Roles')),
            DropdownMenuItem(value: 'user', child: Text('User')),
            DropdownMenuItem(value: 'therapist', child: Text('Therapist')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: (value) {
            ref.read(usersFilterProvider.notifier).state = value == null
                ? filter.copyWith(clearRole: true)
                : filter.copyWith(roleFilter: value);
          },
        ),
        const SizedBox(width: 12),
        _FilterDropdown(
          label: 'Status',
          value: filter.statusFilter,
          isDark: isDark,
          items: const [
            DropdownMenuItem(value: null, child: Text('All Status')),
            DropdownMenuItem(value: 'premium', child: Text('Premium')),
            DropdownMenuItem(value: 'free', child: Text('Free')),
          ],
          onChanged: (value) {
            ref.read(usersFilterProvider.notifier).state = value == null
                ? filter.copyWith(clearStatus: true)
                : filter.copyWith(statusFilter: value);
          },
        ),
      ],
    );
  }

  Widget _buildFilterChips(bool isDark, UsersFilter filter) {
    final hasFilters =
        filter.roleFilter != null ||
        filter.statusFilter != null ||
        filter.riskFilter != null ||
        filter.searchQuery.isNotEmpty;

    if (!hasFilters) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (filter.searchQuery.isNotEmpty)
          _FilterChip(
            label: 'Search: "${filter.searchQuery}"',
            isDark: isDark,
            onRemove: () {
              _searchController.clear();
              ref.read(usersFilterProvider.notifier).state = filter.copyWith(
                searchQuery: '',
              );
            },
          ),
        if (filter.roleFilter != null)
          _FilterChip(
            label: 'Role: ${filter.roleFilter}',
            isDark: isDark,
            onRemove: () {
              ref.read(usersFilterProvider.notifier).state = filter.copyWith(
                clearRole: true,
              );
            },
          ),
        if (filter.statusFilter != null)
          _FilterChip(
            label: 'Status: ${filter.statusFilter}',
            isDark: isDark,
            onRemove: () {
              ref.read(usersFilterProvider.notifier).state = filter.copyWith(
                clearStatus: true,
              );
            },
          ),
        TextButton.icon(
          onPressed: () {
            _searchController.clear();
            ref.read(usersFilterProvider.notifier).state = UsersFilter();
          },
          icon: const Icon(Icons.clear_all_rounded, size: 16),
          label: const Text('Clear all'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.statusDanger.withValues(alpha: 0.1),
        border: Border.all(
          color: AppColors.statusDanger.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusDanger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: AppColors.statusDanger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 64,
            color: isDark ? AppColors.adminTextSecondary : AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.adminNoUsersFound,
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

  Widget _buildUsersTable(bool isDark, List<AdminUser> users) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final tableMinWidth = constraints.maxWidth < 500
            ? constraints.maxWidth
            : (constraints.maxWidth < 700 ? 700.0 : constraints.maxWidth);
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
                        _TableHeader(
                          'Patient',
                          flex: isNarrow ? 2 : 3,
                          isDark: isDark,
                        ),
                        if (!isNarrow)
                          _TableHeader('Last Mood', flex: 1, isDark: isDark),
                        _TableHeader('Status', flex: 1, isDark: isDark),
                        _TableHeader('Role', flex: 1, isDark: isDark),
                        if (!isNarrow)
                          _TableHeader('Joined', flex: 1, isDark: isDark),
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
                      itemCount: users.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.adminBorder
                            : AppColors.borderLight,
                      ),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _UserRow(
                          user: user,
                          isDark: isDark,
                          onTap: () => context.push('/admin/users/${user.id}'),
                          onRoleChange: (newRole) => _showRoleConfirmDialog(
                            context,
                            ref,
                            user,
                            newRole,
                          ),
                          onTogglePremium: () =>
                              _showPremiumConfirmDialog(context, ref, user),
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

  // Export feature removed - button is disabled with tooltip

  void _showRoleConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
    String newRole,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.adminSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Change User Role',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to change ${user.displayName}\'s role to "$newRole"?',
          style: TextStyle(
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              ref
                  .read(adminUsersProvider.notifier)
                  .updateUserRole(user.id, newRole);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Role updated to $newRole'),
                  backgroundColor: AppColors.statusSuccess,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showPremiumConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) {
    if (user.isPremium) {
      // Show revoke dialog
      _showRevokeSubscriptionDialog(context, ref, user);
    } else {
      // Show subscription assignment dialog
      _showAssignSubscriptionDialog(context, ref, user);
    }
  }

  void _showAssignSubscriptionDialog(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SubscriptionProduct? selectedPlan;
    int customDays = 30;
    bool useCustomDuration = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? AppColors.adminSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.statusSuccess,
              ),
              const SizedBox(width: 8),
              Text(
                'Assign Subscription',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign a subscription plan to ${user.displayName ?? user.email}',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Plan:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Plan selection
                ...SubscriptionProduct.allProducts.map(
                  (plan) => _PlanOption(
                    plan: plan,
                    isSelected: selectedPlan?.id == plan.id,
                    isDark: isDark,
                    onTap: () => setState(() => selectedPlan = plan),
                  ),
                ),
                const SizedBox(height: 16),
                // Custom duration toggle
                Row(
                  children: [
                    Checkbox(
                      value: useCustomDuration,
                      onChanged: (value) =>
                          setState(() => useCustomDuration = value ?? false),
                      activeColor: AppColors.primary,
                    ),
                    Text(
                      'Custom Duration',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (useCustomDuration) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Days',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.adminGlass.withValues(alpha: 0.3)
                                : Colors.grey[100],
                          ),
                          onChanged: (value) {
                            customDays = int.tryParse(value) ?? 30;
                          },
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Quick duration buttons
                      _DurationChip(
                        label: '7d',
                        days: 7,
                        isDark: isDark,
                        onTap: () => setState(() => customDays = 7),
                      ),
                      const SizedBox(width: 8),
                      _DurationChip(
                        label: '30d',
                        days: 30,
                        isDark: isDark,
                        onTap: () => setState(() => customDays = 30),
                      ),
                      const SizedBox(width: 8),
                      _DurationChip(
                        label: '90d',
                        days: 90,
                        isDark: isDark,
                        onTap: () => setState(() => customDays = 90),
                      ),
                      const SizedBox(width: 8),
                      _DurationChip(
                        label: '365d',
                        days: 365,
                        isDark: isDark,
                        onTap: () => setState(() => customDays = 365),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusSuccess,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: selectedPlan == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final duration = useCustomDuration
                          ? customDays
                          : selectedPlan!.billingPeriodDays;
                      final success = await ref
                          .read(adminUsersProvider.notifier)
                          .assignSubscription(
                            userId: user.id,
                            planId: selectedPlan!.id,
                            planTitle: selectedPlan!.title,
                            durationDays: duration,
                            amount: selectedPlan!.price,
                            currency: selectedPlan!.currencyCode,
                          );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Subscription assigned: ${selectedPlan!.title} for $duration days'
                                  : 'Failed to assign subscription',
                            ),
                            backgroundColor: success
                                ? AppColors.statusSuccess
                                : AppColors.statusDanger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevokeSubscriptionDialog(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.adminSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.statusWarning),
            const SizedBox(width: 8),
            Text(
              'Revoke Subscription',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to revoke the subscription from ${user.displayName ?? user.email}?\n\nThey will lose access to all premium features immediately.',
          style: TextStyle(
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusWarning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(adminUsersProvider.notifier)
                  .revokeSubscription(user.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Subscription revoked'
                          : 'Failed to revoke subscription',
                    ),
                    backgroundColor: success
                        ? AppColors.statusSuccess
                        : AppColors.statusDanger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}

// Plan Option Widget
class _PlanOption extends StatelessWidget {
  final SubscriptionProduct plan;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanOption({
    required this.plan,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark
                    ? AppColors.adminGlass.withValues(alpha: 0.2)
                    : Colors.grey[50]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.adminBorder : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (plan.isFeatured) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.statusSuccess,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${plan.price} ${plan.currencyCode} / ${plan.billingPeriodDays} days',
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
          ],
        ),
      ),
    );
  }
}

// Duration Chip Widget
class _DurationChip extends StatelessWidget {
  final String label;
  final int days;
  final bool isDark;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.days,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
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

// User Row Widget
class _UserRow extends StatelessWidget {
  final AdminUser user;
  final bool isDark;
  final VoidCallback onTap;
  final Function(String) onRoleChange;
  final VoidCallback onTogglePremium;

  const _UserRow({
    required this.user,
    required this.isDark,
    required this.onTap,
    required this.onRoleChange,
    required this.onTogglePremium,
  });

  static String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'anxious':
        return '😰';
      case 'calm':
        return '😌';
      case 'angry':
        return '😠';
      case 'tired':
        return '😴';
      case 'energetic':
        return '⚡';
      default:
        return '😐';
    }
  }

  // Simple risk calculation based on user data
  String get _riskLevel {
    // In a real app, this would come from a risk provider
    // For now, we'll simulate based on subscription status
    if (user.isPremium) return 'low';
    final daysSinceCreation = user.createdAt != null
        ? DateTime.now().difference(user.createdAt!).inDays
        : 0;
    if (daysSinceCreation < 7) return 'moderate';
    if (daysSinceCreation < 30) return 'low';
    return 'moderate';
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 700;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Patient Info
              Expanded(
                flex: isNarrow ? 2 : 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        (user.displayName != null &&
                                user.displayName!.isNotEmpty)
                            ? user.displayName![0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.adminTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Last Mood
              if (!isNarrow)
                Expanded(
                  flex: 1,
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('mood_entries')
                        .where('user_id', isEqualTo: user.id)
                        .orderBy('created_at', descending: true)
                        .limit(1)
                        .get(),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return Text(
                          '—',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        );
                      }
                      final data =
                          snap.data!.docs.first.data() as Map<String, dynamic>;
                      final mood = (data['mood'] ?? 'neutral').toString();
                      return Row(
                        children: [
                          Text(
                            _moodEmoji(mood),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mood,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Status
              Expanded(
                flex: 1,
                child: _StatusBadge(isPremium: user.isPremium, isDark: isDark),
              ),

              // Role
              Expanded(
                flex: 1,
                child: _RoleBadge(role: user.role, isDark: isDark),
              ),

              // Joined Date
              if (!isNarrow)
                Expanded(
                  flex: 1,
                  child: Text(
                    user.createdAt != null
                        ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                        : 'N/A',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),

              // Actions
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textSecondary,
                        ),
                        onPressed: onTap,
                        tooltip: 'View Profile',
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textSecondary,
                        ),
                        tooltip: 'More Actions',
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: isDark ? AppColors.adminSurface : Colors.white,
                        onSelected: (value) {
                          if (value == 'message') {
                            final thread = ChatThread(
                              userId: user.id,
                              userEmail: user.email,
                              userName: user.displayName ?? 'User',
                              lastMessage: '',
                              lastMessageTime: DateTime.now(),
                            );
                            context.push('/admin/chat/detail', extra: thread);
                          } else if (value.startsWith('role_')) {
                            onRoleChange(value.substring(5));
                          } else if (value == 'toggle_premium') {
                            onTogglePremium();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'message',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.adminTextSecondary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                const Text('Message User'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle_premium',
                            child: Row(
                              children: [
                                Icon(
                                  user.isPremium
                                      ? Icons.star_outline
                                      : Icons.workspace_premium_rounded,
                                  size: 18,
                                  color: user.isPremium
                                      ? AppColors.statusWarning
                                      : AppColors.statusSuccess,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user.isPremium
                                      ? 'Revoke Premium'
                                      : 'Grant Premium',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'role_user',
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Set as User'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'role_therapist',
                            child: Row(
                              children: [
                                Icon(Icons.medical_services_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Set as Therapist'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'role_admin',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings_outlined,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text('Set as Admin'),
                              ],
                            ),
                          ),
                        ],
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
}

// Risk Badge Widget
// Status Badge Widget
class _StatusBadge extends StatelessWidget {
  final bool isPremium;
  final bool isDark;

  const _StatusBadge({required this.isPremium, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isPremium ? AppColors.statusSuccess : AppColors.textMuted;
    final label = isPremium ? 'PREMIUM' : 'FREE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// Role Badge Widget
class _RoleBadge extends StatelessWidget {
  final String role;
  final bool isDark;

  const _RoleBadge({required this.role, required this.isDark});

  Color get _color {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.statusDanger;
      case 'therapist':
        return AppColors.statusInfo;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      role.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _color,
      ),
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onPressed;
  final bool isDisabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.onPressed,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? AppColors.adminGlass.withValues(alpha: 0.5)
          : Colors.white,
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

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
