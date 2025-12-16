import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final Function(ReactionType) onReaction;
  final VoidCallback onBookmark;
  final VoidCallback onComment;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onReaction,
    required this.onBookmark,
    required this.onComment,
    this.onTap,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = PostCategoryData.getColor(post.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppShadows.soft,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.softBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: post.author.isAnonymous
                          ? Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                              size: 22,
                            )
                          : Text(
                              post.author.displayName[0].toUpperCase(),
                              style: AppTypography.headingSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.author.displayName,
                              style: AppTypography.labelLarge.copyWith(
                                color: isDark ? Colors.white : AppColors.textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (post.author.isAnonymous) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.visibility_off_outlined,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(post.createdAt),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? categoryColor.withValues(alpha: 0.2)
                          : categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PostCategoryData.getIcon(post.category),
                          size: 12,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          PostCategoryData.getLabel(post.category),
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
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Reactions display
            if (post.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _ReactionSummary(reactions: post.reactions),
                    const Spacer(),
                    if (post.commentCount > 0)
                      Text(
                        '${post.commentCount} ${post.commentCount == 1 ? 'comment' : 'comments'}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
              child: Row(
                children: [
                  _ReactionButton(
                    post: post,
                    onReaction: onReaction,
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Comment',
                    onTap: onComment,
                  ),
                  const Spacer(),
                  _ActionButton(
                    icon: post.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    label: 'Save',
                    isActive: post.isBookmarked,
                    onTap: onBookmark,
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

class _ReactionSummary extends StatelessWidget {
  final Map<ReactionType, int> reactions;

  const _ReactionSummary({required this.reactions});

  @override
  Widget build(BuildContext context) {
    final sortedReactions = reactions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topReactions = sortedReactions.take(3);
    final total = reactions.values.fold(0, (sum, count) => sum + count);

    return Row(
      children: [
        ...topReactions.map((entry) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Text(
                ReactionData.getEmoji(entry.key),
                style: const TextStyle(fontSize: 14),
              ),
            )),
        const SizedBox(width: 6),
        Text(
          total.toString(),
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReactionButton extends StatefulWidget {
  final Post post;
  final Function(ReactionType) onReaction;

  const _ReactionButton({
    required this.post,
    required this.onReaction,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showReactionPicker() {
    HapticFeedback.lightImpact();

    _overlayEntry = OverlayEntry(
      builder: (context) => _ReactionPickerOverlay(
        layerLink: _layerLink,
        userReactions: widget.post.userReactions,
        onReaction: (type) {
          widget.onReaction(type);
          _hideReactionPicker();
        },
        onDismiss: _hideReactionPicker,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideReactionPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideReactionPicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasReacted = widget.post.userReactions.isNotEmpty;
    final primaryReaction = hasReacted ? widget.post.userReactions.first : null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          if (hasReacted) {
            widget.onReaction(primaryReaction!);
          } else {
            widget.onReaction(ReactionType.heart);
          }
        },
        onLongPress: _showReactionPicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: hasReacted
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.softBlue)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasReacted)
                Text(
                  ReactionData.getEmoji(primaryReaction!),
                  style: const TextStyle(fontSize: 18),
                )
              else
                Icon(
                  Icons.favorite_outline_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              const SizedBox(width: 6),
              Text(
                hasReacted ? ReactionData.getLabel(primaryReaction!) : 'React',
                style: AppTypography.labelMedium.copyWith(
                  color: hasReacted ? AppColors.primary : AppColors.textMuted,
                  fontWeight: hasReacted ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionPickerOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final Set<ReactionType> userReactions;
  final Function(ReactionType) onReaction;
  final VoidCallback onDismiss;

  const _ReactionPickerOverlay({
    required this.layerLink,
    required this.userReactions,
    required this.onReaction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Dismiss area
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),

        // Picker
        CompositedTransformFollower(
          link: layerLink,
          offset: const Offset(0, -60),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ReactionType.values.map((type) {
                  final isSelected = userReactions.contains(type);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onReaction(type);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        ReactionData.getEmoji(type),
                        style: TextStyle(
                          fontSize: isSelected ? 28 : 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.softBlue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isActive ? AppColors.primary : AppColors.textMuted,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
