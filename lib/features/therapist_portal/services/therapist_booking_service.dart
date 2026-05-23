import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/therapist_booking.dart';
import '../../admin/providers/activity_log_provider.dart';
import '../../notifications/services/notification_service.dart';

/// Service for managing therapist bookings
class TherapistBookingService {
  final FirebaseFirestore _firestore;
  final ActivityLogService? _activityLogService;

  TherapistBookingService({
    FirebaseFirestore? firestore,
    ActivityLogService? activityLogService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _activityLogService = activityLogService ?? ActivityLogService();

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _bookingsCollection =>
      _firestore.collection('bookings');

  /// Get all bookings for a therapist.
  ///
  /// When no explicit [status] filter is passed, `awaiting_payment` bookings
  /// are hidden — the therapist must not see (or be able to accept/reject)
  /// a booking whose payment hasn't been captured yet. Bookings only become
  /// visible after `confirmBookingPayment` flips status to `'pending'`.
  Stream<List<TherapistBooking>> getBookings(
    String therapistId, {
    BookingStatus? status,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _bookingsCollection.where(
      'therapist_id',
      isEqualTo: therapistId,
    );

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    query = query.orderBy('scheduled_time', descending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      final all = snapshot.docs
          .map((doc) => TherapistBooking.fromFirestore(doc))
          .toList();
      if (status != null) return all;
      // No explicit status filter: hide unpaid bookings.
      return all
          .where((b) => b.status != BookingStatus.awaitingPayment)
          .toList();
    });
  }

  /// Get upcoming bookings for a therapist
  Stream<List<TherapistBooking>> getUpcomingBookings(String therapistId) {
    final now = DateTime.now();
    return _bookingsCollection
        .where('therapist_id', isEqualTo: therapistId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .where('scheduled_time', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('scheduled_time')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TherapistBooking.fromFirestore(doc))
              .toList();
        });
  }

  /// Get pending booking requests for a therapist
  Stream<List<TherapistBooking>> getPendingBookings(String therapistId) {
    return _bookingsCollection
        .where('therapist_id', isEqualTo: therapistId)
        .where('status', isEqualTo: BookingStatus.pending.name)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TherapistBooking.fromFirestore(doc))
              .toList();
        });
  }

  /// Get today's bookings for a therapist
  Stream<List<TherapistBooking>> getTodaysBookings(String therapistId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _bookingsCollection
        .where('therapist_id', isEqualTo: therapistId)
        .where('status', isEqualTo: BookingStatus.confirmed.name)
        .where(
          'scheduled_time',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('scheduled_time', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('scheduled_time')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TherapistBooking.fromFirestore(doc))
              .toList();
        });
  }

  /// Get past bookings for a therapist
  Stream<List<TherapistBooking>> getPastBookings(
    String therapistId, {
    int limit = 50,
  }) {
    final now = DateTime.now();
    return _bookingsCollection
        .where('therapist_id', isEqualTo: therapistId)
        .where('scheduled_time', isLessThan: Timestamp.fromDate(now))
        .orderBy('scheduled_time', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TherapistBooking.fromFirestore(doc))
              .toList();
        });
  }

  /// Get a single booking by ID
  Future<TherapistBooking?> getBooking(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) return null;
      return TherapistBooking.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  /// Accept a booking request
  Future<void> acceptBooking(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': BookingStatus.confirmed.name,
        'confirmed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify the client that their booking was accepted
      try {
        final bookingDoc = await _bookingsCollection.doc(bookingId).get();
        final data = bookingDoc.data();
        if (data != null) {
          final clientId = data['client_id'] as String?;
          final therapistId = data['therapist_id'] as String?;

          if (clientId != null && clientId.isNotEmpty) {
            String therapistName = 'Your therapist';
            if (therapistId != null) {
              final therapistDoc = await _firestore
                  .collection('therapists')
                  .doc(therapistId)
                  .get();
              therapistName =
                  therapistDoc.data()?['full_name'] as String? ??
                  therapistDoc.data()?['name'] as String? ??
                  'Your therapist';
            }

            final notificationService = NotificationService(
              firestore: _firestore,
            );
            await notificationService.createBookingNotification(
              userId: clientId,
              title: 'Booking Accepted',
              body: '$therapistName has accepted your booking',
              bookingId: bookingId,
            );
          }
        }
      } catch (e) {
        // Don't fail the accept operation if notification fails
        debugPrint(
          'TherapistBookingService: Failed to send acceptance notification: $e',
        );
      }
    } catch (e) {
      throw Exception('Failed to accept booking: $e');
    }
  }

  /// Reject a booking request
  Future<void> rejectBooking(String bookingId, String reason) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': BookingStatus.rejected.name,
        'rejection_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify the client
      try {
        final bookingDoc = await _bookingsCollection.doc(bookingId).get();
        final data = bookingDoc.data();
        if (data != null) {
          final clientId = data['client_id'] as String?;
          if (clientId != null && clientId.isNotEmpty) {
            final notificationService = NotificationService(
              firestore: _firestore,
            );
            await notificationService.createBookingNotification(
              userId: clientId,
              title: 'Booking Update',
              body: 'Your booking request was not accepted',
              bookingId: bookingId,
            );
          }
        }
      } catch (e) {
        debugPrint(
          'TherapistBookingService: Failed to send rejection notification: $e',
        );
      }
    } catch (e) {
      throw Exception('Failed to reject booking: $e');
    }
  }

  /// Update private notes
  Future<void> updatePrivateNotes(String bookingId, String notes) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'private_notes': notes,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update private notes: $e');
    }
  }

  /// Complete a session
  Future<void> completeSession(String bookingId, {String? notes}) async {
    try {
      // Get booking details first for activity log
      final bookingDoc = await _bookingsCollection.doc(bookingId).get();
      final bookingData = bookingDoc.data();

      final updates = <String, dynamic>{
        'status': BookingStatus.completed.name,
        'completed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _bookingsCollection.doc(bookingId).update(updates);

      // Log activity
      if (bookingData != null && _activityLogService != null) {
        final therapistId = bookingData['therapist_id'] as String?;
        final clientName = bookingData['client_name'] as String? ?? 'Patient';

        // Get therapist name
        if (therapistId != null) {
          final therapistDoc = await _firestore
              .collection('therapists')
              .doc(therapistId)
              .get();
          final therapistName =
              therapistDoc.data()?['full_name'] as String? ??
              therapistDoc.data()?['name'] as String? ??
              'Therapist';

          await _activityLogService.logSessionCompleted(
            therapistId: therapistId,
            therapistName: therapistName,
            clientName: clientName,
          );
        }
      }

      // Notify the client that session is completed
      try {
        final cId = bookingData?['client_id'] as String?;
        if (cId != null && cId.isNotEmpty) {
          final notificationService = NotificationService(
            firestore: _firestore,
          );
          await notificationService.createBookingNotification(
            userId: cId,
            title: 'Session Completed',
            body: 'Your therapy session has been completed',
            bookingId: bookingId,
          );
        }
      } catch (e) {
        debugPrint(
          'TherapistBookingService: Failed to send completion notification: $e',
        );
      }
    } catch (e) {
      throw Exception('Failed to complete session: $e');
    }
  }

  /// Mark client as no-show
  Future<void> markNoShow(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': BookingStatus.noShow.name,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify the client
      try {
        final bookingDoc = await _bookingsCollection.doc(bookingId).get();
        final data = bookingDoc.data();
        if (data != null) {
          final clientId = data['client_id'] as String?;
          if (clientId != null && clientId.isNotEmpty) {
            final notificationService = NotificationService(
              firestore: _firestore,
            );
            await notificationService.createBookingNotification(
              userId: clientId,
              title: 'Session Missed',
              body: 'You were marked as a no-show for your session',
              bookingId: bookingId,
            );
          }
        }
      } catch (e) {
        debugPrint(
          'TherapistBookingService: Failed to send no-show notification: $e',
        );
      }
    } catch (e) {
      throw Exception('Failed to mark no-show: $e');
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
        'cancellation_reason': reason,
        'cancelled_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify the client
      try {
        final bookingDoc = await _bookingsCollection.doc(bookingId).get();
        final data = bookingDoc.data();
        if (data != null) {
          final clientId = data['client_id'] as String?;
          if (clientId != null && clientId.isNotEmpty) {
            final notificationService = NotificationService(
              firestore: _firestore,
            );
            await notificationService.createBookingNotification(
              userId: clientId,
              title: 'Booking Cancelled',
              body: 'Your booking has been cancelled',
              bookingId: bookingId,
            );
          }
        }
      } catch (e) {
        debugPrint(
          'TherapistBookingService: Failed to send cancellation notification: $e',
        );
      }
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Add or update session notes
  Future<void> updateSessionNotes(String bookingId, String notes) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'notes': notes,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update notes: $e');
    }
  }

  /// Get booking statistics for a therapist
  Future<Map<String, dynamic>> getBookingStats(String therapistId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Get all bookings for this month
      final snapshot = await _bookingsCollection
          .where('therapist_id', isEqualTo: therapistId)
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .get();

      int totalBookings = snapshot.docs.length;
      int completedBookings = 0;
      int cancelledBookings = 0;
      int pendingBookings = 0;
      double totalEarnings = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = BookingStatusX.fromString(data['status'] as String?);

        switch (status) {
          case BookingStatus.completed:
            completedBookings++;
            totalEarnings += (data['amount'] as num?)?.toDouble() ?? 0.0;
            break;
          case BookingStatus.cancelled:
          case BookingStatus.rejected:
            cancelledBookings++;
            break;
          case BookingStatus.pending:
            pendingBookings++;
            break;
          default:
            break;
        }
      }

      return {
        'total_bookings': totalBookings,
        'completed_bookings': completedBookings,
        'cancelled_bookings': cancelledBookings,
        'pending_bookings': pendingBookings,
        'total_earnings': totalEarnings,
        'month': now.month,
        'year': now.year,
      };
    } catch (e) {
      throw Exception('Failed to get booking stats: $e');
    }
  }

  /// Create a new booking (called from client side)
  Future<String> createBooking(TherapistBooking booking) async {
    try {
      final docRef = await _bookingsCollection.add(booking.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get all bookings for a client (user)
  /// Used for chat escalation to show available therapists
  Future<List<TherapistBooking>> getBookingsForClient(
    String clientId, {
    List<BookingStatus>? statuses,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _bookingsCollection.where(
        'client_id',
        isEqualTo: clientId,
      );

      // If no specific statuses provided, get pending, confirmed, and completed
      final statusList =
          statuses ??
          [
            BookingStatus.pending,
            BookingStatus.confirmed,
            BookingStatus.completed,
          ];

      query = query.where(
        'status',
        whereIn: statusList.map((s) => s.name).toList(),
      );

      final snapshot = await query
          .orderBy('scheduled_time', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => TherapistBooking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get client bookings: $e');
    }
  }

  /// Stream bookings for a client (user)
  Stream<List<TherapistBooking>> streamClientBookings(String clientId) {
    return _bookingsCollection
        .where('client_id', isEqualTo: clientId)
        .where(
          'status',
          whereIn: [BookingStatus.pending.name, BookingStatus.confirmed.name],
        )
        .orderBy('scheduled_time')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TherapistBooking.fromFirestore(doc))
              .toList();
        });
  }
}
