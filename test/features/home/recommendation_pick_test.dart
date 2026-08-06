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

    test('fills every slot when the pools are loaded', () {
      expect(pickRecommendations(all, 20260806).length, 3);
    });

    test('keeps filling the row when both YouTube pools are dead', () {
      // The reported regression: the row used to collapse to one article.
      final picked = pickRecommendations(
        [articles, exercises, const [], const []],
        20260806,
      );
      expect(picked.length, 3);
      expect(picked.map((c) => c.id).toSet().length, 3, reason: 'no repeats');
    });

    test('draws exercises — the type the row used to skip entirely', () {
      // Over a month of seeds an exercise must surface; the old provider
      // could never show one because exercises were not in the pool.
      final month = List.generate(
        31,
        (i) => pickRecommendations(all, 20260801 + i),
      );
      expect(
        month.any((day) => day.any((c) => c.type == 'exercise')),
        isTrue,
      );
    });

    test('mixes formats across the month instead of one fixed type', () {
      final types = <String>{};
      for (var day = 20260801; day <= 20260831; day++) {
        types.addAll(pickRecommendations(all, day).map((c) => c.type));
      }
      expect(types, containsAll(<String>['article', 'exercise']));
      expect(types.length, greaterThanOrEqualTo(3));
    });

    test('caps each pool so 40 articles cannot drown out the rest', () {
      // 15 per pool × 4 pools = 60 candidates, not 98.
      final picked = pickRecommendations(all, 20260806, slots: 100);
      expect(picked.length, 60);
      expect(picked.where((c) => c.type == 'article').length, 15);
    });

    test('returns whatever exists when only one small pool loads', () {
      expect(
        pickRecommendations(
          [_pool('article', 2), const [], const [], const []],
          20260806,
        ).length,
        2,
      );
    });

    test('returns empty when nothing is published', () {
      expect(
        pickRecommendations([const [], const [], const []], 20260806),
        isEmpty,
      );
    });

    test('stable within a day, rotates across days', () {
      final today = pickRecommendations(all, 20260806);
      expect(
        today.map((c) => c.id),
        pickRecommendations(all, 20260806).map((c) => c.id),
      );

      final week = List.generate(
        7,
        (i) => pickRecommendations(all, 20260807 + i).map((c) => c.id).join(),
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
  });
}
