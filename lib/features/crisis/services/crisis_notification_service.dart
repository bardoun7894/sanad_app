import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/crisis_alert.dart';

/// Handles crisis-related notifications using existing FCM infrastructure.
/// Writes notification documents to Firestore for admin/therapist delivery.
class CrisisNotificationService {
  final FirebaseFirestore _firestore;

  CrisisNotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Notify all admins about a new crisis alert.
  /// Creates notification documents in the /notifications collection
  /// for each admin user.
  Future<void> notifyAdmins({required CrisisAlert alert}) async {
    try {
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final adminDoc in adminsSnapshot.docs) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'user_id': adminDoc.id,
          'title': _getAlertTitle(alert),
          'body': _getAlertBody(alert),
          'type': 'crisis',
          'created_at': Timestamp.fromDate(now),
          'is_read': false,
          'data': {
            'alert_id': alert.id,
            'user_id': alert.userId,
            'severity': alert.severity.name,
            'alert_type': alert.alertType.name,
          },
          'action_route': '/admin/crisis-alerts',
        });
      }

      await batch.commit();
      debugPrint(
        'Crisis notifications sent to ${adminsSnapshot.docs.length} admins',
      );
    } catch (e) {
      debugPrint('Error notifying admins of crisis: $e');
    }
  }

  /// Notify an assigned therapist about a crisis alert.
  Future<void> notifyAssignedTherapist({
    required CrisisAlert alert,
    required String therapistId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'user_id': therapistId,
        'title': _getTherapistAlertTitle(alert),
        'body': _getTherapistAlertBody(alert),
        'type': 'crisis',
        'created_at': Timestamp.fromDate(DateTime.now()),
        'is_read': false,
        'data': {
          'alert_id': alert.id,
          'user_id': alert.userId,
          'severity': alert.severity.name,
        },
        'action_route': '/admin/crisis-alerts',
      });
      debugPrint('Crisis notification sent to therapist $therapistId');
    } catch (e) {
      debugPrint('Error notifying therapist of crisis: $e');
    }
  }

  String _getAlertTitle(CrisisAlert alert) {
    switch (alert.severity) {
      case CrisisAlertSeverity.critical:
        return 'CRITICAL: Crisis Alert';
      case CrisisAlertSeverity.high:
        return 'HIGH: Crisis Alert';
      case CrisisAlertSeverity.moderate:
        return 'Crisis Alert';
    }
  }

  String _getAlertBody(CrisisAlert alert) {
    final source = switch (alert.source) {
      CrisisAlertSource.aiChat => 'AI Chat',
      CrisisAlertSource.community => 'Community',
      CrisisAlertSource.moodLog => 'Mood Log',
    };
    return 'User ${alert.userName} triggered a ${alert.severity.name} alert via $source. Immediate review required.';
  }

  String _getTherapistAlertTitle(CrisisAlert alert) {
    return 'Crisis Alert Assigned to You';
  }

  String _getTherapistAlertBody(CrisisAlert alert) {
    return 'You have been assigned a ${alert.severity.name} crisis alert for ${alert.userName}. Please review immediately.';
  }
}
