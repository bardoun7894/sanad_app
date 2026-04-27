import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../content/models/content_models.dart';
import '../../content/providers/content_provider.dart';
import '../../content/providers/youtube_provider.dart';
import '../home_screen.dart';

/// Provider for mood-based recommendations:
/// - 1 article from Firestore (blog)
/// - 1 video from YouTube channel
/// - 1 podcast from YouTube channel (second latest video)
final moodBasedRecommendationsProvider = FutureProvider<List<ContentItem>>((
  ref,
) async {
  ref.watch(contentRevisionProvider);
  final selectedMood = ref.watch(selectedMoodProvider);
  final db = FirebaseFirestore.instance;
  final moodTag = selectedMood?.name.toLowerCase();

  final results = <ContentItem>[];

  // 1. Fetch one article from Firestore (blog)
  try {
    if (moodTag != null) {
      final moodQuery = db
          .collection('content')
          .where('type', isEqualTo: 'article')
          .where('is_published', isEqualTo: true)
          .where('mood_tags', arrayContains: moodTag)
          .limit(1);

      final moodSnapshot = await moodQuery.get();
      if (moodSnapshot.docs.isNotEmpty) {
        final doc = moodSnapshot.docs.first;
        results.add(ContentItem.fromJson({'id': doc.id, ...doc.data()}));
      }
    }

    // Fallback: any published article
    if (results.isEmpty) {
      final fallbackQuery = db
          .collection('content')
          .where('type', isEqualTo: 'article')
          .where('is_published', isEqualTo: true)
          .limit(1);

      final snapshot = await fallbackQuery.get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        results.add(ContentItem.fromJson({'id': doc.id, ...doc.data()}));
      }
    }
  } catch (_) {}

  // 2. Fetch latest video from YouTube channel
  try {
    final latestVideo = await ref.watch(latestYoutubeVideoProvider.future);
    if (latestVideo != null) {
      results.add(latestVideo);
    }
  } catch (_) {}

  // 3. Fetch latest podcast from Sanad Podcast playlist
  try {
    final podcasts = await ref.watch(sanadPodcastProvider.future);
    if (podcasts.isNotEmpty) {
      results.add(podcasts.first);
    }
  } catch (_) {}

  return results;
});
