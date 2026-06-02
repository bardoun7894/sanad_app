import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_models.dart';

/// Pure data layer for fetching and scoring related content.
///
/// Scoring rules (applied in-memory after Firestore fetch):
///   • Per shared mood_tag             → +4  (emotional theme dominates)
///   • Same category as source        → +2
///   • Per matching title keyword (EN) → +1 (tiebreak; > 3 chars, case-insensitive)
class RelatedContentService {
  final FirebaseFirestore _firestore;

  RelatedContentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<ContentItem>> fetchRelated(
    ContentItem source, {
    int limit = 6,
  }) async {
    try {
      final results = await _fetchCandidates(source);
      return _scoreAndRank(results, source, limit);
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Firestore queries
  // ---------------------------------------------------------------------------

  Future<List<ContentItem>> _fetchCandidates(ContentItem source) async {
    // Base query: same type, published.
    final baseQuery = _firestore
        .collection('content')
        .where('is_published', isEqualTo: true)
        .where('type', isEqualTo: source.type)
        .limit(40);

    final List<Future<QuerySnapshot<Map<String, dynamic>>>> futures = [
      _fetchWithOrderBy(baseQuery),
    ];

    // Secondary mood-tag query (only when ≤ 10 tags present).
    final tags = source.moodTags;
    if (tags.isNotEmpty && tags.length <= 10) {
      final moodQuery = _firestore
          .collection('content')
          .where('is_published', isEqualTo: true)
          .where('type', isEqualTo: source.type)
          .where('mood_tags', arrayContainsAny: tags)
          .limit(20);
      futures.add(_fetchWithOrderBy(moodQuery));
    }

    final snapshots = await Future.wait(futures);

    // Merge and dedupe by document id; drop the source article itself.
    final Map<String, ContentItem> seen = {};
    for (final snap in snapshots) {
      for (final doc in snap.docs) {
        if (doc.id == source.id) continue;
        seen.putIfAbsent(doc.id, () => ContentItem.fromFirestore(doc));
      }
    }
    return seen.values.toList();
  }

  /// Attempts the query with `orderBy('created_at', descending: true)`.
  /// On `failed-precondition` (index missing) retries once without the
  /// `orderBy` clause (sorting will happen in-memory). Any other error
  /// is re-thrown so the outer try/catch returns [].
  Future<QuerySnapshot<Map<String, dynamic>>> _fetchWithOrderBy(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await query
          .orderBy('created_at', descending: true)
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        // Index is missing — fall back to unordered fetch; we sort in-memory.
        return await query.get();
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // In-memory scoring + ranking
  // ---------------------------------------------------------------------------

  List<ContentItem> _scoreAndRank(
    List<ContentItem> candidates,
    ContentItem source,
    int limit,
  ) {
    final sourceKeywords = _extractKeywords(source.titleEn);
    final sourceTags = source.moodTags.toSet();

    final scored = candidates.map((item) {
      int score = 0;

      // Shared mood tags: +4 each (emotional theme is most relevant in a
      // mental-health app; mood dominates admin taxonomy).
      for (final tag in item.moodTags) {
        if (sourceTags.contains(tag)) score += 4;
      }

      // Category match: +2
      if (source.category != null &&
          item.category != null &&
          item.category == source.category) {
        score += 2;
      }

      // Keyword tiebreak: +1 each
      final itemKeywords = _extractKeywords(item.titleEn);
      for (final kw in itemKeywords) {
        if (sourceKeywords.contains(kw)) score += 1;
      }

      return (item: item, score: score);
    }).toList();

    // Sort by score DESC, then by createdAt DESC as tiebreak.
    scored.sort((a, b) {
      final cmp = b.score.compareTo(a.score);
      if (cmp != 0) return cmp;
      final dateA = a.item.createdAt;
      final dateB = b.item.createdAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return scored.take(limit).map((e) => e.item).toList();
  }

  /// Extract lowercase words of length > 3 from a title string.
  Set<String> _extractKeywords(String text) {
    if (text.isEmpty) return {};
    return text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toSet();
  }
}
