import 'package:cloud_firestore/cloud_firestore.dart';
import '../../therapist_portal/models/therapist_booking.dart';

class UserBookingService {
  final FirebaseFirestore _firestore;

  UserBookingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _bookingsCollection =>
      _firestore.collection('bookings');

  /// Get upcoming bookings for a client
  /// Also auto-cancels expired unpaid bookings (client-side 24h expiry)
  Stream<List<TherapistBooking>> getUpcomingBookings(String clientId) {
    return _bookingsCollection
        .where('client_id', isEqualTo: clientId)
        .where('status', whereIn: ['pending', 'confirmed', 'awaiting_payment'])
        .orderBy('scheduled_time', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          final now = DateTime.now();
          final bookings = <TherapistBooking>[];

          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final booking = TherapistBooking.fromFirestore(doc);

            // Auto-cancel expired unpaid bookings
            if (data != null &&
                data['payment_status'] == 'awaiting_payment' &&
                data['payment_deadline'] != null) {
              final deadline = (data['payment_deadline'] as Timestamp).toDate();
              if (deadline.isBefore(now)) {
                // Expired - cancel it
                await doc.reference.update({
                  'status': 'cancelled',
                  'payment_status': 'expired',
                  'cancellation_reason': 'payment_timeout',
                  'cancelled_at': FieldValue.serverTimestamp(),
                });
                continue; // Skip this booking from upcoming list
              }
            }

            if (booking.scheduledTime.isAfter(now)) {
              bookings.add(booking);
            }
          }

          return bookings;
        });
  }

  /// Get past bookings for a client
  Stream<List<TherapistBooking>> getPastBookings(String clientId) {
    return _bookingsCollection
        .where('client_id', isEqualTo: clientId)
        .orderBy('scheduled_time', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TherapistBooking.fromFirestore(doc))
              .where(
                (booking) =>
                    booking.scheduledTime.isBefore(DateTime.now()) ||
                    [
                      'completed',
                      'cancelled',
                      'rejected',
                    ].contains(booking.status.name),
              )
              .toList();
        });
  }
}
