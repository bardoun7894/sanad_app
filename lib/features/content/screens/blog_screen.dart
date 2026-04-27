import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';
import 'content_detail_screen.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

class BlogScreen extends ConsumerWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final articlesAsync = ref.watch(blogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.blog,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: articlesAsync.when(
        loading: () => LoadingStateWidget(message: s.loadingContent),
        error: (e, _) => ErrorStateWidget(
          message: s.errorLoadingData,
          retryLabel: s.retry,
          onRetry: () => ref.invalidate(blogProvider),
        ),
        data: (articles) {
          if (articles.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(blogProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: EmptyStateWidget(
                      icon: Icons.article_outlined,
                      message: s.noContentYet,
                      description: s.contentComingSoon,
                      iconColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(blogProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: articles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildArticleCard(context, articles[index], isDark, s),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleCard(
    BuildContext context,
    ContentItem item,
    bool isDark,
    dynamic s,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ContentDetailScreen(item: item)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.article_outlined,
                color: Colors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.headingSmall.copyWith(
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.category != null)
                    Text(
                      item.category!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? Colors.white60
                            : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContentDetailScreen(item: item),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          s.readMore,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
