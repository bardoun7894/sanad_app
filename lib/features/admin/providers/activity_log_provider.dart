import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_log.dart';

/// Provider for recent activity logs (last 20 activities)
final recentActivityProvider = StreamProvider<List<ActivityLog>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collection('activity_logs')
      .orderBy('timestamp', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          // Return empty list if no activity logs yet
          return <ActivityLog>[];
        }

        return snapshot.docs
            .map((doc) => ActivityLog.fromFirestore(doc))
            .toList();
      })
      .handleError((error) {
        // Return empty list on error instead of throwing
        debugPrint('Error loading activity logs: $error');
        return <ActivityLog>[];
      });
});

/// Service for logging activities to Firestore.
///
/// All log entries include an `actor_uid` field to identify who performed
/// the action, ensuring audit trail consistency across both Flutter and
/// Laravel admin stacks.
class ActivityLogService {
  final FirebaseFirestore _firestore;

  ActivityLogService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Log an activity to Firestore.
  ///
  /// The [userId] field identifies the actor (admin or user) who performed
  /// the action. This is also stored as `actor_uid` for cross-stack
  /// consistency with the Laravel admin panel.
  Future<void> logActivity({
    required ActivityType type,
    required String userId,
    required String userName,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activity = ActivityLog(
        id: '', // Will be auto-generated
        type: type,
        userId: userId,
        userName: userName,
        description: description,
        timestamp: DateTime.now(),
        actorUid: userId,
        metadata: metadata,
      );

      await _firestore.collection('activity_logs').add(activity.toFirestore());
    } catch (e) {
      // Log error but don't throw - activity logging should never break the app
      debugPrint('Failed to log activity: $e');
    }
  }

  /// Helper method: Log session completion
  Future<void> logSessionCompleted({
    required String therapistId,
    required String therapistName,
    required String clientName,
  }) async {
    await logActivity(
      type: ActivityType.sessionCompleted,
      userId: therapistId,
      userName: therapistName,
      description: 'completed a session with $clientName',
      metadata: {'client_name': clientName, 'actor_uid': therapistId},
    );
  }

  /// Helper method: Log booking creation
  Future<void> logBookingCreated({
    required String userId,
    required String userName,
    required String therapistName,
  }) async {
    await logActivity(
      type: ActivityType.bookingCreated,
      userId: userId,
      userName: userName,
      description: 'booked a session with $therapistName',
      metadata: {'therapist_name': therapistName, 'actor_uid': userId},
    );
  }

  /// Helper method: Log mood entry
  Future<void> logMoodLogged({
    required String userId,
    required String userName,
    required String mood,
  }) async {
    await logActivity(
      type: ActivityType.moodLogged,
      userId: userId,
      userName: userName,
      description: 'logged mood: $mood',
      metadata: {'mood': mood, 'actor_uid': userId},
    );
  }

  /// Helper method: Log community post
  Future<void> logPostCreated({
    required String userId,
    required String userName,
  }) async {
    await logActivity(
      type: ActivityType.postCreated,
      userId: userId,
      userName: userName,
      description: 'created a community post',
      metadata: {'actor_uid': userId},
    );
  }

  /// Helper method: Log user registration
  Future<void> logUserRegistered({
    required String userId,
    required String userName,
  }) async {
    await logActivity(
      type: ActivityType.userRegistered,
      userId: userId,
      userName: userName,
      description: 'joined Sanad',
      metadata: {'actor_uid': userId},
    );
  }

  /// Helper method: Log therapist approval
  Future<void> logTherapistApproved({
    required String adminId,
    required String adminName,
    required String therapistName,
  }) async {
    await logActivity(
      type: ActivityType.therapistApproved,
      userId: adminId,
      userName: adminName,
      description: 'approved therapist $therapistName',
      metadata: {'therapist_name': therapistName, 'actor_uid': adminId},
    );
  }

  /// Helper method: Log payment verification
  Future<void> logPaymentVerified({
    required String adminId,
    required String adminName,
    required String userName,
    required double amount,
  }) async {
    await logActivity(
      type: ActivityType.paymentVerified,
      userId: adminId,
      userName: adminName,
      description:
          'verified payment of SAR ${amount.toStringAsFixed(0)} for $userName',
      metadata: {'user_name': userName, 'amount': amount, 'actor_uid': adminId},
    );
  }
}

/// Provider for ActivityLogService
final activityLogServiceProvider = Provider<ActivityLogService>((ref) {
  return ActivityLogService();
});
