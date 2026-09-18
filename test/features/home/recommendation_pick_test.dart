import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/content/models/content_models.dart';
import 'package:sanad_app/features/home/providers/recommendation_provider.dart';

ContentItem _item(String id, String type) =>
    ContentItem(id: id, title: id, description: '', type: type);

List<ContentItem> _pool(String type, int count) =>
    List.generate(count, (i) => _item('${type}_$i', type));

void main() {
  group('pickRecommendations', () {
    final articles = _pool('article', 40);
    final exercises = _pool('exercise', 28);
    final podcasts = _pool('podcast', 15);
    final videos = _pool('video', 15);
    final all = [articles, exercises, podcasts, videos];

    test('shows one card per type when every pool is loaded', () {
      final picked = pickRecommendations(all, 20260807);
      expect(picked.length, 4);
      expect(
        picked.map((c) => c.type),
        <String>['article', 'exercise', 'podcast', 'video'],
      );
    });

    test('every rotation carries all four formats', () {
      // The owner's ask: video, podcast and exercise must always be
      // represented, not left to a shuffle that can hand back four articles.
      for (var window = 2938405; window < 2938405 + 200; window++) {
        expect(
          pickRecommendations(all, window).map((c) => c.type).toSet(),
          <String>{'article', 'exercise', 'podcast', 'video'},
          reason: 'window $window dropped a format',
        );
      }
    });

    test('keeps filling the row when both YouTube pools are dead', () {
      // The 1.0.18 regression: the row collapsed to one article.
      final picked = pickRecommendations(
        [articles, exercises, const [], const []],
        20260807,
      );
      expect(picked.length, 4);
      expect(picked.map((c) => c.id).toSet().length, 4, reason: 'no repeats');
    });

    test('returns whatever exists when only one small pool loads', () {
      expect(
        pickRecommendations(
          [_pool('article', 2), const [], const [], const []],
          20260807,
        ).length,
        2,
      );
    });

    test('returns empty when nothing is published', () {
      expect(
        pickRecommendations([const [], const [], const [], const []], 20260807),
        isEmpty,
      );
    });

    test('stable within a window, rotates to the next one', () {
      // The seed is the index of the current 10-minute window since epoch, so
      // the row must not change inside a window but must change when it ticks.
      const window = 2938405;
      final current = pickRecommendations(all, window);
      expect(
        current.map((c) => c.id),
        pickRecommendations(all, window).map((c) => c.id),
        reason: 'picks must not change inside one 10-minute window',
      );

      final nextHour = List.generate(
        6,
        (i) => pickRecommendations(all, window + 1 + i).map((c) => c.id).join(),
      );
      expect(nextHour.toSet().length, greaterThan(1),
          reason: 'picks must change from window to window');
      expect(nextHour.contains(current.map((c) => c.id).join()), isFalse);
    });

    test('keeps rotating across a full day of windows', () {
      // 144 windows in 24h — the row should keep producing fresh combinations
      // rather than cycling through two or three.
      const start = 2938405;
      final combos = List.generate(
        144,
        (i) => pickRecommendations(all, start + i).map((c) => c.id).join(),
      ).toSet();
      expect(combos.length, greaterThan(100),
          reason: 'rotation must not collapse onto a few repeats');
    });

    test('never repeats an item within a single row', () {
      for (var day = 20260801; day <= 20260831; day++) {
        final picked = pickRecommendations(all, day);
        expect(picked.map((c) => c.id).toSet().length, picked.length);
      }
    });

    test('draws from the whole pool, not just the newest few', () {
      // The 30-item cap is gone, so older articles must stay reachable.
      final indices = <int>{};
      for (var day = 20260101; day <= 20260131; day++) {
        final pick = pickRecommendations(all, day).first;
        indices.add(int.parse(pick.id.split('_').last));
      }
      expect(indices.any((i) => i > 15), isTrue);
    });
  });
}
