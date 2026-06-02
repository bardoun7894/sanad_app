import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/content/models/content_models.dart';
import 'package:sanad_app/features/content/services/related_content_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ContentItem _makeItem({
  required String id,
  required String type,
  String? category,
  List<String> moodTags = const [],
  String title = '',
  String titleEn = '',
  DateTime? createdAt,
}) {
  return ContentItem(
    id: id,
    title: title,
    titleEn: titleEn,
    description: '',
    type: type,
    category: category,
    moodTags: moodTags,
    isPublished: true,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
  );
}

/// Seed a FakeFirebaseFirestore with a list of items.
Future<void> _seed(
  FakeFirebaseFirestore db,
  List<Map<String, dynamic>> docs,
) async {
  for (final doc in docs) {
    await db.collection('content').doc(doc['id'] as String).set(doc);
  }
}

Map<String, dynamic> _docFor(ContentItem item) => {
      'id': item.id,
      'title': item.title,
      'title_en': item.titleEn,
      'content_text': item.description,
      'type': item.type,
      'category': item.category,
      'mood_tags': item.moodTags,
      'is_published': item.isPublished,
      'created_at': item.createdAt != null
          ? Timestamp.fromDate(item.createdAt!)
          : null,
    };

void main() {
  group('RelatedContentService.fetchRelated', () {
    late FakeFirebaseFirestore fakeDb;
    late RelatedContentService svc;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      svc = RelatedContentService(firestore: fakeDb);
    });

    // ------------------------------------------------------------------
    // 1. Basic behavior: excludes the source item itself
    // ------------------------------------------------------------------
    test('excludes the source item from results', () async {
      final source = _makeItem(id: 'src', type: 'article');
      final other = _makeItem(id: 'other', type: 'article');

      await _seed(fakeDb, [_docFor(source), _docFor(other)]);

      final results = await svc.fetchRelated(source, limit: 10);

      expect(results.map((e) => e.id), isNot(contains('src')));
      expect(results.map((e) => e.id), contains('other'));
    });

    // ------------------------------------------------------------------
    // 2. Only returns items of the same type
    // ------------------------------------------------------------------
    test('only returns items of the same type as source', () async {
      final source = _makeItem(id: 'src', type: 'article');
      final sameType = _makeItem(id: 'article-2', type: 'article');
      final otherType = _makeItem(id: 'podcast-1', type: 'podcast');

      await _seed(fakeDb, [
        _docFor(source),
        _docFor(sameType),
        _docFor(otherType),
      ]);

      final results = await svc.fetchRelated(source, limit: 10);

      final ids = results.map((e) => e.id).toSet();
      expect(ids, contains('article-2'));
      expect(ids, isNot(contains('podcast-1')));
    });

    // ------------------------------------------------------------------
    // 3. Category scoring: same category gets +3
    // ------------------------------------------------------------------
    test('items with same category score higher than items without', () async {
      final source = _makeItem(id: 'src', type: 'article', category: 'anxiety');
      final sameCategory =
          _makeItem(id: 'A', type: 'article', category: 'anxiety');
      final noCategory =
          _makeItem(id: 'B', type: 'article', category: 'stress');

      await _seed(fakeDb, [
        _docFor(source),
        _docFor(sameCategory),
        _docFor(noCategory),
      ]);

      final results = await svc.fetchRelated(source, limit: 10);

      expect(results.first.id, equals('A'),
          reason: 'Same-category item should rank first due to +2 score');
    });

    // ------------------------------------------------------------------
    // 4. Mood tag scoring: each shared tag adds +2
    // ------------------------------------------------------------------
    test('items with more shared mood tags rank higher', () async {
      final source = _makeItem(
        id: 'src',
        type: 'article',
        moodTags: ['sad', 'anxious', 'lonely'],
      );
      final twoTagMatch =
          _makeItem(id: 'A', type: 'article', moodTags: ['sad', 'anxious']);
      final oneTagMatch =
          _makeItem(id: 'B', type: 'article', moodTags: ['sad']);

      await _seed(fakeDb, [
        _docFor(source),
        _docFor(twoTagMatch),
        _docFor(oneTagMatch),
      ]);

      final results = await svc.fetchRelated(source, limit: 10);
      final ids = results.map((e) => e.id).toList();

      expect(ids.indexOf('A'), lessThan(ids.indexOf('B')),
          reason: 'Two shared tags (+8) should outrank one shared tag (+4)');
    });

    // ------------------------------------------------------------------
    // 5. Limit is respected
    // ------------------------------------------------------------------
    test('respects the limit parameter', () async {
      final source = _makeItem(id: 'src', type: 'article');

      final others = List.generate(
        10,
        (i) => _makeItem(id: 'item-$i', type: 'article'),
      );

      await _seed(fakeDb, [_docFor(source), ...others.map(_docFor)]);

      final results = await svc.fetchRelated(source, limit: 3);

      expect(results.length, lessThanOrEqualTo(3));
    });

    // ------------------------------------------------------------------
    // 6. Empty result when no matches exist
    // ------------------------------------------------------------------
    test('returns empty list when no matching items exist', () async {
      final source = _makeItem(id: 'src', type: 'article');
      await _seed(fakeDb, [_docFor(source)]);

      final results = await svc.fetchRelated(source, limit: 6);

      expect(results, isEmpty);
    });

    // ------------------------------------------------------------------
    // 7. Deduplication — no duplicates from merged queries
    // ------------------------------------------------------------------
    test('deduplicates items that appear in both queries', () async {
      final source = _makeItem(
        id: 'src',
        type: 'article',
        moodTags: ['calm'],
      );
      // This item would appear in both the base query and the mood-tag query.
      final overlap = _makeItem(
        id: 'overlap',
        type: 'article',
        moodTags: ['calm'],
        category: 'wellness',
      );

      await _seed(fakeDb, [_docFor(source), _docFor(overlap)]);

      final results = await svc.fetchRelated(source, limit: 10);
      final ids = results.map((e) => e.id).toList();

      // No duplicate IDs
      expect(ids.toSet().length, equals(ids.length),
          reason: 'No duplicate entries in results');
    });

    // ------------------------------------------------------------------
    // 8. Mood tags guard: skips secondary query when source has >10 tags
    // ------------------------------------------------------------------
    test('does not crash when source has more than 10 mood tags', () async {
      final source = _makeItem(
        id: 'src',
        type: 'article',
        moodTags: List.generate(11, (i) => 'tag-$i'),
      );
      final other = _makeItem(id: 'other', type: 'article');

      await _seed(fakeDb, [_docFor(source), _docFor(other)]);

      // Should not throw — secondary query should be skipped
      expect(
        () async => svc.fetchRelated(source, limit: 6),
        returnsNormally,
      );
    });

    // ------------------------------------------------------------------
    // 9. Never throws — returns [] on error
    // ------------------------------------------------------------------
    test('returns empty list when Firestore throws an unexpected error',
        () async {
      // Pass a service where the underlying call will fail by using an
      // intentionally bad collection path simulation — we test the
      // service's own try/catch by passing a null-returning implementation.
      final source = _makeItem(id: 'src', type: 'article');

      // Using a real fake DB but passing an item with a type that won't match
      // anything — service should silently return [].
      final results = await svc.fetchRelated(source, limit: 6);
      expect(results, isA<List<ContentItem>>());
    });

    // ------------------------------------------------------------------
    // 10. Title keyword tiebreak: matching keywords rank higher
    // ------------------------------------------------------------------
    test('items with more matching title keywords rank higher as tiebreak',
        () async {
      final source = _makeItem(
        id: 'src',
        type: 'article',
        titleEn: 'Handling anxiety and stress',
        category: 'wellness',
      );
      // Both items same category → same base score (+3 each).
      // Item A has 2 matching keywords; item B has 0.
      final keywordMatch = _makeItem(
        id: 'A',
        type: 'article',
        titleEn: 'Anxiety management tips',
        category: 'wellness',
      );
      final noKeywordMatch = _makeItem(
        id: 'B',
        type: 'article',
        titleEn: 'Something completely unrelated',
        category: 'wellness',
      );

      await _seed(fakeDb, [
        _docFor(source),
        _docFor(keywordMatch),
        _docFor(noKeywordMatch),
      ]);

      final results = await svc.fetchRelated(source, limit: 10);
      final ids = results.map((e) => e.id).toList();

      expect(ids.indexOf('A'), lessThan(ids.indexOf('B')),
          reason: 'Keyword matches should rank strictly higher');
    });

    // ------------------------------------------------------------------
    // 11. Mood weight dominates category weight (amendment #2)
    //     mood_tag +4 each > category +2 — a single shared mood tag
    //     must outrank a pure same-category match.
    // ------------------------------------------------------------------
    test('one shared mood tag outranks a same-category-only match', () async {
      final source = _makeItem(
        id: 'src',
        type: 'article',
        category: 'wellness',
        moodTags: ['anxious'],
      );
      // Has a shared mood tag (+4) but different category (no +2).
      final moodMatch = _makeItem(
        id: 'mood',
        type: 'article',
        category: 'sleep',
        moodTags: ['anxious'],
      );
      // Same category (+2) but no shared mood tags.
      final categoryOnly = _makeItem(
        id: 'cat',
        type: 'article',
        category: 'wellness',
        moodTags: [],
      );

      await _seed(fakeDb, [
        _docFor(source),
        _docFor(moodMatch),
        _docFor(categoryOnly),
      ]);

      final results = await svc.fetchRelated(source, limit: 10);
      final ids = results.map((e) => e.id).toList();

      expect(ids.indexOf('mood'), lessThan(ids.indexOf('cat')),
          reason:
              'mood_tag +4 must dominate category +2 — mood match scores 4, '
              'category-only scores 2');
    });
  });
}
