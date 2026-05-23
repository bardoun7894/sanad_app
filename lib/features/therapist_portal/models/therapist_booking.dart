import 'package:cloud_firestore/cloud_firestore.dart';
import '../../therapists/models/therapist.dart';

/// Booking status for therapist view
enum BookingStatus {
  awaitingPayment, // Client booked but hasn't paid yet
  pending, // Awaiting therapist confirmation (post-payment)
  confirmed, // Therapist accepted the booking
  rejected, // Therapist rejected the booking
  completed, // Session completed successfully
  cancelled, // Client or therapist cancelled
  noShow, // Client didn't show up
}

/// Extension methods for BookingStatus
extension BookingStatusX on BookingStatus {
  String get name {
    switch (this) {
      case BookingStatus.awaitingPayment:
        return 'awaiting_payment';
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.rejected:
        return 'rejected';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.noShow:
        return 'no_show';
    }
  }

  static BookingStatus fromString(String? value) {
    switch (value) {
      case 'awaiting_payment':
        return BookingStatus.awaitingPayment;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'rejected':
        return BookingStatus.rejected;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'no_show':
        return BookingStatus.noShow;
      case 'pending':
      default:
        // Legacy/unknown statuses fall back to pending for safety
        return BookingStatus.pending;
    }
  }

  /// Check if booking can be modified (awaitingPayment is not modifiable by therapist)
  bool get isModifiable {
    return this == BookingStatus.pending || this == BookingStatus.confirmed;
  }

  /// Check if booking is terminal (cannot change)
  bool get isTerminal {
    return this == BookingStatus.completed ||
        this == BookingStatus.cancelled ||
        this == BookingStatus.noShow ||
        this == BookingStatus.rejected;
  }
}

/// Booking model for therapist dashboard
class TherapistBooking {
  final String id;
  final String therapistId;
  final String clientId;
  final String clientName;
  final String? clientEmail;
  final String? clientPhotoUrl;
  final int? clientAge;
  final String? primaryComplaint;
  final DateTime scheduledTime;
  final int durationMinutes;
  final SessionType sessionType;
  final BookingStatus status;
  final double amount;
  final String currency;
  final String? notes; // Public/System notes
  final String? privateNotes; // Private therapist notes
  final String? cancellationReason;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final int? actualDurationSeconds;
  // Payment gateway that captured the booking. Populated by
  // BookingService.confirmBookingPayment so the admin dashboard can show
  // the real method used (Google Pay / Apple Pay / PayPal / Bank Transfer /
  // Freemius card) instead of guessing from the Unlock Bank Transfer
  // admin control.
  final String? paymentMethod;
  final String? paymentStatus;

  const TherapistBooking({
    required this.id,
    required this.therapistId,
    required this.clientId,
    required this.clientName,
    this.clientEmail,
    this.clientPhotoUrl,
    this.clientAge,
    this.primaryComplaint,
    required this.scheduledTime,
    this.durationMinutes = 60,
    required this.sessionType,
    this.status = BookingStatus.pending,
    required this.amount,
    this.currency = 'USD',
    this.notes,
    this.privateNotes,
    this.cancellationReason,
    this.rejectionReason,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.actualDurationSeconds,
    this.paymentMethod,
    this.paymentStatus,
  });

  static String _symbol(String code) => const {
        'USD': '\$', 'SAR': '\$', 'AED': 'AED', 'EUR': '€', 'GBP': '£',
      }[code] ?? '\$';

  String get formattedAmount => '${_symbol(currency)}${amount.toStringAsFixed(2)}';

  /// End time of the session
  DateTime get endTime => scheduledTime.add(Duration(minutes: durationMinutes));

  /// Check if session is in the past
  bool get isPast => endTime.isBefore(DateTime.now());

  /// Check if session is upcoming
  bool get isUpcoming =>
      status == BookingStatus.confirmed &&
      scheduledTime.isAfter(DateTime.now());

  /// Check if session is today
  bool get isToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }

  /// Create a copy with updated fields
  TherapistBooking copyWith({
    String? id,
    String? therapistId,
    String? clientId,
    String? clientName,
    String? clientEmail,
    String? clientPhotoUrl,
    int? clientAge,
    String? primaryComplaint,
    DateTime? scheduledTime,
    int? durationMinutes,
    SessionType? sessionType,
    BookingStatus? status,
    double? amount,
    String? currency,
    String? notes,
    String? privateNotes,
    String? cancellationReason,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    int? actualDurationSeconds,
    String? paymentMethod,
    String? paymentStatus,
  }) {
    return TherapistBooking(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhotoUrl: clientPhotoUrl ?? this.clientPhotoUrl,
      clientAge: clientAge ?? this.clientAge,
      primaryComplaint: primaryComplaint ?? this.primaryComplaint,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      privateNotes: privateNotes ?? this.privateNotes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      actualDurationSeconds:
          actualDurationSeconds ?? this.actualDurationSeconds,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  /// Create from Firestore document
  factory TherapistBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TherapistBooking(
      id: doc.id,
      therapistId: data['therapist_id'] as String? ?? '',
      clientId: data['client_id'] as String? ?? '',
      clientName: data['client_name'] as String? ?? '',
      clientEmail: data['client_email'] as String?,
      clientPhotoUrl: data['client_photo_url'] as String?,
      clientAge: data['client_age'] as int?,
      primaryComplaint: data['primary_complaint'] as String?,
      scheduledTime: _parseDateTime(data['scheduled_time']) ?? DateTime.now(),
      durationMinutes: data['duration_minutes'] as int? ?? 60,
      sessionType: _parseSessionType(data['session_type'] as String?),
      status: BookingStatusX.fromString(data['status'] as String?),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      notes: data['notes'] as String?,
      privateNotes: data['private_notes'] as String?,
      cancellationReason: data['cancellation_reason'] as String?,
      rejectionReason: data['rejection_reason'] as String?,
      createdAt: _parseDateTime(data['created_at']) ?? DateTime.now(),
      confirmedAt: _parseDateTime(data['confirmed_at']),
      completedAt: _parseDateTime(data['completed_at']),
      cancelledAt: _parseDateTime(data['cancelled_at']),
      actualDurationSeconds: data['actual_duration_seconds'] as int?,
      paymentMethod: data['payment_method'] as String?,
      paymentStatus: data['payment_status'] as String?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'therapist_id': therapistId,
      'client_id': clientId,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_photo_url': clientPhotoUrl,
      'client_age': clientAge,
      'primary_complaint': primaryComplaint,
      'scheduled_time': Timestamp.fromDate(scheduledTime),
      'duration_minutes': durationMinutes,
      'session_type': sessionType.firestoreValue,
      'status': status.name,
      'amount': amount,
      'currency': currency,
      'notes': notes,
      'private_notes': privateNotes,
      'cancellation_reason': cancellationReason,
      'rejection_reason': rejectionReason,
      'created_at': Timestamp.fromDate(createdAt),
      'confirmed_at': confirmedAt != null
          ? Timestamp.fromDate(confirmedAt!)
          : null,
      'completed_at': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'cancelled_at': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'actual_duration_seconds': actualDurationSeconds,
    };
  }

  /// Helper to parse DateTime from Firestore
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Helper to parse SessionType (accepts both legacy 'inPerson' and canonical 'in_person')
  static SessionType _parseSessionType(String? value) {
    return SessionTypeFirestore.fromFirestore(value);
  }

  @override
  String toString() {
    return 'TherapistBooking(id: $id, client: $clientName, time: $scheduledTime, status: ${status.name})';
  }
}
