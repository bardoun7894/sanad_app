import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';

/// Repository for managing therapist reviews
class ReviewRepository {
  final FirebaseFirestore _firestore;

  ReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _reviewsCollection =>
      _firestore.collection('reviews');

  /// Get all reviews for a specific therapist
  Stream<List<Review>> getTherapistReviews(String therapistId) {
    return _reviewsCollection
        .where('therapist_id', isEqualTo: therapistId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
        });
  }

  /// Get reviews for a specific therapist (future)
  Future<List<Review>> getTherapistReviewsFuture(String therapistId) async {
    final snapshot = await _reviewsCollection
        .where('therapist_id', isEqualTo: therapistId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
  }

  /// Get review for a specific booking
  Future<Review?> getReviewByBooking(String bookingId) async {
    final snapshot = await _reviewsCollection
        .where('booking_id', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Review.fromFirestore(snapshot.docs.first);
  }

  /// Create a new review
  /// Create a new review with transactional update to therapist stats
  Future<void> createReview(Review review) async {
    // Check if review already exists for this booking
    final existing = await getReviewByBooking(review.bookingId);
    if (existing != null) {
      throw Exception('Review already exists for this booking');
    }

    // Validate rating
    if (!review.isValidRating) {
      throw Exception('Rating must be between 1 and 5 stars');
    }

    // Use transaction to ensure data integrity
    await _firestore.runTransaction((transaction) async {
      final therapistRef = _firestore
          .collection('therapists')
          .doc(review.therapistId);

      final therapistDoc = await transaction.get(therapistRef);
      if (!therapistDoc.exists) {
        throw Exception('Therapist not found');
      }

      final data = therapistDoc.data() as Map<String, dynamic>;
      final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (data['review_count'] as int?) ?? 0;

      // Calculate new averages
      final newCount = currentCount + 1;
      final newRating =
          ((currentRating * currentCount) + review.rating) / newCount;

      // Update therapist profile
      transaction.update(therapistRef, {
        'rating': newRating,
        'review_count': newCount,
      });

      // Create review document
      final newReviewRef = _reviewsCollection.doc();
      final reviewData = review.toFirestore();
      // Ensure specific fields are set if not in model
      reviewData['id'] = newReviewRef.id;

      transaction.set(newReviewRef, reviewData);
    });
  }

  /// Update an existing review
  Future<void> updateReview(
    String reviewId, {
    double? rating,
    String? comment,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
    };

    if (rating != null) {
      if (rating < 1.0 || rating > 5.0) {
        throw Exception('Rating must be between 1 and 5 stars');
      }
      updates['rating'] = rating;
    }

    if (comment != null) {
      updates['comment'] = comment;
    }

    await _reviewsCollection.doc(reviewId).update(updates);
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    await _reviewsCollection.doc(reviewId).delete();
  }

  /// Get average rating for a therapist
  Future<double> getAverageRating(String therapistId) async {
    final reviews = await getTherapistReviewsFuture(therapistId);

    if (reviews.isEmpty) return 0.0;

    final total = reviews.fold<double>(
      0,
      (totalScore, review) => totalScore + review.rating,
    );
    return total / reviews.length;
  }

  /// Get rating distribution for a therapist
  Future<Map<int, int>> getRatingDistribution(String therapistId) async {
    final reviews = await getTherapistReviewsFuture(therapistId);

    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final review in reviews) {
      final stars = review.starCount;
      distribution[stars] = (distribution[stars] ?? 0) + 1;
    }

    return distribution;
  }

  /// Check if user has reviewed a booking
  Future<bool> hasUserReviewed(String userId, String bookingId) async {
    final snapshot = await _reviewsCollection
        .where('user_id', isEqualTo: userId)
        .where('booking_id', isEqualTo: bookingId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get recent reviews across all therapists (for admin)
  Stream<List<Review>> getRecentReviews({int limit = 20}) {
    return _reviewsCollection
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
        });
  }
}

/// Provider for ReviewRepository
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});
