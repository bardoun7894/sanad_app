import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/content_share_utils.dart';
import '../../../core/widgets/expandable_text.dart';
import '../../../routes/app_routes.dart';
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

    final showThumbnail =
        item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: showThumbnail ? 280 : 120,
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
              background: showThumbnail
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
                    item.localizedTitle(context),
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
                  if (item.localizedDescription(context).isNotEmpty)
                    ExpandableText(
                      text: item.localizedDescription(context),
                      maxLines: _maxLines,
                      style: textStyle,
                      isDark: isDark,
                      expandLabel: s.showMore,
                      collapseLabel: s.showLess,
                    ),

                  const SizedBox(height: 32),

                  // Action buttons (only for podcast/video — articles
                  // and exercises are read in-place).
                  if (item.contentUrl != null &&
                      item.contentUrl!.isNotEmpty &&
                      const {
                        'podcast',
                        'video',
                      }.contains(widget.item.type)) ...[
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

                  const SizedBox(height: 24),

                  // Contact Support button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.userSupportChat),
                      icon: const Icon(Icons.headset_mic_outlined, size: 18),
                      label: Text(s.contactSanadTherapySupport),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Similar Articles button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSimilarArticles(item.category),
                      icon: const Icon(Icons.article_outlined, size: 18),
                      label: Text(s.similarArticles),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
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

  void _showSimilarArticles(String? category) {
    final s = ref.read(stringsProvider);
    final hasCategory = category != null && category.isNotEmpty;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  Text(
                    hasCategory
                        ? '${s.similarArticles} — $category'
                        : s.similarArticles,
                    style: AppTypography.headingMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _SimilarArticlesList(
                      category: hasCategory ? category : null,
                      type: widget.item.type,
                      currentId: widget.item.id,
                      emptyText: s.noSimilarArticlesFound,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

class _SimilarArticlesList extends ConsumerWidget {
  final String? category;
  final String type;
  final String currentId;
  final String emptyText;

  const _SimilarArticlesList({
    required this.category,
    required this.type,
    required this.currentId,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('content')
        .where('is_published', isEqualTo: true)
        .where('type', isEqualTo: type);
    if (category != null && category!.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('created_at', descending: true).limit(20).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final articles = snapshot.data!.docs
            .where((doc) => doc.id != currentId)
            .map((doc) => ContentItem.fromFirestore(doc))
            .toList();

        if (articles.isEmpty) {
          return Center(
            child: Text(
              emptyText,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: articles.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final article = articles[index];
            return ListTile(
              leading: article.thumbnailUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        article.thumbnailUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.article_outlined,
                              color: AppColors.primary),
                        ),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.article_outlined,
                          color: AppColors.primary),
                    ),
              title: Text(
                article.localizedTitle(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              subtitle: article.category != null
                  ? Text(
                      article.category!,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContentDetailScreen(item: article),
                  ),
                );
              },
            );
          },
        );
      },
    );
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
