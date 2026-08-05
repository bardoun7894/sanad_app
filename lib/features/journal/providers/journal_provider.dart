import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood/models/mood_enums.dart';
import '../models/journal_entry.dart';
import '../repositories/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

class JournalState {
  final List<JournalEntry> entries;
  final bool isLoading;

  const JournalState({this.entries = const [], this.isLoading = true});

  JournalState copyWith({List<JournalEntry>? entries, bool? isLoading}) {
    return JournalState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Distinct tags across all entries (for filter chips).
  List<String> get allTags {
    final set = <String>{};
    for (final e in entries) {
      set.addAll(e.tags);
    }
    return set.toList()..sort();
  }
}

class JournalNotifier extends StateNotifier<JournalState> {
  final JournalRepository _repository;

  JournalNotifier(this._repository) : super(const JournalState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final entries = await _repository.getAll();
      state = JournalState(entries: entries, isLoading: false);
    } catch (e) {
      // Storage unavailable (e.g. secure-storage plugin not registered after a
      // hot restart — needs a full rebuild). Fail soft with an empty list.
      state = const JournalState(entries: [], isLoading: false);
    }
  }

  /// Create or update an entry. Returns the saved entry.
  Future<JournalEntry> upsert({
    String? id,
    required String body,
    MoodType? mood,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    JournalEntry? existing;
    if (id != null) {
      for (final e in state.entries) {
        if (e.id == id) {
          existing = e;
          break;
        }
      }
    }
    final entry = JournalEntry(
      id: id ?? 'j_${now.microsecondsSinceEpoch}',
      body: body,
      mood: mood,
      tags: tags,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _repository.save(entry);
    await load();
    return entry;
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }
}

final journalProvider =
    StateNotifierProvider<JournalNotifier, JournalState>((ref) {
  return JournalNotifier(ref.watch(journalRepositoryProvider));
});
