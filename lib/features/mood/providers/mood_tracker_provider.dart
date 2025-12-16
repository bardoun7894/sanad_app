import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_entry.dart';
import '../widgets/mood_selector.dart';

class MoodTrackerState {
  final List<MoodEntry> entries;
  final bool isLoading;
  final MoodEntry? todayEntry;

  const MoodTrackerState({
    this.entries = const [],
    this.isLoading = false,
    this.todayEntry,
  });

  MoodTrackerState copyWith({
    List<MoodEntry>? entries,
    bool? isLoading,
    MoodEntry? todayEntry,
  }) {
    return MoodTrackerState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      todayEntry: todayEntry ?? this.todayEntry,
    );
  }

  // Get entries for the last 7 days
  List<MoodEntry> get weeklyEntries {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return entries
        .where((e) => e.date.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get entries grouped by date
  Map<DateTime, MoodEntry> get entriesByDate {
    final map = <DateTime, MoodEntry>{};
    for (final entry in entries) {
      final dateOnly = DateTime(entry.date.year, entry.date.month, entry.date.day);
      map[dateOnly] = entry;
    }
    return map;
  }
}

class MoodTrackerNotifier extends StateNotifier<MoodTrackerState> {
  MoodTrackerNotifier() : super(const MoodTrackerState()) {
    _loadEntries();
  }

  void _loadEntries() {
    // Simulate loading with sample data
    // In production, load from Hive/local storage
    final now = DateTime.now();
    final sampleEntries = [
      MoodEntry(
        id: '1',
        mood: MoodType.happy,
        date: now.subtract(const Duration(days: 0)),
        note: 'Great day at work!',
      ),
      MoodEntry(
        id: '2',
        mood: MoodType.calm,
        date: now.subtract(const Duration(days: 1)),
        note: 'Meditation helped',
      ),
      MoodEntry(
        id: '3',
        mood: MoodType.tired,
        date: now.subtract(const Duration(days: 2)),
      ),
      MoodEntry(
        id: '4',
        mood: MoodType.anxious,
        date: now.subtract(const Duration(days: 3)),
        note: 'Deadline stress',
      ),
      MoodEntry(
        id: '5',
        mood: MoodType.happy,
        date: now.subtract(const Duration(days: 4)),
      ),
      MoodEntry(
        id: '6',
        mood: MoodType.calm,
        date: now.subtract(const Duration(days: 5)),
      ),
      MoodEntry(
        id: '7',
        mood: MoodType.sad,
        date: now.subtract(const Duration(days: 6)),
        note: 'Missing family',
      ),
    ];

    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEntry = sampleEntries.where((e) {
      final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
      return entryDate == todayStart;
    }).firstOrNull;

    state = MoodTrackerState(
      entries: sampleEntries,
      todayEntry: todayEntry,
    );
  }

  void logMood(MoodType mood, {String? note}) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Check if there's already an entry for today
    final existingIndex = state.entries.indexWhere((e) {
      final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
      return entryDate == todayStart;
    });

    final newEntry = MoodEntry(
      id: now.millisecondsSinceEpoch.toString(),
      mood: mood,
      date: now,
      note: note,
    );

    List<MoodEntry> updatedEntries;
    if (existingIndex >= 0) {
      // Update existing entry
      updatedEntries = [...state.entries];
      updatedEntries[existingIndex] = newEntry;
    } else {
      // Add new entry
      updatedEntries = [newEntry, ...state.entries];
    }

    state = state.copyWith(
      entries: updatedEntries,
      todayEntry: newEntry,
    );
  }

  void deleteEntry(String id) {
    final updatedEntries = state.entries.where((e) => e.id != id).toList();
    final todayEntry = state.todayEntry?.id == id ? null : state.todayEntry;
    state = state.copyWith(entries: updatedEntries, todayEntry: todayEntry);
  }
}

final moodTrackerProvider =
    StateNotifierProvider<MoodTrackerNotifier, MoodTrackerState>((ref) {
  return MoodTrackerNotifier();
});
