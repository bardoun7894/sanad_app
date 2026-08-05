import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/journal/models/journal_entry.dart';
import 'package:sanad_app/features/journal/providers/journal_provider.dart';
import 'package:sanad_app/features/journal/repositories/journal_repository.dart';
import 'package:sanad_app/features/mood/models/mood_enums.dart';

/// In-memory fake — overrides the local Hive-backed methods so the notifier
/// logic can be tested without platform channels (secure storage / Hive).
class _FakeJournalRepository extends JournalRepository {
  final Map<String, JournalEntry> _store = {};

  @override
  Future<List<JournalEntry>> getAll() async {
    final list = _store.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> save(JournalEntry entry) async {
    _store[entry.id] = entry;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }
}

void main() {
  group('JournalEntry serialization', () {
    test('toJson/fromJson round-trips all fields', () {
      final now = DateTime(2026, 5, 24, 8, 30);
      final entry = JournalEntry(
        id: 'j_1',
        body: 'today was **good**',
        mood: MoodType.happy,
        tags: const ['gratitude', 'work'],
        createdAt: now,
        updatedAt: now,
      );
      final restored = JournalEntry.fromJson(entry.toJson());
      expect(restored.id, entry.id);
      expect(restored.body, entry.body);
      expect(restored.mood, MoodType.happy);
      expect(restored.tags, ['gratitude', 'work']);
      expect(restored.createdAt, now);
    });

    test('null mood survives round-trip', () {
      final now = DateTime(2026, 5, 24);
      final entry = JournalEntry(
        id: 'j_2',
        body: 'no mood',
        createdAt: now,
        updatedAt: now,
      );
      final restored = JournalEntry.fromJson(entry.toJson());
      expect(restored.mood, isNull);
    });
  });

  group('JournalNotifier', () {
    test('upsert creates then updates the same entry', () async {
      final notifier = JournalNotifier(_FakeJournalRepository());
      // wait for initial load
      await Future<void>.delayed(Duration.zero);

      final created = await notifier.upsert(body: 'first', mood: MoodType.calm);
      expect(notifier.state.entries.length, 1);
      expect(notifier.state.entries.first.body, 'first');

      await notifier.upsert(id: created.id, body: 'edited', mood: MoodType.sad);
      expect(notifier.state.entries.length, 1);
      expect(notifier.state.entries.first.body, 'edited');
      expect(notifier.state.entries.first.mood, MoodType.sad);
      // createdAt preserved across edit
      expect(notifier.state.entries.first.createdAt, created.createdAt);
    });

    test('delete removes the entry', () async {
      final notifier = JournalNotifier(_FakeJournalRepository());
      await Future<void>.delayed(Duration.zero);
      final e = await notifier.upsert(body: 'temp');
      expect(notifier.state.entries.length, 1);
      await notifier.delete(e.id);
      expect(notifier.state.entries, isEmpty);
    });

    test('allTags aggregates distinct tags', () async {
      final notifier = JournalNotifier(_FakeJournalRepository());
      await Future<void>.delayed(Duration.zero);
      await notifier.upsert(body: 'a', tags: const ['work', 'anxiety']);
      await notifier.upsert(body: 'b', tags: const ['work', 'gratitude']);
      expect(notifier.state.allTags, containsAll(['work', 'anxiety', 'gratitude']));
      expect(notifier.state.allTags.where((t) => t == 'work').length, 1);
    });
  });
}
