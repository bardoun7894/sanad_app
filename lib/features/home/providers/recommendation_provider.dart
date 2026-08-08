import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/system_settings_provider.dart';
import '../../content/models/content_models.dart';
import '../../content/providers/content_provider.dart';
import '../../content/providers/youtube_provider.dart';

/// Fallback rotation interval used before the admin setting has loaded.
const Duration _kDefaultRotationInterval = Duration(minutes: 10);

int _windowFor(DateTime t, Duration interval) =>
    t.millisecondsSinceEpoch ~/ interval.inMilliseconds;

/// How often the "اخترنا لك" row re-draws, driven by the admin dashboard
/// (`system_settings/config.recommendation_rotation_minutes`). Falls back to
/// 10 minutes until the setting arrives, and while it is loading or errored,
/// so the row never depends on Firestore being reachable.
final rotationIntervalProvider = Provider<Duration>((ref) {
  final minutes = ref
      .watch(systemSettingsProvider)
      .valueOrNull
      ?.recommendationRotationMinutes;
  return minutes == null ? _kDefaultRotationInterval : Duration(minutes: minutes);
});

/// Rotation seed — the index of the current rotation window since epoch.
/// Stable inside a window, different in the next one.
///
/// This is a stream rather than a plain value because a `Provider` would only
/// be re-read when something else rebuilt it: the row would sit on the same
/// four cards until the user restarted the app. The stream fires exactly on
/// each window boundary, so the row re-draws on its own while the app is open.
/// Changing the interval from the dashboard rebuilds this provider, so a new
/// cadence takes effect without an app restart.
final _rotationSeedProvider = StreamProvider<int>((ref) async* {
  final interval = ref.watch(rotationIntervalProvider);

  while (true) {
    final now = DateTime.now();
    final window = _windowFor(now, interval);
    yield window;

    // Sleep until the next boundary rather than polling on an interval, so a
    // long-lived session can't drift out of step with the window numbering.
    final nextBoundary = (window + 1) * interval.inMilliseconds;
    await Future<void>.delayed(
      Duration(milliseconds: nextBoundary - now.millisecondsSinceEpoch),
    );
  }
});

/// How many cards the "اخترنا لك" row shows — one per content type.
const int _kRecommendationSlots = 4;

/// Per-type ceiling on how much of each pool enters the back-fill draw, so one
/// big pool (40 articles) can't drown out the smaller ones.
const int _kPerPoolCeiling = 15;

/// Provider for the rotating "اخترنا لك" recommendations.
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
/// Re-drawn every [_kRotationInterval] (10 minutes) and whenever the CMS
/// updates. The pools come from cached providers, so a rotation re-picks from
/// lists already in memory rather than re-reading Firestore or YouTube.
final moodBasedRecommendationsProvider = FutureProvider<List<ContentItem>>((
  ref,
) async {
  ref.watch(contentRevisionProvider);
  // Fall back to the current window if the first tick hasn't landed yet, so
  // the row renders immediately on a cold start instead of waiting 10 minutes.
  final seed = ref.watch(_rotationSeedProvider).valueOrNull ??
      _windowFor(DateTime.now(), ref.watch(rotationIntervalProvider));

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
