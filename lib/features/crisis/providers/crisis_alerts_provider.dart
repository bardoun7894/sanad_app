import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crisis_alert.dart';
import '../services/crisis_detection_service.dart';
import '../services/crisis_notification_service.dart';
import 'crisis_detection_provider.dart';

/// Stream provider for active crisis alerts (admin dashboard).
final activeCrisisAlertsProvider = StreamProvider<List<CrisisAlert>>((ref) {
  final service = ref.watch(crisisDetectionServiceProvider);
  return service.streamActiveAlerts();
});

/// Stream provider for all crisis alerts (admin management screen).
final allCrisisAlertsProvider = StreamProvider<List<CrisisAlert>>((ref) {
  final service = ref.watch(crisisDetectionServiceProvider);
  return service.streamAllAlerts();
});

/// Provider for crisis alert actions (acknowledge, assign, resolve, false positive).
final crisisAlertActionsProvider = Provider<CrisisAlertActions>((ref) {
  final detectionService = ref.watch(crisisDetectionServiceProvider);
  final notificationService = CrisisNotificationService();
  return CrisisAlertActions(
    detectionService: detectionService,
    notificationService: notificationService,
  );
});

class CrisisAlertActions {
  final CrisisDetectionService detectionService;
  final CrisisNotificationService notificationService;

  CrisisAlertActions({
    required this.detectionService,
    required this.notificationService,
  });

  Future<void> acknowledge({
    required String alertId,
    required String acknowledgedBy,
  }) async {
    await detectionService.acknowledgeAlert(
      alertId: alertId,
      acknowledgedBy: acknowledgedBy,
    );
  }

  Future<void> assign({
    required CrisisAlert alert,
    required String therapistId,
    required String therapistName,
  }) async {
    await detectionService.assignAlert(
      alertId: alert.id,
      therapistId: therapistId,
      therapistName: therapistName,
    );
    await notificationService.notifyAssignedTherapist(
      alert: alert.copyWith(
        assignedTherapistId: therapistId,
        assignedTherapistName: therapistName,
      ),
      therapistId: therapistId,
    );
  }

  Future<void> resolve({
    required String alertId,
    required String resolvedBy,
    String? notes,
  }) async {
    await detectionService.resolveAlert(
      alertId: alertId,
      resolvedBy: resolvedBy,
      notes: notes,
    );
  }

  Future<void> markFalsePositive({
    required String alertId,
    required String markedBy,
    String? notes,
  }) async {
    await detectionService.markFalsePositive(
      alertId: alertId,
      markedBy: markedBy,
      notes: notes,
    );
  }
}
