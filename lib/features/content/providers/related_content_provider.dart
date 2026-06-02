import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import '../services/related_content_service.dart';

/// Auto-disposing family provider keyed by [ContentItem].
///
/// Riverpod uses the argument's `==` / `hashCode` to distinguish family
/// instances. Since [ContentItem] does not override those operators we use a
/// thin [_ContentKey] wrapper that only compares on [id], matching the spec's
/// "keyed by source.id" requirement.
///
/// Usage:
///   ref.watch(relatedContentProvider(RelatedContentKey(item)))
class RelatedContentKey {
  final ContentItem item;

  const RelatedContentKey(this.item);

  @override
  bool operator ==(Object other) =>
      other is RelatedContentKey && other.item.id == item.id;

  @override
  int get hashCode => item.id.hashCode;
}

/// Auto-disposing family provider.
///
/// A 5-minute keep-alive is attached so re-opening the same article within
/// that window avoids a second Firestore round-trip.
final relatedContentProvider = FutureProvider.family
    .autoDispose<List<ContentItem>, RelatedContentKey>(
  (ref, key) async {
    final link = ref.keepAlive();
    Timer(const Duration(minutes: 5), link.close);

    final svc = RelatedContentService();
    return svc.fetchRelated(key.item, limit: 6);
  },
);
