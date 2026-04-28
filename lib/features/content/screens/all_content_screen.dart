import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/content_models.dart';
import 'youtube_player_screen.dart';
import 'content_detail_screen.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/expandable_text.dart';

class AllContentScreen extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final FutureProvider<List<ContentItem>> provider;
  final bool isYouTube;
  final bool showPlayIcon;

  const AllContentScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.provider,
    this.isYouTube = false,
    this.showPlayIcon = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final itemsAsync = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.displayMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: itemsAsync.when(
        loading: () => LoadingStateWidget(message: s.loadingContent),
        error: (e, _) => ErrorStateWidget(
          message: s.errorLoadingData,
          retryLabel: s.retry,
          onRetry: () => ref.invalidate(provider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: icon,
              message: s.noContentYet,
              description: s.contentComingSoon,
              iconColor: iconColor,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(provider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildCard(context, items[index], isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, ContentItem item, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (isYouTube || item.isYouTubeVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YouTubePlayerScreen(content: item),
            ),
          );
        } else if (item.contentUrl != null && item.contentUrl!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContentDetailScreen(item: item)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContentDetailScreen(item: item)),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    item.thumbnailUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: isDark
                          ? const Color(0xFF1E3A5F)
                          : AppColors.primary.withValues(alpha: 0.08),
                      child: Icon(
                        showPlayIcon
                            ? Icons.videocam_outlined
                            : Icons.article_outlined,
                        size: 40,
                        color: isDark
                            ? Colors.white24
                            : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  if (showPlayIcon)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else
              Container(
                height: 80,
                color: isDark
                    ? const Color(0xFF1E3A5F)
                    : AppColors.primary.withValues(alpha: 0.08),
                child: Center(
                  child: Icon(
                    showPlayIcon ? Icons.videocam_outlined : icon,
                    size: 32,
                    color: iconColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.category != null && item.category!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category!,
                        style: AppTypography.caption.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    item.localizedTitle(context),
                    style: AppTypography.headingSmall.copyWith(
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.localizedDescription(context).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ExpandableText(
                      text: item.localizedDescription(context),
                      maxLines: 2,
                      isDark: isDark,
                    ),
                  ],
                  if (item.createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(item.createdAt!),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}
