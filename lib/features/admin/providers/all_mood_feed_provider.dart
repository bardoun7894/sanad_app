import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood_alert.dart';
import '../../mood/models/mood_enums.dart';
import '../../../core/utils/user_display_name.dart';

/// Streams the 80 most-recent mood entries across ALL users (collectionGroup),
/// including ALL mood types (positive, negative, neutral).
///
/// This is the data source for the admin "all moods" feed tab.
/// For the negative-only alert bell, see [moodAlertsProvider] instead.
///
/// Frontend usage:
///   ref.watch(allMoodFeedProvider) → AsyncValue<List<MoodAlert>>
///
/// The list is ordered newest-first (Firestore query order preserved).
/// Each entry's mood polarity can be read via [MoodPolarityX.polarity].
final allMoodFeedProvider = StreamProvider<List<MoodAlert>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collectionGroup('mood_entries')
      .orderBy('date', descending: true)
      .limit(80)
      .snapshots(includeMetadataChanges: false)
      .asyncMap((snapshot) async {
        // --- 1. Parse entries — include ALL mood types ---
        final entries = <_RawEntry>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();

          // Guard: skip if moodIndex is null or outside the valid enum range.
          final moodIndex = data['mood'] as int?;
          if (moodIndex == null) continue;
          if (moodIndex < 0 || moodIndex >= MoodType.values.length) continue;

          // Guard: skip docs with no parent userId (malformed path).
          final userId = doc.reference.parent.parent?.id;
          if (userId == null) continue;

          // Guard: skip docs missing a date field (see [[firestore_orderby_hides_docs_missing_field]]).
          final timestamp = (data['date'] as Timestamp?)?.toDate();
          if (timestamp == null) continue;

          entries.add(_RawEntry(
            userId: userId,
            moodIndex: moodIndex,
            date: timestamp,
          ));
        }

        if (entries.isEmpty) return <MoodAlert>[];

        // --- 2. Dedupe userIds and batch-fetch user docs ---
        final distinctUserIds = {for (final e in entries) e.userId}.toList();

        // Firestore whereIn supports up to 30 items per call; chunk if needed.
        final nameByUserId = <String, String?>{};

        try {
          final chunks = _chunk(distinctUserIds, 30);
          final futures = chunks.map(
            (chunk) => firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: chunk)
                .get(),
          );

          final results = await Future.wait(futures);

          for (final result in results) {
            for (final doc in result.docs) {
              nameByUserId[doc.id] =
                  resolveDisplayNameFromUserDoc(doc.data());
            }
          }
        } catch (e) {
          debugPrint('[allMoodFeedProvider] batch user-name fetch failed: $e');
          // Proceed without names rather than crashing the whole stream.
        }

        // --- 3. Map to MoodAlert (names resolved, list newest-first) ---
        return entries.map((e) {
          final mood = MoodType.values[e.moodIndex];
          return MoodAlert(
            userId: e.userId,
            userName: nameByUserId[e.userId], // null if not fetched / incomplete signup
            mood: mood,
            date: e.date,
          );
        }).toList();
      })
      .handleError((Object error, StackTrace stack) {
        debugPrint('[allMoodFeedProvider] stream error: $error\n$stack');
        return <MoodAlert>[];
      });
});

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _RawEntry {
  final String userId;
  final int moodIndex;
  final DateTime date;

  const _RawEntry({
    required this.userId,
    required this.moodIndex,
    required this.date,
  });
}

/// Splits [list] into sub-lists of at most [size] elements.
List<List<T>> _chunk<T>(List<T> list, int size) {
  final chunks = <List<T>>[];
  for (var i = 0; i < list.length; i += size) {
    chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
  }
  return chunks;
}
