import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/l10n/language_provider.dart';
import '../../core/widgets/loading_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/empty_state_widget.dart';
import 'models/post.dart';
import 'providers/community_provider.dart';
import 'widgets/post_card.dart';
import 'widgets/create_post_sheet.dart';
import '../auth/providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/login_prompt.dart';
import 'package:go_router/go_router.dart';

// Search query provider
final communitySearchQueryProvider = StateProvider<String>((ref) => '');

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(communityProvider);
      if (state.hasMorePosts && !state.isLoadingMore) {
        ref.read(communityProvider.notifier).loadMorePosts();
      }
    }
  }

  void _showSearchSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController = TextEditingController(
      text: ref.read(communitySearchQueryProvider),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${ref.read(stringsProvider).search} ${ref.read(stringsProvider).posts}',
                style: AppTypography.headingSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '${ref.read(stringsProvider).search}...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      ref.read(communitySearchQueryProvider.notifier).state =
                          '';
                    },
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  ref.read(communitySearchQueryProvider.notifier).state = value;
                },
                onSubmitted: (_) => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        searchController.clear();
                        ref.read(communitySearchQueryProvider.notifier).state =
                            '';
                        Navigator.pop(context);
                      },
                      child: Text(ref.read(stringsProvider).clearAll),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(ref.read(stringsProvider).search),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreatePostSheet(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    final s = ref.read(stringsProvider);

    // Check auth
    if (!authState.isAuthenticated || (authState.user?.isGuest ?? false)) {
      final shouldLogin = await showLoginPrompt(
        context,
        feature: s.community,
        description: s.loginToPost,
      );
      if (shouldLogin == true && context.mounted) {
        context.push(AppRoutes.login);
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostSheet(
        onPost: (content, category, isAnonymous) {
          ref
              .read(communityProvider.notifier)
              .addPost(content, category, isAnonymous: isAnonymous);
        },
      ),
    );
  }

  void _showPostDetails(BuildContext context, WidgetRef ref, Post post) async {
    // Check if user is authenticated before allowing comments
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      final s = ref.read(stringsProvider);
      final shouldLogin = await GuestGuard.checkAuth(
        context,
        ref,
        feature: s.commenting,
        description: s.loginToComment,
      );
      // If user chose not to login, just return without showing post details
      if (!shouldLogin) return;
    }

    // Check if context is still mounted after async operation
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostDetailSheet(
        post: post,
        onReaction: (type) =>
            ref.read(communityProvider.notifier).toggleReaction(post.id, type),
        onComment: (content) =>
            ref.read(communityProvider.notifier).addComment(post.id, content),
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    final searchQuery = ref.watch(communitySearchQueryProvider).toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    // Apply search filter to posts
    final displayedPosts = searchQuery.isEmpty
        ? state.filteredPosts
        : state.filteredPosts.where((post) {
            return post.content.toLowerCase().contains(searchQuery) ||
                post.author.displayName.toLowerCase().contains(searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search
            _CommunityHeader(
              strings: s,
              onSearch: () => _showSearchSheet(context, ref),
            ),

            // Search indicator
            if (searchQuery.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.search}: "$searchQuery"',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          ref
                                  .read(communitySearchQueryProvider.notifier)
                                  .state =
                              '',
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

            // Category filter
            _CategoryFilter(
              strings: s,
              selectedCategory: state.selectedCategory,
              onCategorySelected: (category) {
                ref.read(communityProvider.notifier).setCategory(category);
              },
            ),

            // Posts list with proper loading/error/empty states
            Expanded(
              child: _buildPostsContent(
                state: state,
                displayedPosts: displayedPosts,
                isDark: isDark,
                s: s,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton.extended(
          onPressed: () => _showCreatePostSheet(context, ref),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          label: Text(s.newPost, style: AppTypography.buttonMedium),
        ),
      ),
    );
  }

  Widget _buildPostsContent({
    required CommunityState state,
    required List<Post> displayedPosts,
    required bool isDark,
    required S s,
  }) {
    // Priority 1: Loading state (first load, no posts yet)
    if (state.isLoading && state.posts.isEmpty) {
      return LoadingStateWidget(message: s.loadingPosts);
    }

    // Priority 2: Error state (error occurred, no posts to show)
    if (state.error != null && state.posts.isEmpty) {
      return ErrorStateWidget(
        message: s.errorLoadingPosts,
        retryLabel: s.retry,
        onRetry: () {
          ref.read(communityProvider.notifier).refreshPosts();
        },
      );
    }

    // Priority 3: Empty state (not loading, no error, truly no posts)
    if (displayedPosts.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline_rounded,
        message: s.noPosts,
        description: s.beFirstShare,
        actionLabel: s.newPost,
        onAction: () => _showCreatePostSheet(context, ref),
      );
    }

    // Priority 4: Show posts with pull-to-refresh
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(communityProvider.notifier).refreshPosts();
        // Wait a bit for the stream to update
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsetsDirectional.only(
          top: 16,
          bottom: 100,
        ),
        itemCount: displayedPosts.length + (state.hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading more indicator at the bottom
          if (index == displayedPosts.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }

          final post = displayedPosts[index];
          return PostCard(
            post: post,
            onReaction: (type) {
              ref
                  .read(communityProvider.notifier)
                  .toggleReaction(post.id, type);
            },
            onBookmark: () {
              ref
                  .read(communityProvider.notifier)
                  .toggleBookmark(post.id);
            },
            onComment: () => _showPostDetails(context, ref, post),
            onTap: () => _showPostDetails(context, ref, post),
          );
        },
      ),
    );
  }
}

