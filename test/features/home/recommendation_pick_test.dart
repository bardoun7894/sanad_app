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

    test('shows one card of each type when every pool is loaded', () {
      final picked = pickRecommendations(
        [articles, exercises, podcasts, videos],
        20260806,
      );

      expect(picked.length, 4);
      expect(
        picked.map((c) => c.type).toSet(),
        {'article', 'exercise', 'podcast', 'video'},
      );
    });

    test('includes an exercise — the type the section used to skip', () {
      final picked = pickRecommendations(
        [articles, exercises, podcasts, videos],
        20260806,
      );
      expect(picked.any((c) => c.type == 'exercise'), isTrue);
    });

    test('back-fills instead of collapsing to one card when YouTube is dead',
        () {
      // Both YouTube pools empty — the regression the client reported.
      final picked = pickRecommendations(
        [articles, exercises, const [], const []],
        20260806,
      );

      expect(picked.length, 4);
      expect(picked.map((c) => c.id).toSet().length, 4, reason: 'no repeats');
    });

    test('returns whatever exists when only one small pool loads', () {
      final picked = pickRecommendations(
        [_pool('article', 2), const [], const [], const []],
        20260806,
      );
      expect(picked.length, 2);
    });

    test('returns empty when nothing is published', () {
      expect(
        pickRecommendations([const [], const [], const []], 20260806),
        isEmpty,
      );
    });

    test('same day is stable, different days rotate the picks', () {
      final pools = [articles, exercises, podcasts, videos];
      final today = pickRecommendations(pools, 20260806);
      final againToday = pickRecommendations(pools, 20260806);
      expect(today.map((c) => c.id), againToday.map((c) => c.id));

      // Across a week at least one day must differ, otherwise the row is
      // "stuck on one fixed article" again.
      final week = [
        20260807,
        20260808,
        20260809,
        20260810,
        20260811,
        20260812,
      ].map((s) => pickRecommendations(pools, s).map((c) => c.id).join(','));

      expect(
        week.toSet().length,
        greaterThan(1),
        reason: 'picks must change from day to day',
      );
      expect(
        week.every((day) => day == today.map((c) => c.id).join(',')),
        isFalse,
      );
    });

    test('never repeats an item within a single row', () {
      for (var day = 20260801; day <= 20260831; day++) {
        final picked = pickRecommendations(
          [articles, exercises, podcasts, videos],
          day,
        );
        expect(picked.map((c) => c.id).toSet().length, picked.length);
      }
    });
  });
}
