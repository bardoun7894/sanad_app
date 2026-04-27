import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/content_share_utils.dart';
import '../../../core/widgets/expandable_text.dart';
import '../models/content_models.dart';
import 'youtube_player_screen.dart';

class ContentDetailScreen extends ConsumerStatefulWidget {
  final ContentItem item;

  const ContentDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ContentDetailScreen> createState() =>
      _ContentDetailScreenState();
}

class _ContentDetailScreenState extends ConsumerState<ContentDetailScreen> {
  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final item = widget.item;

    // If it's a YouTube video, redirect to the player screen
    if (item.type == 'video' && item.isYouTubeVideo) {
      return YouTubePlayerScreen(content: item);
    }

    final textStyle = AppTypography.bodyLarge.copyWith(
      color: isDark ? Colors.white70 : AppColors.textPrimary,
      height: 1.7,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Collapsible app bar with thumbnail
          SliverAppBar(
            expandedHeight:
                item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                ? 280
                : 120,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                onPressed: () => ContentShareUtils.shareContent(item),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background:
                  item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          item.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        // Gradient overlay for better text contrast
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  isDark ? Colors.black87 : Colors.white,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  if (item.category != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.category!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Title
                  Text(
                    item.title,
                    style: AppTypography.headingLarge.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 24,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Meta row: duration + date
                  Row(
                    children: [
                      if (item.formattedDuration.isNotEmpty) ...[
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.formattedDuration,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.createdAt != null
                            ? _formatDate(item.createdAt!)
                            : '',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Divider(
                    color: isDark ? Colors.white12 : Colors.black12,
                    height: 1,
                  ),

                  const SizedBox(height: 24),

                  // Description — only shows the expand toggle if the text
                  // actually overflows, and uses localized labels.
                  if (item.description.isNotEmpty)
                    ExpandableText(
                      text: item.description,
                      maxLines: _maxLines,
                      style: textStyle,
                      isDark: isDark,
                      expandLabel: s.showMore,
                      collapseLabel: s.showLess,
                    ),

                  const SizedBox(height: 32),

                  // Action buttons
                  if (item.contentUrl != null &&
                      item.contentUrl!.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchUrl(item.contentUrl!),
                        icon: Icon(_getUrlIcon()),
                        label: Text(_getUrlLabel(s)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Share section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'شارك المحتوى',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ShareButton(
                              icon: Icons.share,
                              label: 'مشاركة',
                              onTap: () => ContentShareUtils.shareContent(item),
                            ),
                            const SizedBox(width: 12),
                            _ShareButton(
                              icon: Icons.chat,
                              label: 'واتساب',
                              color: const Color(0xFF25D366),
                              onTap: () =>
                                  ContentShareUtils.shareViaWhatsApp(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getUrlIcon() {
    switch (widget.item.type) {
      case 'podcast':
        return Icons.headphones;
      case 'video':
        return Icons.play_circle_outline;
      case 'exercise':
        return Icons.fitness_center;
      default:
        return Icons.open_in_new;
    }
  }

  String _getUrlLabel(S s) {
    switch (widget.item.type) {
      case 'podcast':
        return s.listenNow;
      case 'video':
        return s.watchNow;
      case 'exercise':
        return s.startExercise;
      default:
        return s.readMore;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: btnColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: btnColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: btnColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: btnColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
