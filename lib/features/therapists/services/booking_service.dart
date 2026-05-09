import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents an available time slot for booking
class AvailableSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool isBooked;

  const AvailableSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
  });

  /// Format time for display (e.g., "9:00 AM")
  String get formattedTime {
    final hour = startTime.hour;
    final minute = startTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  factory AvailableSlot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AvailableSlot(
      id: doc.id,
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: (data['end_time'] as Timestamp).toDate(),
      isBooked: data['is_booked'] as bool? ?? false,
    );
  }
}

class BookingService {
  final FirebaseFirestore _firestore;

  BookingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _availabilityRef =>
      _firestore.collection('therapist_availability');

  CollectionReference get _bookingsRef => _firestore.collection('bookings');

  /// Get available slots for a therapist on a specific date
  Future<List<AvailableSlot>> getAvailableSlotsForDate(
    String therapistId,
    DateTime date,
  ) async {
    // Get start and end of the selected date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final snapshot = await _availabilityRef
          .where('therapist_id', isEqualTo: therapistId)
          .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('start_time', isLessThan: Timestamp.fromDate(endOfDay))
          .where('is_booked', isEqualTo: false)
          .orderBy('start_time')
          .get();

      if (snapshot.docs.isEmpty) {
        // Return default slots if no availability configured
        return _getDefaultSlotsForDate(date);
      }

      return snapshot.docs
          .map((doc) => AvailableSlot.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Return default slots on error
      return _getDefaultSlotsForDate(date);
    }
  }

  /// Generate default slots for a date (9 AM - 6 PM, hourly)
  List<AvailableSlot> _getDefaultSlotsForDate(DateTime date) {
    final slots = <AvailableSlot>[];
    final now = DateTime.now();

    for (int hour = 9; hour <= 17; hour++) {
      final startTime = DateTime(date.year, date.month, date.day, hour);
      final endTime = startTime.add(const Duration(hours: 1));

      // Skip past slots for today
      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year &&
          startTime.isBefore(now)) {
        continue;
      }

      slots.add(AvailableSlot(
        id: 'default_${date.toIso8601String()}_$hour',
        startTime: startTime,
        endTime: endTime,
        isBooked: false,
      ));
    }

    return slots;
  }

  /// Create a booking with foreign key validation
  Future<String> createBooking({
    required String therapistId,
    required String therapistName,
    required String clientId,
    required String clientName,
    required String clientEmail,
    required DateTime scheduledTime,
    required int durationMinutes,
    required String sessionType,
    required double amount,
    String currency = 'SAR',
    String? notes,
  }) async {
    // Validate therapist exists
    final therapistDoc = await _firestore.collection('therapists').doc(therapistId).get();
    if (!therapistDoc.exists) {
      throw Exception('Therapist not found: $therapistId');
    }

    // Validate therapist is approved and active
    final therapistData = therapistDoc.data()!;
    if (therapistData['approval_status'] != 'approved') {
      throw Exception('Therapist is not approved for bookings');
    }
    if (therapistData['is_active'] != true) {
      throw Exception('Therapist is not currently accepting bookings');
    }

    // Validate client exists (user document)
    final clientDoc = await _firestore.collection('users').doc(clientId).get();
    if (!clientDoc.exists) {
      throw Exception('Client not found: $clientId');
    }

    // Validate scheduled time is in the future
    if (scheduledTime.isBefore(DateTime.now())) {
      throw Exception('Cannot book appointments in the past');
    }

    // Create the booking with payment fields
    final paymentDeadline = DateTime.now().add(const Duration(hours: 24));
    final docRef = await _bookingsRef.add({
      'therapist_id': therapistId,
      'therapist_name': therapistName,
      'client_id': clientId,
      'client_name': clientName,
      'client_email': clientEmail,
      'scheduled_time': Timestamp.fromDate(scheduledTime),
      'duration_minutes': durationMinutes,
      'session_type': sessionType,
      'status': 'awaiting_payment',
      'payment_status': 'awaiting_payment',
      'payment_deadline': Timestamp.fromDate(paymentDeadline),
      'payment_id': null,
      'amount': amount,
      'currency': currency,
      'notes': notes,
      // Bank transfer is locked until admin explicitly unlocks it.
      'bank_transfer_unlocked': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Mark the availability slot as booked (if it exists)
    await _markSlotAsBooked(therapistId, scheduledTime, docRef.id);

    return docRef.id;
  }

  /// Mark a slot as booked
  Future<void> _markSlotAsBooked(
    String therapistId,
    DateTime scheduledTime,
    String bookingId,
  ) async {
    final startOfSlot = DateTime(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
    );

    // Find the slot
    final snapshot = await _availabilityRef
        .where('therapist_id', isEqualTo: therapistId)
        .where('start_time', isEqualTo: Timestamp.fromDate(startOfSlot))
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'is_booked': true,
        'booking_id': bookingId,
      });
    }
  }

  /// Get user's upcoming bookings
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    final snapshot = await _bookingsRef
        .where('client_id', isEqualTo: userId)
        .where('scheduled_time', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('scheduled_time')
        .get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  /// Confirm booking payment
  Future<void> confirmBookingPayment(String bookingId, String paymentId) async {
    await _bookingsRef.doc(bookingId).update({
      'status': 'confirmed',
      'payment_status': 'paid',
      'payment_id': paymentId,
      'paid_at': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel expired unpaid bookings for a user (client-side 24h expiry)
  Future<void> cancelExpiredBookings(String userId) async {
    final now = Timestamp.fromDate(DateTime.now());
    final snapshot = await _bookingsRef
        .where('client_id', isEqualTo: userId)
        .where('payment_status', isEqualTo: 'awaiting_payment')
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final deadline = data['payment_deadline'] as Timestamp?;
      if (deadline != null && deadline.compareTo(now) < 0) {
        await cancelBooking(doc.id, 'payment_timeout');
      }
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, String reason) async {
    final doc = await _bookingsRef.doc(bookingId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    // Update booking status
    await _bookingsRef.doc(bookingId).update({
      'status': 'cancelled',
      'cancellation_reason': reason,
      'cancelled_at': FieldValue.serverTimestamp(),
    });

    // Free up the availability slot
    final therapistId = data['therapist_id'] as String;

    final slotSnapshot = await _availabilityRef
        .where('therapist_id', isEqualTo: therapistId)
        .where('booking_id', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (slotSnapshot.docs.isNotEmpty) {
      await slotSnapshot.docs.first.reference.update({
        'is_booked': false,
        'booking_id': null,
      });
    }
  }

  /// Unlock the bank-transfer payment option for a booking.
  ///
  /// Called by the admin after confirming the therapist assignment.
  /// Sets [bank_transfer_unlocked] to true so the user can complete
  /// payment via bank transfer on their BookingPaymentScreen.
  Future<void> unlockBankTransfer(String bookingId) async {
    await _bookingsRef.doc(bookingId).update({
      'bank_transfer_unlocked': true,
      'bank_transfer_unlocked_at': FieldValue.serverTimestamp(),
    });
  }
}

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

/// Provider for available slots on a specific date
final availableSlotsProvider = FutureProvider.family<List<AvailableSlot>, ({String therapistId, DateTime date})>((ref, params) {
  final service = ref.watch(bookingServiceProvider);
  return service.getAvailableSlotsForDate(params.therapistId, params.date);
});
