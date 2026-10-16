import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/sudan_time.dart';

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

  /// Time for display in Sudan time (e.g., "8:00 PM"), never device-local.
  String get formattedTime => formatSudanTime(startTime, 'en');

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

/// Fixed daily booking hours, Sudan time.
const List<int> kSudanSlotHours = [19, 20, 21];

/// Thrown when the requested slot was taken by another booking.
class SlotTakenException implements Exception {
  const SlotTakenException();
  @override
  String toString() => 'SlotTakenException: slot already booked';
}

/// Pure: the fixed slots for a Sudan [date] minus [takenInstants] (UTC).
List<AvailableSlot> generateSudanSlots(
  DateTime date,
  Set<DateTime> takenInstants,
) {
  final taken = takenInstants.map((t) => t.toUtc()).toSet();
  final slots = <AvailableSlot>[];
  for (final hour in kSudanSlotHours) {
    final start = sudanSlotInstant(date, hour);
    if (taken.contains(start)) continue;
    slots.add(AvailableSlot(
      id: 'slot_${date.year}-${date.month}-${date.day}_$hour',
      startTime: start,
      endTime: start.add(const Duration(hours: 1)),
    ));
  }
  return slots;
}

/// Pure: whether a booking with these fields occupies its slot.
bool isBookingTaken({
  required String? status,
  required String? paymentStatus,
  required DateTime? paymentDeadline,
  required DateTime now,
}) {
  if (status == 'pending' || status == 'confirmed') return true;
  if (status == 'awaiting_payment') {
    if (paymentStatus == 'bank_transfer_pending') return true;
    return paymentDeadline != null && paymentDeadline.isAfter(now);
  }
  return false;
}

/// Earliest bookable instant: 19:00 Sudan, two Sudan days from today.
DateTime earliestBookableInstant({DateTime? now}) {
  final t = sudanToday(now: now);
  return sudanSlotInstant(DateTime(t.year, t.month, t.day + 2), 19);
}

class BookingService {
  final FirebaseFirestore _firestore;

  BookingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _availabilityRef =>
      _firestore.collection('therapist_availability');

  CollectionReference get _bookingsRef => _firestore.collection('bookings');

  /// Instants (UTC) already taken for [therapistId] in [fromUtc, toUtc).
  Future<Set<DateTime>> _takenInstants(
    String therapistId,
    DateTime fromUtc,
    DateTime toUtc,
  ) async {
    final snapshot = await _bookingsRef
        .where('therapist_id', isEqualTo: therapistId)
        .where('scheduled_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fromUtc))
        .where('scheduled_time', isLessThan: Timestamp.fromDate(toUtc))
        .get();
    final now = DateTime.now();
    final taken = <DateTime>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final scheduled = data['scheduled_time'] as Timestamp?;
      if (scheduled == null) continue;
      final deadline = data['payment_deadline'] as Timestamp?;
      if (isBookingTaken(
        status: data['status'] as String?,
        paymentStatus: data['payment_status'] as String?,
        paymentDeadline: deadline?.toDate(),
        now: now,
      )) {
        taken.add(scheduled.toDate().toUtc());
      }
    }
    return taken;
  }

  /// Fixed 19:00/20:00/21:00 Sudan slots for a Sudan [date], minus taken ones.
  /// `therapist_availability` is intentionally ignored. Errors propagate.
  Future<List<AvailableSlot>> getAvailableSlotsForDate(
    String therapistId,
    DateTime date,
  ) async {
    final from = sudanSlotInstant(date, 0);
    final to = from.add(const Duration(days: 1));
    final taken = await _takenInstants(therapistId, from, to);
    return generateSudanSlots(date, taken);
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
    String currency = 'USD',
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
    if (scheduledTime.isBefore(earliestBookableInstant())) {
      throw Exception('Bookings need at least 2 days notice');
    }

    // Re-check right before writing: another client may have just booked it.
    final taken = await _takenInstants(
      therapistId,
      scheduledTime.toUtc(),
      scheduledTime.toUtc().add(const Duration(seconds: 1)),
    );
    if (taken.contains(scheduledTime.toUtc())) {
      throw const SlotTakenException();
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

  /// Confirm booking payment.
  ///
  /// Sets status to 'pending' (not 'confirmed') and payment_status to 'paid'.
  /// This triggers onBookingStatusChanged in Cloud Functions, which notifies
  /// the therapist with a "new paid booking" prompt so they can Accept/Reject.
  /// The therapist accepting moves status to 'confirmed', which then notifies
  /// the client. The home "continue chat" card is gated on
  /// `users/{clientId}.assigned_therapist_id`, which must stay unset until
  /// admin assignment.
  ///
  /// [paymentMethod] identifies which gateway captured the payment. Persisted
  /// so the admin dashboard can show the actual method used (Google Pay,
  /// Apple Pay, PayPal, etc.) instead of guessing from the "Unlock Bank
  /// Transfer" admin control.
  Future<void> confirmBookingPayment(
    String bookingId,
    String paymentId, {
    required String paymentMethod,
  }) async {
    final bookingRef = _bookingsRef.doc(bookingId);
    await bookingRef.update({
      'status': 'pending',
      'payment_status': 'paid',
      'payment_id': paymentId,
      'payment_method': paymentMethod,
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

  /// Record that the user requested to pay via bank transfer (WhatsApp).
  ///
  /// Keeps `status: 'awaiting_payment'` (so the admin's "Confirm Bank Transfer
  /// Received" control stays visible) but moves `payment_status` to the
  /// distinct `bank_transfer_pending` state. This makes the booking show as
  /// "awaiting payment confirmation" for the user (not a normal unpaid
  /// booking) and keeps it out of the `awaiting_payment` expiry sweep. The
  /// admin completes it with [markBankTransferPaid] once the money arrives.
  Future<void> requestBankTransfer(String bookingId) async {
    await _bookingsRef.doc(bookingId).update({
      'payment_method': 'bank_transfer',
      'payment_status': 'bank_transfer_pending',
      'bank_transfer_requested_at': FieldValue.serverTimestamp(),
    });
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

  /// Mark a bank-transfer payment as received and move the booking from
  /// `awaiting_payment` to `pending` so the therapist sees it.
  ///
  /// This is the admin equivalent of the gateway success callback —
  /// card/wallet payments are auto-captured by the Cloud Function and flip
  /// to `paid` automatically, but bank transfers require human verification
  /// (admin checks the bank account). Only call this after confirming the
  /// money actually arrived.
  Future<void> markBankTransferPaid({
    required String bookingId,
    required String adminUid,
    String? reference,
  }) async {
    final paymentId = reference != null && reference.isNotEmpty
        ? reference
        : 'BT-${DateTime.now().millisecondsSinceEpoch}-$adminUid';
    await _bookingsRef.doc(bookingId).update({
      'status': 'pending',
      'payment_status': 'paid',
      'payment_id': paymentId,
      'payment_method': 'bank_transfer',
      'paid_at': FieldValue.serverTimestamp(),
      'bank_transfer_unlocked': true,
      'bank_transfer_confirmed_by': adminUid,
      'bank_transfer_confirmed_at': FieldValue.serverTimestamp(),
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
