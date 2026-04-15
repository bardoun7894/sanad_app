import 'package:cloud_firestore/cloud_firestore.dart';

/// Review model for therapist ratings
class Review {
  final String id;
  final String therapistId;
  final String userId;
  final String bookingId;
  final double rating; // 1.0 to 5.0
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Review({
    required this.id,
    required this.therapistId,
    required this.userId,
    required this.bookingId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Review from Firestore document
  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Review(
      id: doc.id,
      therapistId: data['therapist_id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      bookingId: data['booking_id'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert Review to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'therapist_id': therapistId,
      'user_id': userId,
      'booking_id': bookingId,
      'rating': rating,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      'created_at': FieldValue.serverTimestamp(),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Create a copy with updated fields
  Review copyWith({
    String? id,
    String? therapistId,
    String? userId,
    String? bookingId,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if rating is valid (1-5 stars)
  bool get isValidRating => rating >= 1.0 && rating <= 5.0;

  /// Get star count as integer
  int get starCount => rating.round();

  /// Get rating as percentage (0-100)
  double get ratingPercentage => (rating / 5.0) * 100;
}
