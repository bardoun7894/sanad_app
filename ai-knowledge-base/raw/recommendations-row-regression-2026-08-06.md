# "اخترنا لك" home row — collapsed to one fixed card (2026-08-06)

## Symptom (client, WhatsApp)

After release `1.0.18+42`, the home "اخترنا لك" (Picked for you) section stopped
showing a random mix and displayed a single, unchanging article. The client also
asked why random exercises were no longer shown.

## Root cause

Two faults introduced by the "drop the 30-item cap" change in `2af7e90`:

1. `youtube_service.dart` — removing the cap turned one request per playlist into
   up to 10 paged requests, but the `catch` block returned `[]`, discarding every
   page already fetched. A single slow/failed page on a mobile network emptied
   both Sanad Tube and Sanad Podcast.
2. `recommendation_provider.dart` — the row hard-mapped one slot per pool
   (article / podcast / video), so an empty pool meant a missing card. With both
   YouTube pools dead the section degraded to a single article. The daily seed
   then kept that one article fixed for the whole day.

Exercises were never in this provider in any reachable commit — the client's
request to show them was new work, not a regression.

## Data verified (read-only, `scripts/inspect-content-pool.js`)

- `content`: 70 docs — 40 article, 28 exercise, 2 video; all published, all have
  `created_at` (so the `orderBy` drop-docs pattern does NOT apply here).
- `api_keys` collection is empty → `AppConfig.youtubeApiKey` resolves from the
  `.env` asset (declared in `pubspec.yaml`), not Firestore.
- Both YouTube playlists return data and the key/quota are healthy from a laptop,
  so the failure is network-conditional on device, not a dead key.

## Fix (`b0af83a`, then `1e8b472`)

- `youtube_service`: return the pages that did arrive instead of `[]` on error.
- `recommendation_provider`: restored the pre-`f1eb1eb` algorithm the owner
  wanted — merge all pools, dedupe, `shuffle(Random(dailySeed))`, `take(3)` —
  with exercises added to the pool and a 15-item ceiling per pool so 40 articles
  can't drown out the 15 podcasts / 15 videos.
- Pools now come from `blogProvider` / `exercisesProvider` (shared cache with the
  blog and exercises screens, uncapped since the release) instead of a private
  Firestore query.
- Every `ref.watch` hoisted above the first `await` — unsupported after an await
  point in Riverpod 2.6.1.
- Silent `catch (_) {}` replaced with `kDebugMode` logging.
- Pure selection extracted to `pickRecommendations()` with 9 unit tests in
  `test/features/home/recommendation_pick_test.dart`, including the
  both-YouTube-pools-empty regression.

Shipped as `1.0.19+43` (`app-release.aab` built).

## Lesson

Unbounded pagination behind a single try/catch is a resilience downgrade, not
just a slower fetch: it multiplies the failure surface by the page count and
throws away partial success. Any UI row that maps one fixed slot per data source
must degrade by back-filling or pooling, otherwise one dead source silently
rewrites the layout.
