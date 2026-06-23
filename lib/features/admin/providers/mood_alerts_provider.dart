import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mood_alert.dart';
import '../../mood/models/mood_enums.dart';
import '../../../core/utils/user_display_name.dart';

/// Negative mood indices: anxious=2, sad=3, angry=4.
const _negativeMoodIndices = {2, 3, 4};

/// Streams the 60 most-recent mood entries across ALL users (collectionGroup),
/// filtered client-side to negative moods only, with user display names
/// resolved in a single batch (deduplicated by userId).
///
/// Frontend usage:
///   ref.watch(moodAlertsProvider) → AsyncValue<List<MoodAlert>>
///
/// The list is already ordered newest-first (Firestore query order preserved).
final moodAlertsProvider = StreamProvider<List<MoodAlert>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collectionGroup('mood_entries')
      .orderBy('date', descending: true)
      .limit(60)
      .snapshots(includeMetadataChanges: false)
      .asyncMap((snapshot) async {
        // --- 1. Parse entries, filter to negative moods ---
        final entries = <_RawEntry>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final moodIndex = (data['mood'] as int?) ?? -1;

          if (!_negativeMoodIndices.contains(moodIndex)) continue;

          final userId = doc.reference.parent.parent?.id;
          if (userId == null) continue;

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

          for (final snapshot in results) {
            for (final doc in snapshot.docs) {
              nameByUserId[doc.id] =
                  resolveDisplayNameFromUserDoc(doc.data());
            }
          }
        } catch (e) {
          debugPrint('[moodAlertsProvider] batch user-name fetch failed: $e');
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
        debugPrint('[moodAlertsProvider] stream error: $error\n$stack');
        return <MoodAlert>[];
      });
});

/// Convenience derived provider: count of alerts for badge display.
/// Frontend: `ref.watch(moodAlertCountProvider).value ?? 0`
final moodAlertCountProvider = Provider<int>((ref) {
  return ref.watch(moodAlertsProvider).value?.length ?? 0;
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
