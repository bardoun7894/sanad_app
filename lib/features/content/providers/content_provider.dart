import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import '../models/psychological_test.dart';
import '../repositories/content_repository.dart';

/// Stream of `meta/content_revision`. Whenever admin adds/updates/deletes
/// content, that doc's `updated_at` is bumped. Content providers watch this
/// so they re-fetch automatically without the user having to pull-to-refresh.
final contentRevisionProvider = StreamProvider<int>((ref) {
  return FirebaseFirestore.instance
      .collection('meta')
      .doc('content_revision')
      .snapshots()
      .map((doc) {
    final ts = doc.data()?['updated_at'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    return 0;
  });
});

final blogProvider = FutureProvider<List<ContentItem>>((ref) {
  ref.watch(contentRevisionProvider);
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getContentByType('article');
});

final podcastProvider = FutureProvider<List<ContentItem>>((ref) {
  ref.watch(contentRevisionProvider);
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getContentByType('podcast');
});

final exercisesProvider = FutureProvider<List<ContentItem>>((ref) {
  ref.watch(contentRevisionProvider);
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getContentByType('exercise');
});

final psychTestsProvider = FutureProvider<List<PsychologicalTest>>((ref) {
  ref.keepAlive();
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getPsychologicalTests();
});

final testResultsProvider = FutureProvider<List<TestResult>>((ref) {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getUserTestResults();
});
