import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../providers/admin_community_provider.dart';
import '../../community/models/post.dart';
import 'package:intl/intl.dart';

// Moderation filter state
class ModerationFilter {
  final String searchQuery;
  final String category;
  final String status;
  final String sortBy;

  const ModerationFilter({
    this.searchQuery = '',
    this.category = 'all',
    this.status = 'all',
    this.sortBy = 'newest',
  });

  ModerationFilter copyWith({
    String? searchQuery,
    String? category,
    String? status,
    String? sortBy,
  }) {
    return ModerationFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      status: status ?? this.status,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final moderationFilterProvider = StateProvider<ModerationFilter>(
  (ref) => const ModerationFilter(),
);

final selectedPostsProvider = StateProvider<Set<String>>((ref) => {});

class ModerationDashboard extends ConsumerStatefulWidget {
  const ModerationDashboard({super.key});

  @override
  ConsumerState<ModerationDashboard> createState() =>
      _ModerationDashboardState();
}

class _ModerationDashboardState extends ConsumerState<ModerationDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() => ref.read(adminCommunityProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(adminCommunityProvider);
    final filter = ref.watch(moderationFilterProvider);
    final selectedPosts = ref.watch(selectedPostsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          _buildHeader(isDark, selectedPosts),

          // Stats Row
          _buildStatsRow(isDark, state.posts),

          // Search and Filters
          _buildSearchAndFilters(isDark, filter),

          // Tabs
          _buildTabs(isDark, state.posts),

          // Content
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.error != null
                ? _ErrorState(error: state.error!, isDark: isDark)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _PostsList(
                        posts: state.posts,
                        filter: filter,
                        type: 'all',
                      ),
                      _PostsList(
                        posts: state.posts,
                        filter: filter,
                        type: 'reported',
                      ),
                      _PostsList(
                        posts: state.posts,
                        filter: filter,
                        type: 'flagged',
                      ),
                      _PostsList(
                        posts: state.posts,
                        filter: filter,
                        type: 'approved',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Set<String> selectedPosts) {
    final isMobile = AdminResponsive.isMobile(context);

    final titleAndStats = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.adminCommunityModeration,
          style: TextStyle(
            fontSize: isMobile ? 22 : 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.adminReviewModerate,
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
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (selectedPosts.isNotEmpty) ...[
          _BulkActionButton(
            icon: Icons.check_circle_rounded,
            label: 'Approve (${selectedPosts.length})',
            color: AppColors.statusSuccess,
            onPressed: () => _bulkAction('approve'),
            isDark: isDark,
          ),
          _BulkActionButton(
            icon: Icons.flag_rounded,
            label: 'Flag',
            color: AppColors.statusWarning,
            onPressed: () => _bulkAction('flag'),
            isDark: isDark,
          ),
          _BulkActionButton(
            icon: Icons.delete_rounded,
            label: 'Delete',
            color: AppColors.statusDanger,
            onPressed: () => _bulkAction('delete'),
            isDark: isDark,
          ),
        ],
        _ActionButton(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onPressed: () =>
              ref.read(adminCommunityProvider.notifier).refresh(),
          isDark: isDark,
          isOutlined: true,
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        isMobile ? 12 : 24,
        isMobile ? 12 : 24,
        16,
      ),
      child: isMobile || selectedPosts.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleAndStats,
                const SizedBox(height: 12),
                actions,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleAndStats),
                actions,
              ],
            ),
    );
  }

