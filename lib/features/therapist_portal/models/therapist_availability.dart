import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single availability slot for a therapist
class AvailabilitySlot {
  final String id;
  final String therapistId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isBooked;
  final String? bookingId;
  final DateTime createdAt;

  const AvailabilitySlot({
    required this.id,
    required this.therapistId,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.bookingId,
    required this.createdAt,
  });

  /// Duration in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// Check if slot is in the past
  bool get isPast => endTime.isBefore(DateTime.now());

  /// Check if slot is available for booking
  bool get isAvailable => !isBooked && !isPast;

  /// Create a copy with updated fields
  AvailabilitySlot copyWith({
    String? id,
    String? therapistId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isBooked,
    String? bookingId,
    DateTime? createdAt,
  }) {
    return AvailabilitySlot(
      id: id ?? this.id,
      therapistId: therapistId ?? this.therapistId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isBooked: isBooked ?? this.isBooked,
      bookingId: bookingId ?? this.bookingId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Create from Firestore document
  factory AvailabilitySlot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AvailabilitySlot(
      id: doc.id,
      therapistId: data['therapist_id'] as String? ?? '',
      startTime: _parseDateTime(data['start_time']) ?? DateTime.now(),
      endTime: _parseDateTime(data['end_time']) ?? DateTime.now(),
      isBooked: data['is_booked'] as bool? ?? false,
      bookingId: data['booking_id'] as String?,
      createdAt: _parseDateTime(data['created_at']) ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'therapist_id': therapistId,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'is_booked': isBooked,
      'booking_id': bookingId,
      'created_at': Timestamp.fromDate(createdAt),
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

  @override
  String toString() {
    return 'AvailabilitySlot(id: $id, start: $startTime, end: $endTime, booked: $isBooked)';
  }
}

/// Time range for weekly availability template
class TimeRange {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const TimeRange({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  /// Duration in minutes
  int get durationMinutes {
    final startInMinutes = startHour * 60 + startMinute;
    final endInMinutes = endHour * 60 + endMinute;
    return endInMinutes - startInMinutes;
  }

  /// Format as string (e.g., "09:00 - 17:00")
  String get formatted {
    final startStr = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final endStr = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  /// Create from map
  factory TimeRange.fromMap(Map<String, dynamic> map) {
    return TimeRange(
      startHour: map['start_hour'] as int? ?? 9,
      startMinute: map['start_minute'] as int? ?? 0,
      endHour: map['end_hour'] as int? ?? 17,
      endMinute: map['end_minute'] as int? ?? 0,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'start_hour': startHour,
      'start_minute': startMinute,
      'end_hour': endHour,
      'end_minute': endMinute,
    };
  }
}

/// Weekly availability template for a therapist
class WeeklyAvailability {
  final String therapistId;
  final Map<int, List<TimeRange>> weeklySlots; // day (0=Sun, 1=Mon, etc.) -> time ranges
  final int slotDurationMinutes; // Default session duration
  final DateTime updatedAt;

  const WeeklyAvailability({
    required this.therapistId,
    required this.weeklySlots,
    this.slotDurationMinutes = 60,
    required this.updatedAt,
  });

  /// Check if a day is available
  bool isDayAvailable(int day) {
    return weeklySlots.containsKey(day) && weeklySlots[day]!.isNotEmpty;
  }

  /// Get available days
  List<int> get availableDays {
    return weeklySlots.keys.where((day) => weeklySlots[day]!.isNotEmpty).toList()..sort();
  }

  /// Create a copy with updated fields
  WeeklyAvailability copyWith({
    String? therapistId,
    Map<int, List<TimeRange>>? weeklySlots,
    int? slotDurationMinutes,
    DateTime? updatedAt,
  }) {
    return WeeklyAvailability(
      therapistId: therapistId ?? this.therapistId,
      weeklySlots: weeklySlots ?? this.weeklySlots,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create from Firestore document
  factory WeeklyAvailability.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final slots = <int, List<TimeRange>>{};

    final slotsData = data['weekly_slots'] as Map<String, dynamic>? ?? {};
    slotsData.forEach((key, value) {
      final day = int.tryParse(key) ?? 0;
      final ranges = (value as List<dynamic>? ?? [])
          .map((r) => TimeRange.fromMap(r as Map<String, dynamic>))
          .toList();
      slots[day] = ranges;
    });

    return WeeklyAvailability(
      therapistId: data['therapist_id'] as String? ?? doc.id,
      weeklySlots: slots,
      slotDurationMinutes: data['slot_duration_minutes'] as int? ?? 60,
      updatedAt: _parseDateTime(data['updated_at']) ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    final slotsMap = <String, dynamic>{};
    weeklySlots.forEach((day, ranges) {
      slotsMap[day.toString()] = ranges.map((r) => r.toMap()).toList();
    });

    return {
      'therapist_id': therapistId,
      'weekly_slots': slotsMap,
      'slot_duration_minutes': slotDurationMinutes,
      'updated_at': Timestamp.fromDate(updatedAt),
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

  /// Create default availability (9 AM - 5 PM, Mon-Fri)
  factory WeeklyAvailability.defaultTemplate(String therapistId) {
    const defaultRange = TimeRange(
      startHour: 9,
      startMinute: 0,
      endHour: 17,
      endMinute: 0,
    );

    return WeeklyAvailability(
      therapistId: therapistId,
      weeklySlots: {
        1: [defaultRange], // Monday
        2: [defaultRange], // Tuesday
        3: [defaultRange], // Wednesday
        4: [defaultRange], // Thursday
        5: [defaultRange], // Friday
      },
      slotDurationMinutes: 60,
      updatedAt: DateTime.now(),
    );
  }
}
