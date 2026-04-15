import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import '../models/psychological_test.dart';
import '../repositories/content_repository.dart';

final blogProvider = FutureProvider<List<ContentItem>>((ref) {
  ref.keepAlive();
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getContentByType('article');
});

final podcastProvider = FutureProvider<List<ContentItem>>((ref) {
  ref.keepAlive();
  final repo = ref.watch(contentRepositoryProvider);
  return repo.getContentByType('podcast');
});

final exercisesProvider = FutureProvider<List<ContentItem>>((ref) {
  ref.keepAlive();
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
