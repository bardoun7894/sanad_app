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
/// Picks ONE random article + ONE random podcast + ONE random video, so the
/// "Picked for you" row always shows a balanced mix of all three formats
/// (instead of three items of the same kind).
/// Deterministic per calendar day — refreshes every 24h or when CMS updates.
final moodBasedRecommendationsProvider = FutureProvider<List<ContentItem>>((
  ref,
) async {
  ref.watch(contentRevisionProvider);
  ref.watch(_dailySeedProvider);
  final db = FirebaseFirestore.instance;
  final seed = ref.read(_dailySeedProvider);

  ContentItem? pickOne(List<ContentItem> items, int salt) {
    if (items.isEmpty) return null;
    final rng = Random(seed + salt);
    return items[rng.nextInt(items.length)];
  }

  // 1. Pool of recent articles
  final articles = <ContentItem>[];
  try {
    final snapshot = await db
        .collection('content')
        .where('type', isEqualTo: 'article')
        .where('is_published', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .limit(15)
        .get();
    articles.addAll(
      snapshot.docs.map(
        (doc) => ContentItem.fromJson({'id': doc.id, ...doc.data()}),
      ),
    );
  } catch (_) {}

  // 2. Pool of recent videos — Sanad Tube playlist only (distinct from
  // the Sanad Podcast playlist used for the podcast slot below, so the
  // video and podcast picks never collide).
  final videos = <ContentItem>[];
  try {
    final v = await ref.watch(sanadTubeProvider.future);
    videos.addAll(v.take(10));
  } catch (_) {}

  // 3. Pool of recent podcasts
  final podcasts = <ContentItem>[];
  try {
    final p = await ref.watch(sanadPodcastProvider.future);
    podcasts.addAll(p.take(10));
  } catch (_) {}

  // One pick from each pool — different salt per type so the choices feel
  // independent. Skip a slot if its pool is empty.
  return [
    pickOne(articles, 1),
    pickOne(podcasts, 2),
    pickOne(videos, 3),
  ].whereType<ContentItem>().toList();
});