  Widget _buildStatsRow(bool isDark, List<Post> posts) {
    final isMobile = AdminResponsive.isMobile(context);
    final totalPosts = posts.length;
    final reportedPosts = posts.where((p) => p.reportCount > 0).length;
    final flaggedPosts = posts.where((p) => p.reportCount > 3).length;
    final todayPosts = posts
        .where(
          (p) =>
              p.createdAt.day == DateTime.now().day &&
              p.createdAt.month == DateTime.now().month,
        )
        .length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatChip(
              icon: Icons.article_rounded,
              label: 'Total Posts',
              value: totalPosts.toString(),
              color: AppColors.primary,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.flag_rounded,
              label: 'Reported',
              value: reportedPosts.toString(),
              color: AppColors.statusWarning,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.warning_rounded,
              label: 'Needs Review',
              value: flaggedPosts.toString(),
              color: AppColors.statusDanger,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.today_rounded,
              label: 'Today',
              value: todayPosts.toString(),
              color: AppColors.statusInfo,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark, ModerationFilter filter) {
    final isMobile = AdminResponsive.isMobile(context);

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.adminGlass.withValues(alpha: 0.3)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.adminBorder : AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(moderationFilterProvider.notifier).state = filter
                      .copyWith(searchQuery: value);
                },
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search posts by content or author...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FilterDropdown(
                    value: filter.category,
                    items: const {
                      'all': 'All Categories',
                      'general': 'General',
                      'anxiety': 'Anxiety',
                      'depression': 'Depression',
                      'relationships': 'Relationships',
                      'selfCare': 'Self Care',
                      'motivation': 'Motivation',
                    },
                    onChanged: (value) {
                      ref.read(moderationFilterProvider.notifier).state = filter
                          .copyWith(category: value);
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterDropdown(
                    value: filter.sortBy,
                    items: const {
                      'newest': 'Newest',
                      'oldest': 'Oldest',
                      'mostReported': 'Most Reported',
                    },
                    onChanged: (value) {
                      ref.read(moderationFilterProvider.notifier).state = filter
                          .copyWith(sortBy: value);
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
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
                  color: isDark ? AppColors.adminBorder : AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(moderationFilterProvider.notifier).state = filter
                      .copyWith(searchQuery: value);
                },
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search posts by content or author...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Category Dropdown
          _FilterDropdown(
            value: filter.category,
            items: const {
              'all': 'All Categories',
              'general': 'General',
              'anxiety': 'Anxiety',
              'depression': 'Depression',
              'relationships': 'Relationships',
              'selfCare': 'Self Care',
              'motivation': 'Motivation',
            },
            onChanged: (value) {
              ref.read(moderationFilterProvider.notifier).state = filter
                  .copyWith(category: value);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 12),

          // Sort Dropdown
          _FilterDropdown(
            value: filter.sortBy,
            items: const {
              'newest': 'Newest First',
              'oldest': 'Oldest First',
              'mostReports': 'Most Reports',
              'mostReactions': 'Most Reactions',
            },
            onChanged: (value) {
              ref.read(moderationFilterProvider.notifier).state = filter
                  .copyWith(sortBy: value);
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isDark, List<Post> posts) {
    final allCount = posts.length;
    final reportedCount = posts.where((p) => p.reportCount > 0).length;
    final flaggedCount = posts.where((p) => p.reportCount > 3).length;
    final approvedCount = posts.where((p) => p.reportCount == 0).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.2)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark
            ? AppColors.adminTextSecondary
            : AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: isDark
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        dividerColor: Colors.transparent,
        tabs: [
          _TabWithBadge(label: 'All', count: allCount, isDark: isDark),
          _TabWithBadge(
            label: 'Reported',
            count: reportedCount,
            isDark: isDark,
            badgeColor: AppColors.statusWarning,
          ),
          _TabWithBadge(
            label: 'Flagged',
            count: flaggedCount,
            isDark: isDark,
            badgeColor: AppColors.statusDanger,
          ),
          _TabWithBadge(
            label: 'Approved',
            count: approvedCount,
            isDark: isDark,
            badgeColor: AppColors.statusSuccess,
          ),
        ],
      ),
    );
  }

  void _bulkAction(String action) async {
    final selectedPosts = ref.read(selectedPostsProvider);
    if (selectedPosts.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.adminSurface : Colors.white,
          title: Text('Confirm $action'),
          content: Text(
            'Are you sure you want to $action ${selectedPosts.length} posts?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'delete'
                    ? AppColors.statusDanger
                    : AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(action.toUpperCase()),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Perform bulk action
      if (action == 'delete') {
        for (final postId in selectedPosts) {
          await ref.read(adminCommunityProvider.notifier).deletePost(postId);
        }
      }
      ref.read(selectedPostsProvider.notifier).state = {};
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedPosts.length} posts ${action}ed'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    }
  }
}

// Posts List Widget
class _PostsList extends ConsumerWidget {
  final List<Post> posts;
  final ModerationFilter filter;
  final String type;

  const _PostsList({
    required this.posts,
    required this.filter,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedPosts = ref.watch(selectedPostsProvider);

    var filteredPosts = posts;

    // Apply type filter
    switch (type) {
      case 'reported':
        filteredPosts = filteredPosts.where((p) => p.reportCount > 0).toList();
        break;
      case 'flagged':
        filteredPosts = filteredPosts.where((p) => p.reportCount > 3).toList();
        break;
      case 'approved':
        filteredPosts = filteredPosts.where((p) => p.reportCount == 0).toList();
        break;
    }

    // Apply category filter
    if (filter.category != 'all') {
      filteredPosts = filteredPosts
          .where((p) => p.category.name == filter.category)
          .toList();
    }

    // Apply search
    if (filter.searchQuery.isNotEmpty) {
      filteredPosts = filteredPosts.where((p) {
        return p.content.toLowerCase().contains(
              filter.searchQuery.toLowerCase(),
            ) ||
            p.author.displayName.toLowerCase().contains(
              filter.searchQuery.toLowerCase(),
            );
      }).toList();
    }

    // Apply sorting
    switch (filter.sortBy) {
      case 'oldest':
        filteredPosts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'mostReports':
        filteredPosts.sort((a, b) => b.reportCount.compareTo(a.reportCount));
        break;
      case 'mostReactions':
        filteredPosts.sort(
          (a, b) => b.totalReactions.compareTo(a.totalReactions),
        );
        break;
      default:
        filteredPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    if (filteredPosts.isEmpty) {
      return _EmptyState(type: type, isDark: isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return _PostCard(
          post: post,
          isDark: isDark,
          isSelected: selectedPosts.contains(post.id),
          onSelect: (selected) {
            final currentSet = Set<String>.from(selectedPosts);
            if (selected) {
              currentSet.add(post.id);
            } else {
              currentSet.remove(post.id);
            }
            ref.read(selectedPostsProvider.notifier).state = currentSet;
          },
        );
      },
    );
  }
}

class _PostCard extends ConsumerWidget {
  final Post post;
  final bool isDark;
  final bool isSelected;
  final Function(bool) onSelect;

  const _PostCard({
    required this.post,
    required this.isDark,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasReports = post.reportCount > 0;
    final isUrgent = post.reportCount > 3;
    final categoryColor = PostCategoryData.getColor(post.category);
    final categoryIcon = PostCategoryData.getIcon(post.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: isSelected ? 0.5 : 0.3)
            : isSelected
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : isUrgent
              ? AppColors.statusDanger.withValues(alpha: 0.5)
              : hasReports
              ? AppColors.statusWarning.withValues(alpha: 0.5)
              : (isDark ? AppColors.adminBorder : AppColors.borderLight),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (val) => onSelect(val ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),

                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: post.author.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            post.author.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                                  child: Text(
                                    post.author.displayName.isNotEmpty
                                        ? post.author.displayName[0]
                                              .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: categoryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                          ),
                        )
                      : Center(
                          child: Text(
                            post.author.displayName.isNotEmpty
                                ? post.author.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Author Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.author.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (post.author.isAnonymous) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ANONYMOUS',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.adminTextSecondary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'MMM d, yyyy · h:mm a',
                        ).format(post.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon, size: 14, color: categoryColor),
                      const SizedBox(width: 4),
                      Text(
                        PostCategoryData.getLabel(post.category),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Report Badge
                if (hasReports) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isUrgent
                                  ? AppColors.statusDanger
                                  : AppColors.statusWarning)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            (isUrgent
                                    ? AppColors.statusDanger
                                    : AppColors.statusWarning)
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          size: 14,
                          color: isUrgent
                              ? AppColors.statusDanger
                              : AppColors.statusWarning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.reportCount} reports',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isUrgent
                                ? AppColors.statusDanger
                                : AppColors.statusWarning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.textPrimary,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Stats
                _StatIcon(
                  icon: Icons.favorite_rounded,
                  count: post.totalReactions,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _StatIcon(
                  icon: Icons.comment_rounded,
                  count: post.commentCount,
                  isDark: isDark,
                ),
                const Spacer(),

                // Actions
                _ActionIconButton(
                  icon: Icons.visibility_rounded,
                  tooltip: 'View Details',
                  onPressed: () => _showPostDetails(context, post),
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _DisabledActionIconButton(
                  icon: Icons.check_circle_outline_rounded,
                  tooltip:
                      '${AppStrings.adminApprove} — ${AppStrings.adminFeatureComingSoon}',
                  isDark: isDark,
                  color: AppColors.statusSuccess,
                ),
                const SizedBox(width: 4),
                _DisabledActionIconButton(
                  icon: Icons.flag_outlined,
                  tooltip:
                      '${AppStrings.adminFlag} — ${AppStrings.adminFeatureComingSoon}',
                  isDark: isDark,
                  color: AppColors.statusWarning,
                ),
                const SizedBox(width: 4),
                _ActionIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete',
                  onPressed: () => _deletePost(context, ref, post.id),
                  isDark: isDark,
                  color: AppColors.statusDanger,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDetails(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostDetailSheet(post: post),
    );
  }

  void _deletePost(BuildContext context, WidgetRef ref, String postId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.adminSurface : Colors.white,
          title: const Text('Delete Post'),
          content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusDanger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await ref.read(adminCommunityProvider.notifier).deletePost(postId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.statusDanger,
            ),
          );
        }
      }
    }
  }
}

class _PostDetailSheet extends StatelessWidget {
  final Post post;

  const _PostDetailSheet({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = PostCategoryData.getColor(post.category);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.adminBorder : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Post Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            post.author.displayName[0].toUpperCase(),
                            style: TextStyle(
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author.displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM d, yyyy · h:mm a',
                            ).format(post.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.adminTextSecondary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Full Content
                  Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.adminGlass.withValues(alpha: 0.2)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DetailStat(
                          label: 'Reactions',
                          value: post.totalReactions.toString(),
                          icon: Icons.favorite_rounded,
                          color: AppColors.statusDanger,
                          isDark: isDark,
                        ),
                        _DetailStat(
                          label: 'Comments',
                          value: post.commentCount.toString(),
                          icon: Icons.comment_rounded,
                          color: AppColors.primary,
                          isDark: isDark,
                        ),
                        _DetailStat(
                          label: 'Reports',
                          value: post.reportCount.toString(),
                          icon: Icons.flag_rounded,
                          color: AppColors.statusWarning,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _DetailStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Supporting Widgets
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDark;
  final bool isOutlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isDark,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : AppColors.primary,
        foregroundColor: isOutlined
            ? (isDark ? Colors.white : AppColors.textPrimary)
            : Colors.white,
        elevation: isOutlined ? 0 : 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: isOutlined
              ? BorderSide(
                  color: isDark ? AppColors.adminBorder : AppColors.borderLight,
                )
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _BulkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isDark;

  const _BulkActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.adminGlass.withValues(alpha: 0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
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
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final Map<String, String> items;
  final Function(String) onChanged;
  final bool isDark;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
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
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? AppColors.adminTextSecondary : AppColors.textMuted,
          ),
          dropdownColor: isDark ? AppColors.adminSurface : Colors.white,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          items: items.entries.map((e) {
            return DropdownMenuItem(value: e.key, child: Text(e.value));
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

class _TabWithBadge extends StatelessWidget {
  final String label;
  final int count;
  final bool isDark;
  final Color? badgeColor;

  const _TabWithBadge({
    required this.label,
    required this.count,
    required this.isDark,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor ?? AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool isDark;

  const _StatIcon({
    required this.icon,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.adminTextSecondary : AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.adminTextSecondary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isDark;
  final Color? color;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor =
        color ?? (isDark ? AppColors.adminTextSecondary : AppColors.textMuted);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: buttonColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: buttonColor),
        ),
      ),
    );
  }
}

class _DisabledActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final Color? color;

  const _DisabledActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor =
        (color ?? (isDark ? AppColors.adminTextSecondary : AppColors.textMuted))
            .withValues(alpha: 0.35);

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: buttonColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: buttonColor),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String type;
  final bool isDark;

  const _EmptyState({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final messages = {
      'all': 'No posts found',
      'reported': 'No reported posts',
      'flagged': 'No flagged posts',
      'approved': 'No approved posts',
    };

    final icons = {
      'all': Icons.article_outlined,
      'reported': Icons.flag_outlined,
      'flagged': Icons.warning_outlined,
      'approved': Icons.check_circle_outlined,
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.adminGlass.withValues(alpha: 0.2)
                  : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icons[type] ?? Icons.article_outlined,
              size: 48,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            messages[type] ?? 'No posts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final bool isDark;

  const _ErrorState({required this.error, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
            'Error loading posts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
