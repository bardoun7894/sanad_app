import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../content/models/content_models.dart';
import '../../content/providers/content_provider.dart';
import '../../content/providers/youtube_provider.dart';

/// Daily seed provider — changes once per calendar day so the shuffle
/// is deterministic for the whole day but different tomorrow.
final _dailySeedProvider = Provider<int>((ref) {
  final now = DateTime.now();
  return now.year * 10000 + now.month * 100 + now.day;
});

/// Provider for daily randomized recommendations.
/// Fetches a pool of articles, videos and podcasts, then shuffles them
/// with a daily seed and returns the top 3. Refreshes automatically
/// every 24 hours (seed change) and when CMS content is updated.
final moodBasedRecommendationsProvider = FutureProvider<List<ContentItem>>((
  ref,
) async {
  ref.watch(contentRevisionProvider);
  ref.watch(_dailySeedProvider);
  final db = FirebaseFirestore.instance;

  final pool = <ContentItem>[];

  // 1. Fetch up to 15 published articles from Firestore
  try {
    final snapshot = await db
        .collection('content')
        .where('type', isEqualTo: 'article')
        .where('is_published', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .limit(15)
        .get();

    pool.addAll(
      snapshot.docs.map(
        (doc) => ContentItem.fromJson({'id': doc.id, ...doc.data()}),
      ),
    );
  } catch (_) {}

  // 2. Fetch up to 10 latest videos from YouTube channel
  try {
    final videos = await ref.watch(youtubeVideosProvider.future);
    if (videos.isNotEmpty) {
      pool.addAll(videos.take(10));
    }
  } catch (_) {}

  // 3. Fetch up to 10 latest podcasts from Sanad Podcast playlist
  try {
    final podcasts = await ref.watch(sanadPodcastProvider.future);
    if (podcasts.isNotEmpty) {
      pool.addAll(podcasts.take(10));
    }
  } catch (_) {}

  if (pool.isEmpty) return [];

  // Deterministic daily shuffle using the calendar-day seed
  final seed = ref.read(_dailySeedProvider);
  final rng = Random(seed);
  pool.shuffle(rng);

  // Return top 3 random recommendations
  return pool.take(3).toList();
});
