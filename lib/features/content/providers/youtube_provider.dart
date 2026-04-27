import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import '../services/youtube_service.dart';

/// Provider for Sanad Tube videos (playlist PLvz7o6Rxv9iBASvocqCB7GH5IMvHz---T).
final sanadTubeProvider = FutureProvider<List<ContentItem>>((ref) async {
  ref.keepAlive();
  final service = ref.watch(youtubeServiceProvider);
  return service.getSanadTubeVideos(limit: 15);
});

/// Provider for Sanad Podcast episodes (playlist PLvz7o6Rxv9iDkB_C7qeejg5_IY8RMCUdZ).
final sanadPodcastProvider = FutureProvider<List<ContentItem>>((ref) async {
  ref.keepAlive();
  final service = ref.watch(youtubeServiceProvider);
  return service.getSanadPodcastVideos(limit: 15);
});

/// Legacy provider — still used by home screen for the general YouTube section.
final youtubeVideosProvider = FutureProvider<List<ContentItem>>((ref) async {
  ref.keepAlive();
  final service = ref.watch(youtubeServiceProvider);
  return service.getChannelVideos(limit: 10);
});

/// Provider for the latest video from the YouTube channel (for home page).
final latestYoutubeVideoProvider = FutureProvider<ContentItem?>((ref) async {
  final videos = await ref.watch(youtubeVideosProvider.future);
  if (videos.isEmpty) return null;
  return videos.first;
});
