import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

/// A generic content card that adapts its appearance based on content type
class ContentCard extends StatelessWidget {
  final String title;
  final String description;
  final String category;
  final String type; // article, video, exercise, tip
  final String? imageUrl;
  final VoidCallback? onTap;

  const ContentCard({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    this.type = 'article',
    this.imageUrl,
    this.onTap,
  });

  IconData get _categoryIcon {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline_rounded;
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'meditation':
        return Icons.self_improvement_rounded;
      case 'tip':
        return Icons.lightbulb_outline_rounded;
      case 'article':
      default:
        return Icons.article_outlined;
    }
  }

  IconData get _placeholderIcon {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.video_library_rounded;
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'meditation':
        return Icons.self_improvement_rounded;
      case 'tip':
        return Icons.lightbulb_rounded;
      case 'article':
      default:
        return Icons.menu_book_rounded;
    }
  }

  Color get _categoryColor {
    switch (category.toLowerCase()) {
      case 'stress management':
        return const Color(0xFFF97316);
      case 'self-care':
        return const Color(0xFFEC4899);
      case 'mental health':
        return const Color(0xFF8B5CF6);
      case 'sleep':
        return const Color(0xFF6366F1);
      case 'mindfulness':
        return const Color(0xFF10B981);
      case 'anxiety':
        return const Color(0xFF3B82F6);
      case 'depression':
        return const Color(0xFF14B8A6);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppShadows.soft,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail with type-appropriate icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Category label with icon
                  Row(
                    children: [
                      Icon(
                        _categoryIcon,
                        size: 14,
                        color: _categoryColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          category.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: _categoryColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow indicator
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _categoryColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          _placeholderIcon,
          size: 32,
          color: _categoryColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
