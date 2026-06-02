import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/content_models.dart';
import '../providers/related_content_provider.dart';
import '../screens/content_detail_screen.dart';

/// Horizontal carousel of articles related to [item].
///
/// Collapses entirely (renders nothing) when the loaded list is empty or when
/// the provider is in an error state, so the page layout is never broken.
///
/// Amendment #4: "see all" link and modal have been removed. 6 inline
/// cards are sufficient; restore only as full-screen route post-analytics.
class RelatedContentSection extends ConsumerWidget {
  final ContentItem item;

  const RelatedContentSection({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncRelated =
        ref.watch(relatedContentProvider(RelatedContentKey(item)));

    return asyncRelated.when(
      loading: () => _SkeletonSection(isDark: isDark),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section heading — Amendment #4: no spaceBetween, no "see all".
            Padding(
              // Amendment #10: EdgeInsetsDirectional so start/end are
              // bidi-correct regardless of text direction.
              padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
              child: Text(
                s.similarArticles,
                style: AppTypography.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Horizontal card list
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                // Amendment #10: directional padding instead of symmetric.
                padding:
                    const EdgeInsetsDirectional.only(start: 20, end: 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _RelatedCard(article: items[index], isDark: isDark),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual card
// ---------------------------------------------------------------------------

class _RelatedCard extends StatelessWidget {
  final ContentItem article;
  final bool isDark;

  const _RelatedCard({required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = isDark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContentDetailScreen(item: article),
        ),
      ),
      child: Container(
        // Amendment #1: 150px → 176px for Arabic word wrapping.
        width: 176,
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail 4:3 aspect ratio, 14-radius corners at top.
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: article.thumbnailUrl != null
                    ? Image.network(
                        article.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _ThumbnailFallback(),
                      )
                    : const _ThumbnailFallback(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title: 2-line max, height 1.4 for Arabic breathing room.
                  // Amendment #10: height bumped from 1.35 → 1.4.
                  Text(
                    article.localizedTitle(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color:
                          isDarkMode ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  if (article.category != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        article.category!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
}

// ---------------------------------------------------------------------------
// Thumbnail fallback — gradient placeholder + category icon.
// ---------------------------------------------------------------------------

class _ThumbnailFallback extends StatelessWidget {
  const _ThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.article_outlined,
          color: AppColors.primary.withValues(alpha: 0.55),
          size: 28,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loading section (3 skeleton cards, max 3s then hidden by provider)
// ---------------------------------------------------------------------------

class _SkeletonSection extends StatefulWidget {
  final bool isDark;

  const _SkeletonSection({required this.isDark});

  @override
  State<_SkeletonSection> createState() => _SkeletonSectionState();
}

class _SkeletonSectionState extends State<_SkeletonSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmerColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.07);

    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) {
        return Opacity(
          opacity: _opacity.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading skeleton
              Padding(
                // Amendment #10: directional padding.
                padding:
                    const EdgeInsetsDirectional.only(start: 20, end: 20),
                child: Container(
                  height: 18,
                  width: 140,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  // Amendment #10: directional padding.
                  padding:
                      const EdgeInsetsDirectional.only(start: 20, end: 20),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  // Amendment #1: skeleton cards also at 176px.
                  itemBuilder: (_, __) =>
                      _SkeletonCard(color: shimmerColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final Color color;

  const _SkeletonCard({required this.color});

  @override
  Widget build(BuildContext context) {
    // Amendment #1: match the real card width of 176px.
    return Container(
      width: 176,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
