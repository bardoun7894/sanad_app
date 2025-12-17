import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/l10n/language_provider.dart';
import 'models/post.dart';
import 'providers/community_provider.dart';
import 'widgets/post_card.dart';
import 'widgets/create_post_sheet.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  void _showCreatePostSheet(BuildContext context, WidgetRef ref) {
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

  void _showPostDetails(BuildContext context, WidgetRef ref, Post post) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _Header(strings: s),

            // Category filter
            _CategoryFilter(
              strings: s,
              selectedCategory: state.selectedCategory,
              onCategorySelected: (category) {
                ref.read(communityProvider.notifier).setCategory(category);
              },
            ),

            // Posts list
            Expanded(
              child: state.filteredPosts.isEmpty
                  ? _EmptyState(isDark: isDark, strings: s)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.spacingXl),
                      itemCount: state.filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = state.filteredPosts[index];
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostSheet(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: Text(s.newPost, style: AppTypography.buttonMedium),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final S strings;

  const _Header({required this.strings});

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
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Text(
              strings.community,
              style: AppTypography.headingMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textLight,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Search functionality
            },
            icon: Icon(
              Icons.search_rounded,
              color: isDark ? AppColors.textDark : AppColors.textLight,
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

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final S strings;

  const _EmptyState({required this.isDark, required this.strings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.softBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.noPosts,
              style: AppTypography.headingSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.beFirstShare,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
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
                                    widget.post.author.displayName[0]
                                        .toUpperCase(),
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
                                          : AppColors.textLight,
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
                            : AppColors.textLight,
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
                    Text(
                      '${s.comments} (${widget.post.commentCount})',
                      style: AppTypography.headingSmall.copyWith(
                        color: widget.isDark
                            ? Colors.white
                            : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (widget.post.comments.isEmpty)
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
                      ...widget.post.comments.map((comment) {
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: widget.isDark
                                          ? AppColors.primary.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.softBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        comment.author.name[0].toUpperCase(),
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    comment.author.name,
                                    style: AppTypography.labelMedium.copyWith(
                                      color: widget.isDark
                                          ? Colors.white
                                          : AppColors.textLight,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatTime(comment.createdAt, s),
                                    style: AppTypography.caption.copyWith(
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
                                      : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

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
                                  : AppColors.textLight,
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
