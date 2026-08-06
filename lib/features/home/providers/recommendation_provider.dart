import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../content/models/content_models.dart';
import '../../content/providers/content_provider.dart';
import '../../content/providers/youtube_provider.dart';

/// Daily seed provider — changes once per calendar day so the shuffle
/// is deterministic for the whole day but different tomorrow.
final _dailySeedProvider = Provider<int>((ref) {
  final now = DateTime.now();
  return now.year * 10000 + now.month * 100 + now.day;
});

/// How many cards the "اخترنا لك" row shows.
const int _kRecommendationSlots = 3;

/// Per-type ceiling on how much of each pool enters the shuffle, so one big
/// pool (40 articles) can't drown out the smaller ones.
const int _kPerPoolCeiling = 15;

/// Provider for daily randomized recommendations.
///
/// Builds one pool out of articles, exercises, podcasts and videos, shuffles
/// it with the calendar-day seed and returns the top [_kRecommendationSlots]
/// — the original behaviour the owner asked for: a genuinely random mix, not
/// a fixed one-card-per-type layout.
///
/// A dead pool (YouTube unreachable) simply contributes nothing; the row is
/// still filled from the pools that did load, so it can never collapse to a
/// single card.
///
/// Deterministic per calendar day — refreshes every 24h or when CMS updates.
final moodBasedRecommendationsProvider = FutureProvider<List<ContentItem>>((
  ref,
) async {
  ref.watch(contentRevisionProvider);
  final seed = ref.watch(_dailySeedProvider);

  // Subscribe to every pool BEFORE the first await — `ref.watch` after an
  // await point is unsupported in Riverpod 2.x, and this also lets the four
  // fetches run in parallel instead of one after the other. These are the
  // same provider instances the blog / exercises / Sanad Tube / Sanad
  // Podcast screens use, so the lists come from cache, not extra reads.
  final articlesFuture = ref.watch(blogProvider.future);
  final exercisesFuture = ref.watch(exercisesProvider.future);
  final podcastFuture = ref.watch(sanadPodcastProvider.future);
  final tubeFuture = ref.watch(sanadTubeProvider.future);

  Future<List<ContentItem>> guard(
    String label,
    Future<List<ContentItem>> future,
  ) async {
    try {
      return await future;
    } catch (e) {
      // Never let one dead pool take the whole row down with it.
      if (kDebugMode) {
        debugPrint('[recommendations] $label pool failed: $e');
      }
      return const [];
    }
  }

  // Four independent pools: articles, exercises, podcasts, videos.
  // Sanad Tube (video) and Sanad Podcast are distinct playlists, so the
  // video and podcast picks never collide.
  final pools = await Future.wait([
    guard('article', articlesFuture),
    guard('exercise', exercisesFuture),
    guard('podcast', podcastFuture),
    guard('video', tubeFuture),
  ]);

  return pickRecommendations(pools, seed);
});

/// Merges every pool into one list, shuffles it with [seed] and returns the
/// first [slots] items — the original random-mix behaviour. Each pool is
/// capped at [_kPerPoolCeiling] first so the largest one doesn't dominate.
/// Pure and deterministic for a given [seed] — unit tested.
@visibleForTesting
List<ContentItem> pickRecommendations(
  List<List<ContentItem>> pools,
  int seed, {
  int slots = _kRecommendationSlots,
}) {
  final pool = <ContentItem>[];
  final seenIds = <String>{};

  for (final items in pools) {
    for (final item in items.take(_kPerPoolCeiling)) {
      if (seenIds.add(item.id)) pool.add(item);
    }
  }

  if (pool.isEmpty) return const [];

  pool.shuffle(Random(seed));
  return pool.take(slots).toList();
}
