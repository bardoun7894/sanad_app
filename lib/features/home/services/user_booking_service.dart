import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents an upcoming session for the user
class UpcomingSession {
  final String id;
  final String therapistId;
  final String therapistName;
  final String? therapistPhotoUrl;
  final DateTime scheduledTime;
  final int durationMinutes;
  final String sessionType;
  final String status;

  const UpcomingSession({
    required this.id,
    required this.therapistId,
    required this.therapistName,
    this.therapistPhotoUrl,
    required this.scheduledTime,
    this.durationMinutes = 60,
    required this.sessionType,
    required this.status,
  });

  factory UpcomingSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime scheduledTime;
    final timeField = data['scheduled_time'];
    if (timeField is Timestamp) {
      scheduledTime = timeField.toDate();
    } else if (timeField is DateTime) {
      scheduledTime = timeField;
    } else {
      scheduledTime = DateTime.now();
    }

    return UpcomingSession(
      id: doc.id,
      therapistId: data['therapist_id'] as String? ?? '',
      therapistName: data['therapist_name'] as String? ?? 'Therapist',
      therapistPhotoUrl: data['therapist_photo_url'] as String?,
      scheduledTime: scheduledTime,
      durationMinutes: data['duration_minutes'] as int? ?? 60,
      sessionType: data['session_type'] as String? ?? 'video',
      status: data['status'] as String? ?? 'pending',
    );
  }

  /// Format date for display (e.g., "Thursday, 5:00 PM")
  String get formattedDateTime {
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final weekday = weekdays[scheduledTime.weekday - 1];

    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$weekday, $displayHour:$minute $period';
  }

  /// Format date for Arabic display
  String get formattedDateTimeAr {
    final weekdays = [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
      'الجمعة', 'السبت', 'الأحد'
    ];
    final weekday = weekdays[scheduledTime.weekday - 1];

    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$weekday، $displayHour:$minute $period';
  }

  bool get isToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return scheduledTime.isAfter(weekStart) && scheduledTime.isBefore(weekEnd);
  }
}

class UserBookingService {
  final FirebaseFirestore _firestore;

  UserBookingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _bookingsRef => _firestore.collection('bookings');

  /// Get upcoming sessions for a user (confirmed or pending)
  Stream<List<UpcomingSession>> getUpcomingSessionsStream(String userId) {
    final now = DateTime.now();

    return _bookingsRef
        .where('client_id', isEqualTo: userId)
        .where('scheduled_time', isGreaterThan: Timestamp.fromDate(now))
        .where('status', whereIn: ['confirmed', 'pending'])
        .orderBy('scheduled_time')
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UpcomingSession.fromFirestore(doc))
            .toList());
  }

  /// Get next upcoming session (for home screen display)
  Future<UpcomingSession?> getNextUpcomingSession(String userId) async {
    final now = DateTime.now();

    final snapshot = await _bookingsRef
        .where('client_id', isEqualTo: userId)
        .where('scheduled_time', isGreaterThan: Timestamp.fromDate(now))
        .where('status', whereIn: ['confirmed', 'pending'])
        .orderBy('scheduled_time')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return UpcomingSession.fromFirestore(snapshot.docs.first);
  }

  /// Get count of completed sessions for a user
  Future<int> getCompletedSessionsCount(String userId) async {
    final snapshot = await _bookingsRef
        .where('client_id', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .count()
        .get();

    return snapshot.count ?? 0;
  }
}

final userBookingServiceProvider = Provider<UserBookingService>((ref) {
  return UserBookingService();
});
