import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/reviews/models/review.dart';

void main() {
  final now = DateTime(2026, 2, 15, 10, 30);

  group('Review', () {
    test('creates with required fields', () {
      final review = Review(
        id: 'review-1',
        therapistId: 'therapist-1',
        userId: 'user-1',
        bookingId: 'booking-1',
        rating: 4.5,
        createdAt: now,
      );

      expect(review.id, 'review-1');
      expect(review.therapistId, 'therapist-1');
      expect(review.userId, 'user-1');
      expect(review.bookingId, 'booking-1');
      expect(review.rating, 4.5);
      expect(review.comment, isNull);
      expect(review.updatedAt, isNull);
    });

    test('isValidRating returns true for valid ratings', () {
      final review = Review(
        id: 'r1',
        therapistId: 't1',
        userId: 'u1',
        bookingId: 'b1',
        rating: 3.5,
        createdAt: now,
      );

      expect(review.isValidRating, isTrue);
    });

    test('isValidRating returns false for out of range', () {
      final lowReview = Review(
        id: 'r1',
        therapistId: 't1',
        userId: 'u1',
        bookingId: 'b1',
        rating: 0.5,
        createdAt: now,
      );

      final highReview = Review(
        id: 'r2',
        therapistId: 't1',
        userId: 'u1',
        bookingId: 'b1',
        rating: 5.5,
        createdAt: now,
      );

      expect(lowReview.isValidRating, isFalse);
      expect(highReview.isValidRating, isFalse);
    });

    test('starCount rounds correctly', () {
      final review = Review(
        id: 'r1',
        therapistId: 't1',
        userId: 'u1',
        bookingId: 'b1',
        rating: 3.7,
        createdAt: now,
      );

      expect(review.starCount, 4);
    });

    test('ratingPercentage calculates correctly', () {
      final review = Review(
        id: 'r1',
        therapistId: 't1',
        userId: 'u1',
        bookingId: 'b1',
        rating: 2.5,
        createdAt: now,
      );

      expect(review.ratingPercentage, 50.0);
    });

    test('ratingPercentage returns 100 for 5.0', () {
      final review = Review(
        id: 'r1',
        therapistId: 't1',
        userId: 'u1',
        bookingId: 'b1',
        rating: 5.0,
        createdAt: now,
      );

      expect(review.ratingPercentage, 100.0);
    });

    test('copyWith creates updated copy', () {
      final review = Review(
        id: 'r1',
        therapistId: 't1',
        userId: 'u1',
        bookingId: 'b1',
        rating: 3.0,
        createdAt: now,
      );

      final updated = review.copyWith(rating: 5.0, comment: 'Great!');

      expect(updated.rating, 5.0);
      expect(updated.comment, 'Great!');
      expect(updated.id, 'r1');
      expect(review.rating, 3.0);
    });

    test('toFirestore serializes correctly', () {
      final review = Review(
        id: 'r1',
        therapistId: 't1',
        userId: 'u1',
        bookingId: 'b1',
        rating: 4.0,
        comment: 'Good',
        createdAt: now,
      );

      final map = review.toFirestore();

      expect(map['therapist_id'], 't1');
      expect(map['user_id'], 'u1');
      expect(map['booking_id'], 'b1');
      expect(map['rating'], 4.0);
      expect(map['comment'], 'Good');
    });

    test('toFirestore excludes empty comment', () {
      final review = Review(
        id: 'r1',
        therapistId: 't1',
        userId: 'u1',
        bookingId: 'b1',
        rating: 4.0,
        comment: '',
        createdAt: now,
      );

      final map = review.toFirestore();
      expect(map.containsKey('comment'), isFalse);
    });
  });
}
