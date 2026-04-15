import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_entry.dart';
import '../models/mood_enums.dart';
import '../repositories/mood_repository.dart';
import '../../admin/providers/activity_log_provider.dart';
import '../../auth/providers/auth_provider.dart';

final moodRepositoryProvider = Provider((ref) => MoodRepository());

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
    return entries.where((e) => e.date.isAfter(weekAgo)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get entries for the current month
  List<MoodEntry> get monthlyEntries {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    return entries.where((e) => e.date.isAfter(monthStart)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get dominant mood (most frequent in the last 30 days)
  MoodType? get dominantMood {
    if (entries.isEmpty) return null;

    final recentEntries = monthlyEntries;
    if (recentEntries.isEmpty) return null;

    final counts = <MoodType, int>{};
    for (final entry in recentEntries) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }

    var maxCount = 0;
    MoodType? dominant;

    counts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = mood;
      }
    });

    return dominant;
  }

  // Calculate current streak (consecutive days with logs)
  int get currentStreak {
    if (entries.isEmpty) return 0;

    final sortedEntries = List<MoodEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));

    var streak = 0;
    final now = DateTime.now();
    var checkDate = DateTime(now.year, now.month, now.day);

    // Check if logged today
    final loggedToday = sortedEntries.any((e) {
      final eDate = DateTime(e.date.year, e.date.month, e.date.day);
      return eDate == checkDate;
    });

    if (!loggedToday) {
      // If not logged today, check from yesterday
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final hasEntry = sortedEntries.any((e) {
        final eDate = DateTime(e.date.year, e.date.month, e.date.day);
        return eDate == checkDate;
      });

      if (hasEntry) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Get entries grouped by date
  Map<DateTime, MoodEntry> get entriesByDate {
    final map = <DateTime, MoodEntry>{};
    for (final entry in entries) {
      final dateOnly = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      map[dateOnly] = entry;
    }
    return map;
  }
}

class MoodTrackerNotifier extends StateNotifier<MoodTrackerState> {
  final MoodRepository _repository;
  StreamSubscription? _subscription;
  final String? _userId;
  final Ref _ref;

  // Demo mood entries for guests to show app functionality

  MoodTrackerNotifier(this._repository, this._userId, this._ref)
    : super(const MoodTrackerState()) {
    if (_userId != null) {
      _init();
    }
    // Guest user - no data
  }

  void _init() {
    state = state.copyWith(isLoading: true);
    _subscription = _repository.getMoodEntries(_userId!).listen((entries) {
      // Find today's entry
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final todayEntry = entries.where((e) {
        final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
        return entryDate == todayStart;
      }).firstOrNull;

      state = state.copyWith(
        entries: entries,
        todayEntry: todayEntry,
        isLoading: false,
      );
    });
  }

  Future<void> logMood(MoodType mood, {String? note}) async {
    if (_userId == null) return;

    // Check if we updating today's entry
    final entryId =
        state.todayEntry?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final entry = MoodEntry(
      id: entryId,
      mood: mood,
      date: DateTime.now(),
      note: note,
    );

    if (state.todayEntry != null) {
      await _repository.updateMoodEntry(entry, _userId);
    } else {
      await _repository.addMoodEntry(entry, _userId);

      // Log activity
      try {
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser != null) {
          await _ref
              .read(activityLogServiceProvider)
              .logMoodLogged(
                userId: _userId,
                userName: currentUser.displayName ?? 'User',
                mood: mood.name,
              );
        }
      } catch (e) {
        debugPrint('Failed to log mood activity: $e');
      }
    }
  }

  Future<void> deleteEntry(String id) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.deleteMoodEntry(id, userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final moodTrackerProvider =
    StateNotifierProvider<MoodTrackerNotifier, MoodTrackerState>((ref) {
      final repository = ref.watch(moodRepositoryProvider);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      return MoodTrackerNotifier(repository, userId, ref);
    });
