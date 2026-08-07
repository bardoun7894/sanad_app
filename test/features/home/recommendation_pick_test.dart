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

    test('every day of the month carries all four formats', () {
      // The owner's ask: video, podcast and exercise must always be
      // represented, not left to a shuffle that can hand back four articles.
      for (var day = 20260801; day <= 20260831; day++) {
        expect(
          pickRecommendations(all, day).map((c) => c.type).toSet(),
          <String>{'article', 'exercise', 'podcast', 'video'},
          reason: 'day $day dropped a format',
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

    test('stable within a day, rotates across days', () {
      final today = pickRecommendations(all, 20260807);
      expect(
        today.map((c) => c.id),
        pickRecommendations(all, 20260807).map((c) => c.id),
      );

      final week = List.generate(
        7,
        (i) => pickRecommendations(all, 20260808 + i).map((c) => c.id).join(),
      );
      expect(week.toSet().length, greaterThan(1),
          reason: 'picks must change from day to day');
      expect(week.contains(today.map((c) => c.id).join()), isFalse);
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
