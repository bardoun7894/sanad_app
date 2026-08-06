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
const int _kRecommendationSlots = 4;

/// Provider for daily randomized recommendations.
/// Picks ONE random article + ONE random exercise + ONE random podcast +
/// ONE random video, so the "Picked for you" row always shows a balanced
/// mix of formats instead of several items of the same kind.
///
/// If a pool is empty (YouTube unreachable, no exercises published yet) the
/// remaining slots are back-filled from the pools that DID load, so the row
/// never collapses to a single card.
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

/// Picks one item per pool, then back-fills empty slots from the pools that
/// did load, so the row keeps showing [slots] cards even when a pool is dead.
/// Pure and deterministic for a given [seed] — unit tested.
@visibleForTesting
List<ContentItem> pickRecommendations(
  List<List<ContentItem>> pools,
  int seed, {
  int slots = _kRecommendationSlots,
}) {
  final picked = <ContentItem>[];
  final usedIds = <String>{};

  /// Takes one not-yet-picked item from [items].
  bool takeOne(List<ContentItem> items, int salt) {
    final available = items.where((i) => !usedIds.contains(i.id)).toList();
    if (available.isEmpty) return false;
    final rng = Random(seed * 31 + salt);
    final choice = available[rng.nextInt(available.length)];
    picked.add(choice);
    usedIds.add(choice.id);
    return true;
  }

  // One pick per pool — different salt per type so the choices feel
  // independent. Skip a slot if its pool is empty.
  for (var i = 0; i < pools.length && picked.length < slots; i++) {
    takeOne(pools[i], i + 1);
  }

  // Back-fill: if some pools were empty, keep drawing from the ones that
  // loaded until the row is full again (previously the section could show a
  // single article whenever YouTube failed).
  var salt = 100;
  while (picked.length < slots) {
    final before = picked.length;
    for (final pool in pools) {
      if (picked.length >= slots) break;
      takeOne(pool, salt++);
    }
    if (picked.length == before) break; // every pool exhausted
  }

  // Shuffle the final order so the same content type isn't always on top.
  picked.shuffle(Random(seed));
  return picked;
}
