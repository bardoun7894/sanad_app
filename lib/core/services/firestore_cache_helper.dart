import 'package:cloud_firestore/cloud_firestore.dart';

/// Extensions for cache-first Firestore reads.
///
/// Since Firestore persistence is enabled (main.dart), documents are cached
/// locally. These helpers try the cache first for instant results, then fall
/// back to the server if the cache is empty (first launch or data never read).
///
/// Use `.getCacheFirst()` instead of `.get()` on read-only queries where
/// slight staleness is acceptable (streams or pull-to-refresh provide updates).

extension CacheFirstDoc<T extends Object?> on DocumentReference<T> {
  Future<DocumentSnapshot<T>> getCacheFirst() async {
    try {
      final cached = await get(const GetOptions(source: Source.cache));
      if (cached.exists) return cached;
    } catch (_) {
      // Cache miss or error — fall through to server
    }
    return get();
  }
}

extension CacheFirstQuery<T extends Object?> on Query<T> {
  Future<QuerySnapshot<T>> getCacheFirst() async {
    try {
      final cached = await get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) return cached;
    } catch (_) {
      // Cache miss or error — fall through to server
    }
    return get();
  }
}
