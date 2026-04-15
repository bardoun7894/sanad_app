import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../therapist_portal/models/therapist_booking.dart';
import 'activity_log_provider.dart';
import '../models/activity_log.dart';

/// Page size for admin booking list pagination (M6.1).
const int kAdminBookingsPageSize = 20;

class AdminBookingState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<TherapistBooking> bookings;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  const AdminBookingState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.bookings = const [],
    this.hasMore = true,
    this.lastDocument,
  });

  AdminBookingState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<TherapistBooking>? bookings,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
  }) {
    return AdminBookingState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      bookings: bookings ?? this.bookings,
      hasMore: hasMore ?? this.hasMore,
      lastDocument:
          clearLastDocument ? null : (lastDocument ?? this.lastDocument),
    );
  }

  List<TherapistBooking> get upcomingBookings => bookings
      .where((b) => b.isUpcoming || b.status == BookingStatus.pending)
      .toList();

  List<TherapistBooking> get completedBookings =>
      bookings.where((b) => b.status == BookingStatus.completed).toList();

  List<TherapistBooking> get cancelledBookings => bookings
      .where(
        (b) =>
            b.status == BookingStatus.cancelled ||
            b.status == BookingStatus.rejected,
      )
      .toList();
}

class AdminBookingNotifier extends StateNotifier<AdminBookingState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityLogService _activityLogService = ActivityLogService();

  AdminBookingNotifier() : super(const AdminBookingState()) {
    _fetchBookings();
  }

  /// Fetch first page of bookings using cursor-based pagination (M6.1).
  Future<void> _fetchBookings() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      hasMore: true,
      clearLastDocument: true,
    );
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .orderBy('scheduled_time', descending: true)
          .limit(kAdminBookingsPageSize)
          .get();

      final bookings = _parseBookings(snapshot.docs);
      final lastDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      state = state.copyWith(
        isLoading: false,
        bookings: bookings,
        hasMore: snapshot.docs.length >= kAdminBookingsPageSize,
        lastDocument: lastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load next page using startAfterDocument cursor (M6.1).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDocument == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .orderBy('scheduled_time', descending: true)
          .startAfterDocument(state.lastDocument!)
          .limit(kAdminBookingsPageSize)
          .get();

      final newBookings = _parseBookings(snapshot.docs);
      final lastDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      state = state.copyWith(
        isLoadingMore: false,
        bookings: [...state.bookings, ...newBookings],
        hasMore: snapshot.docs.length >= kAdminBookingsPageSize,
        lastDocument: lastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  List<TherapistBooking> _parseBookings(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs
        .map((doc) {
          try {
            return TherapistBooking.fromFirestore(doc);
          } catch (e) {
            debugPrint('Error parsing booking ${doc.id}: $e');
            return null;
          }
        })
        .whereType<TherapistBooking>()
        .toList();
  }

  Future<void> refresh() => _fetchBookings();

  Future<void> cancelBooking(
    String bookingId,
    String reason, {
    String? actorUid,
    String? actorName,
  }) async {
    try {
      final adminId = actorUid ?? 'admin';

      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancellation_reason': reason,
        'cancelled_by': adminId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Log activity (was previously silent)
      try {
        await _activityLogService.logActivity(
          type: ActivityType.bookingCreated,
          userId: adminId,
          userName: actorName ?? 'Admin',
          description: 'cancelled booking $bookingId',
          metadata: {
            'booking_id': bookingId,
            'cancellation_reason': reason,
            'actor_uid': adminId,
            'action': 'cancelled',
          },
        );
      } catch (e) {
        debugPrint('Failed to log booking cancellation activity: $e');
      }

      // Update local state
      state = state.copyWith(
        bookings: state.bookings.map((b) {
          if (b.id == bookingId) {
            return b.copyWith(status: BookingStatus.cancelled);
          }
          return b;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel booking: $e');
    }
  }
}

final adminBookingProvider =
    StateNotifierProvider<AdminBookingNotifier, AdminBookingState>((ref) {
      return AdminBookingNotifier();
    });
