import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firestore_cache_helper.dart';
import '../models/journey.dart';

/// Repository for Journey + Chapter CRUD on /journeys/{journeyId}
class JourneyRepository {
  final FirebaseFirestore _firestore;

  JourneyRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _journeysCollection =>
      _firestore.collection('journeys');

  /// List all active journeys, optionally filtered by category and/or difficulty
  Future<List<Journey>> listJourneys({
    JourneyCategory? category,
    JourneyDifficulty? difficulty,
  }) async {
    try {
      Query query = _journeysCollection.where('is_active', isEqualTo: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.name);
      }

      query = query.orderBy('display_order');

      final snapshot = await query.getCacheFirst();
      return snapshot.docs.map((doc) => Journey.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error listing journeys: $e');
      return [];
    }
  }

  /// Get a single journey by ID
  Future<Journey?> getJourney(String journeyId) async {
    try {
      final doc = await _journeysCollection.doc(journeyId).getCacheFirst();
      if (!doc.exists) return null;
      return Journey.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting journey: $e');
      return null;
    }
  }

  /// List all chapters for a journey, ordered by chapter order
  Future<List<JourneyChapter>> listChapters(String journeyId) async {
    try {
      final snapshot = await _journeysCollection
          .doc(journeyId)
          .collection('chapters')
          .orderBy('order')
          .getCacheFirst();

      return snapshot.docs
          .map((doc) => JourneyChapter.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error listing chapters: $e');
      return [];
    }
  }

  /// Get a single chapter by ID
  Future<JourneyChapter?> getChapter(String journeyId, String chapterId) async {
    try {
      final doc = await _journeysCollection
          .doc(journeyId)
          .collection('chapters')
          .doc(chapterId)
          .getCacheFirst();

      if (!doc.exists) return null;
      return JourneyChapter.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting chapter: $e');
      return null;
    }
  }

  /// Stream all active journeys for real-time updates
  Stream<List<Journey>> streamJourneys() {
    return _journeysCollection
        .where('is_active', isEqualTo: true)
        .orderBy('display_order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Journey.fromFirestore(doc))
              .toList();
        });
  }
}
