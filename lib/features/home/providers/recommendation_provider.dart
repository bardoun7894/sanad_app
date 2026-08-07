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

/// How many cards the "اخترنا لك" row shows — one per content type.
const int _kRecommendationSlots = 4;

/// Per-type ceiling on how much of each pool enters the back-fill draw, so one
/// big pool (40 articles) can't drown out the smaller ones.
const int _kPerPoolCeiling = 15;

/// Provider for daily randomized recommendations.
///
/// Picks ONE random article + ONE random exercise + ONE random podcast + ONE
/// random video, so the row always shows a balanced mix of every format
/// instead of several items of the same kind — the pre-1.0.18 behaviour the
/// owner asked to have back on 2026-08-07, plus exercises as a fourth card.
///
/// A dead pool (YouTube unreachable) costs the row that format, never a card:
/// the empty slot is back-filled from the pools that did load, so the section
/// can't collapse to a single card the way it did in 1.0.18.
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

/// Takes one random item from each pool, in pool order (article, exercise,
/// podcast, video), so every format that loaded gets a card. Any slot left
/// over — because a pool came back empty — is back-filled from the pools that
/// did load, capped at [_kPerPoolCeiling] each so the largest one can't
/// dominate. Pure and deterministic for a given [seed] — unit tested.
@visibleForTesting
List<ContentItem> pickRecommendations(
  List<List<ContentItem>> pools,
  int seed, {
  int slots = _kRecommendationSlots,
}) {
  final picked = <ContentItem>[];
  final seenIds = <String>{};

  // One pick per type. A different salt per pool keeps the choices feeling
  // independent rather than all landing on the same index.
  for (var i = 0; i < pools.length && picked.length < slots; i++) {
    final items = pools[i];
    if (items.isEmpty) continue;
    final item = items[Random(seed + i + 1).nextInt(items.length)];
    if (seenIds.add(item.id)) picked.add(item);
  }

  if (picked.length >= slots) return picked;

  // Back-fill: a dead pool costs the row a format, not a card.
  final spare = <ContentItem>[];
  for (final items in pools) {
    for (final item in items.take(_kPerPoolCeiling)) {
      if (!seenIds.contains(item.id)) spare.add(item);
    }
  }
  spare.shuffle(Random(seed));
  for (final item in spare) {
    if (picked.length >= slots) break;
    if (seenIds.add(item.id)) picked.add(item);
  }

  return picked;
}