class _CommunityHeader extends StatelessWidget {
  final S strings;
  final VoidCallback onSearch;

  const _CommunityHeader({required this.strings, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Text(
              strings.community,
              style: AppTypography.headingMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onSearch,
            icon: Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final PostCategory? selectedCategory;
  final Function(PostCategory?) onCategorySelected;
  final S strings;

  const _CategoryFilter({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
        children: [
          _FilterChip(
            label: strings.categoryAll,
            icon: Icons.grid_view_rounded,
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
            color: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          ...PostCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: PostCategoryData.getLabel(category, strings: strings),
                icon: PostCategoryData.getIcon(category),
                isSelected: selectedCategory == category,
                onTap: () => onCategorySelected(category),
                color: PostCategoryData.getColor(category),
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? color.withValues(alpha: 0.3) : color)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.white)
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.white)
                    : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostDetailSheet extends ConsumerStatefulWidget {
  final Post post;
  final Function(ReactionType) onReaction;
  final Function(String) onComment;
  final bool isDark;

  const _PostDetailSheet({
    required this.post,
    required this.onReaction,
    required this.onComment,
    required this.isDark,
  });

  @override
  ConsumerState<_PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends ConsumerState<_PostDetailSheet> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;

    HapticFeedback.mediumImpact();
    widget.onComment(_commentController.text.trim());
    _commentController.clear();
  }

  String _formatTime(DateTime dateTime, S s) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return s.justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}${s.minutesAgo}';
    if (diff.inHours < 24) return '${diff.inHours}${s.hoursAgo}';
    return '${diff.inDays}${s.daysAgo}';
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = PostCategoryData.getColor(widget.post.category);
    final s = ref.watch(stringsProvider);
    final commentsAsync = ref.watch(postCommentsProvider(widget.post.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Author info
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.softBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: widget.post.author.isAnonymous
                                ? Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.primary,
                                  )
                                : Text(
                                    (widget.post.author.displayName.isNotEmpty)
                                        ? widget.post.author.displayName[0]
                                              .toUpperCase()
                                        : '?',
                                    style: AppTypography.headingSmall.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.post.author.displayName,
                                    style: AppTypography.labelLarge.copyWith(
                                      color: widget.isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (widget.post.author.isAnonymous) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.visibility_off_outlined,
                                      size: 14,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                _formatTime(widget.post.createdAt, s),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? categoryColor.withValues(alpha: 0.2)
                                : categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius2xl,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PostCategoryData.getIcon(widget.post.category),
                                size: 12,
                                color: categoryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                PostCategoryData.getLabel(
                                  widget.post.category,
                                  strings: s,
                                ),
                                style: AppTypography.caption.copyWith(
                                  color: categoryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Post content
                    Text(
                      widget.post.content,
                      style: AppTypography.bodyLarge.copyWith(
                        color: widget.isDark
                            ? AppColors.textDark
                            : AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reactions
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ReactionType.values.map((type) {
                        final count = widget.post.reactions[type] ?? 0;
                        final isSelected = widget.post.userReactions.contains(
                          type,
                        );

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onReaction(type);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (widget.isDark
                                        ? AppColors.primary.withValues(
                                            alpha: 0.2,
                                          )
                                        : AppColors.softBlue)
                                  : (widget.isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.backgroundLight),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius2xl,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (widget.isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ReactionData.getEmoji(type),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    count.toString(),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                    Divider(
                      color: widget.isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                    const SizedBox(height: 16),

                    // Comments section
                    commentsAsync.when(
                      data: (comments) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.comments} (${comments.length})',
                              style: AppTypography.headingSmall.copyWith(
                                color: widget.isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (comments.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 40,
                                        color: AppColors.textMuted.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        s.noComments,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      Text(
                                        s.beFirstSupport,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...comments.map((comment) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: widget.isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: widget.isDark
                                                  ? AppColors.primary
                                                        .withValues(alpha: 0.2)
                                                  : AppColors.softBlue,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                comment.author.name.isNotEmpty
                                                    ? comment.author.name[0]
                                                          .toUpperCase()
                                                    : '?',
                                                style: AppTypography.labelSmall
                                                    .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              comment.author.name,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: AppTypography.labelMedium
                                                  .copyWith(
                                                    color: widget.isDark
                                                        ? Colors.white
                                                        : AppColors.textPrimary,
                                                  ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatTime(comment.createdAt, s),
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: AppColors.textMuted,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        comment.content,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: widget.isDark
                                              ? AppColors.textDark
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => Text(
                        s.errorLoadingData,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.surfaceDark : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: widget.isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? AppColors.backgroundDark
                                : AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius2xl,
                            ),
                          ),
                          child: TextField(
                            controller: _commentController,
                            style: AppTypography.bodyMedium.copyWith(
                              color: widget.isDark
                                  ? AppColors.textDark
                                  : AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: s.addComment,
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _submitComment,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
