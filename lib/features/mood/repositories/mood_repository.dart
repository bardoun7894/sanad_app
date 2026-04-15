import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';
import '../../admin/providers/activity_log_provider.dart';

class MoodRepository {
  final FirebaseFirestore _firestore;
  final ActivityLogService? _activityLogService;

  MoodRepository({
    FirebaseFirestore? firestore,
    ActivityLogService? activityLogService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _activityLogService = activityLogService ?? ActivityLogService();

  CollectionReference _userMoodsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_entries');
  }

  /// Get mood entries stream for a user
  Stream<List<MoodEntry>> getMoodEntries(String userId) {
    return _userMoodsCollection(
      userId,
    ).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure ID is from doc ID
        return MoodEntry.fromMap(data, doc.id);
      }).toList();
    });
  }

  /// Add a new mood entry
  Future<void> addMoodEntry(MoodEntry entry, String userId) async {
    await _userMoodsCollection(userId).doc(entry.id).set(entry.toMap());

    // Log activity
    final activityLogService = _activityLogService;
    if (activityLogService == null) return;

    try {
      // Get user name
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName =
          userDoc.data()?['full_name'] as String? ??
          userDoc.data()?['name'] as String? ??
          'User';

      await activityLogService.logMoodLogged(
        userId: userId,
        userName: userName,
        mood: entry.mood.name,
      );
    } catch (e) {
      // Silently fail - activity logging shouldn't break mood entry
      debugPrint('Failed to log mood activity: $e');
    }
  }

  /// Update an existing mood entry
  Future<void> updateMoodEntry(MoodEntry entry, String userId) async {
    await _userMoodsCollection(userId).doc(entry.id).update(entry.toMap());
  }

  /// Delete a mood entry
  Future<void> deleteMoodEntry(String id, String userId) async {
    await _userMoodsCollection(userId).doc(id).delete();
  }

  /// Get today's entry if it exists
  Future<MoodEntry?> getTodayEntry(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = await _userMoodsCollection(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    return MoodEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
