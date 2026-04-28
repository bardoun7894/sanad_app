import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';
import 'content_detail_screen.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/expandable_text.dart';

class PodcastScreen extends ConsumerWidget {
  const PodcastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final podcastsAsync = ref.watch(podcastProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.podcast,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: podcastsAsync.when(
        loading: () => LoadingStateWidget(message: s.loadingContent),
        error: (e, _) => ErrorStateWidget(
          message: s.errorLoadingData,
          retryLabel: s.retry,
          onRetry: () => ref.invalidate(podcastProvider),
        ),
        data: (episodes) {
          if (episodes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.mic_none_outlined,
              message: s.noContentYet,
              description: s.contentComingSoon,
              iconColor: Colors.red,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(podcastProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: episodes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildEpisodeCard(context, episodes[index], isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpisodeCard(
    BuildContext context,
    ContentItem item,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        if (item.contentUrl != null && item.contentUrl!.isNotEmpty) {
          _launchUrl(item.contentUrl!);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ContentDetailScreen(item: item)),
          );
        }
      },
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
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.headphones, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.localizedTitle(context),
                    style: AppTypography.headingSmall.copyWith(
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.category != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.category!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (item.localizedDescription(context).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ExpandableText(
                      text: item.localizedDescription(context),
                      maxLines: 2,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
