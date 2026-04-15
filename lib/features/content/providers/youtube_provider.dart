import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import '../services/youtube_service.dart';

/// Provider for latest YouTube channel videos.
/// Cached with keepAlive to avoid refetching on every rebuild.
final youtubeVideosProvider = FutureProvider<List<ContentItem>>((ref) async {
  ref.keepAlive();
  final service = ref.watch(youtubeServiceProvider);
  return service.getChannelVideos(limit: 10);
});

/// Provider for the latest video from the YouTube channel (for home page).
final latestYoutubeVideoProvider = FutureProvider<ContentItem?>((ref) async {
  final videos = await ref.watch(youtubeVideosProvider.future);
  if (videos.isEmpty) return null;
  // First video is the latest
  return videos.first;
});

/// Provider for the second latest video (used as podcast on home page).
final latestYoutubePodcastProvider = FutureProvider<ContentItem?>((ref) async {
  final videos = await ref.watch(youtubeVideosProvider.future);
  if (videos.length < 2) return null;
  // Return second video as "podcast" content
  final video = videos[1];
  return ContentItem(
    id: video.id,
    title: video.title,
    description: video.description,
    type: 'podcast', // Display as podcast card
    category: video.category,
    contentUrl: video.contentUrl,
    thumbnailUrl: video.thumbnailUrl,
    createdAt: video.createdAt,
  );
});
