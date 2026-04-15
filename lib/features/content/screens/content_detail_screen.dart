import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/content_share_utils.dart';
import '../models/content_models.dart';
import 'youtube_player_screen.dart';

class ContentDetailScreen extends ConsumerWidget {
  final ContentItem item;

  const ContentDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    // If it's a YouTube video, redirect to the player screen
    if (item.type == 'video' && item.isYouTubeVideo) {
      return YouTubePlayerScreen(content: item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.category ?? item.type,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ContentShareUtils.shareContent(item),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(item.thumbnailUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              item.title,
              style: AppTypography.headingMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (item.category != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (item.formattedDuration.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    item.formattedDuration,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Text(
              item.description,
              style: AppTypography.bodyLarge.copyWith(
                color: isDark ? Colors.white70 : AppColors.textPrimary,
                height: 1.7,
              ),
            ),
            if (item.contentUrl != null && item.contentUrl!.isNotEmpty) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(item.contentUrl!),
                  icon: Icon(_getUrlIcon()),
                  label: Text(_getUrlLabel(s)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Share Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ShareButton(
                  icon: Icons.share,
                  label: 'مشاركة',
                  onTap: () => ContentShareUtils.shareContent(item),
                ),
                const SizedBox(width: 16),
                _ShareButton(
                  icon: Icons.chat,
                  label: 'واتساب',
                  color: const Color(0xFF25D366),
                  onTap: () => ContentShareUtils.shareViaWhatsApp(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getUrlIcon() {
    switch (item.type) {
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
    switch (item.type) {
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
