import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sanad_app/features/crisis/models/crisis_alert.dart';

void main() {
  group('CrisisAlert', () {
    final now = DateTime(2026, 2, 28, 12, 0);

    test('creates with required fields', () {
      final alert = CrisisAlert(
        id: 'test-id',
        userId: 'user-1',
        userName: 'Test User',
        alertType: CrisisAlertType.crisisKeyword,
        source: CrisisAlertSource.aiChat,
        severity: CrisisAlertSeverity.critical,
        triggeredText: 'I want to kill myself',
        matchedKeywords: ['kill myself'],
        language: 'en',
        createdAt: now,
        updatedAt: now,
      );

      expect(alert.id, 'test-id');
      expect(alert.userId, 'user-1');
      expect(alert.severity, CrisisAlertSeverity.critical);
      expect(alert.status, CrisisAlertStatus.newAlert);
      expect(alert.aiConfirmed, isFalse);
      expect(alert.isActive, isTrue);
    });

    test('toFirestore serializes correctly', () {
      final alert = CrisisAlert(
        id: 'test-id',
        userId: 'user-1',
        userName: 'Test User',
        alertType: CrisisAlertType.crisisKeyword,
        source: CrisisAlertSource.aiChat,
        severity: CrisisAlertSeverity.critical,
        triggeredText: 'test text',
        matchedKeywords: ['keyword1', 'keyword2'],
        language: 'ar',
        createdAt: now,
        updatedAt: now,
      );

      final map = alert.toFirestore();

      expect(map['user_id'], 'user-1');
      expect(map['user_name'], 'Test User');
      expect(map['alert_type'], 'crisisKeyword');
      expect(map['source'], 'aiChat');
      expect(map['severity'], 'critical');
      expect(map['status'], 'newAlert');
      expect(map['triggered_text'], 'test text');
      expect(map['matched_keywords'], ['keyword1', 'keyword2']);
      expect(map['ai_confirmed'], false);
      expect(map['language'], 'ar');
      expect(map['created_at'], isA<Timestamp>());
      expect(map['updated_at'], isA<Timestamp>());
      // Optional fields should not be present
      expect(map.containsKey('assigned_therapist_id'), isFalse);
      expect(map.containsKey('acknowledged_by'), isFalse);
    });

    test('toFirestore includes optional fields when set', () {
      final alert = CrisisAlert(
        id: 'test-id',
        userId: 'user-1',
        userName: 'Test User',
        alertType: CrisisAlertType.aiFlagged,
        source: CrisisAlertSource.community,
        severity: CrisisAlertSeverity.high,
        status: CrisisAlertStatus.assigned,
        triggeredText: 'test',
        language: 'en',
        aiConfirmed: true,
        assignedTherapistId: 'therapist-1',
        assignedTherapistName: 'Dr. Smith',
        acknowledgedBy: 'admin-1',
        acknowledgedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      final map = alert.toFirestore();

      expect(map['alert_type'], 'aiFlagged');
      expect(map['source'], 'community');
      expect(map['severity'], 'high');
      expect(map['status'], 'assigned');
      expect(map['ai_confirmed'], true);
      expect(map['assigned_therapist_id'], 'therapist-1');
      expect(map['assigned_therapist_name'], 'Dr. Smith');
      expect(map['acknowledged_by'], 'admin-1');
      expect(map['acknowledged_at'], isA<Timestamp>());
    });

    test('copyWith creates updated copy', () {
      final alert = CrisisAlert(
        id: 'test-id',
        userId: 'user-1',
        userName: 'Test User',
        alertType: CrisisAlertType.crisisKeyword,
        source: CrisisAlertSource.aiChat,
        severity: CrisisAlertSeverity.critical,
        triggeredText: 'test',
        language: 'en',
        createdAt: now,
        updatedAt: now,
      );

      final updated = alert.copyWith(
        status: CrisisAlertStatus.acknowledged,
        acknowledgedBy: 'admin-1',
        acknowledgedAt: now,
      );

      expect(updated.status, CrisisAlertStatus.acknowledged);
      expect(updated.acknowledgedBy, 'admin-1');
      // Original unchanged
      expect(alert.status, CrisisAlertStatus.newAlert);
      // Preserved fields
      expect(updated.userId, 'user-1');
      expect(updated.severity, CrisisAlertSeverity.critical);
    });

    test('isActive returns correct state', () {
      final makeAlert = (CrisisAlertStatus status) => CrisisAlert(
        id: 'id',
        userId: 'u',
        userName: 'n',
        alertType: CrisisAlertType.crisisKeyword,
        source: CrisisAlertSource.aiChat,
        severity: CrisisAlertSeverity.critical,
        status: status,
        triggeredText: 't',
        language: 'en',
        createdAt: now,
        updatedAt: now,
      );

      expect(makeAlert(CrisisAlertStatus.newAlert).isActive, isTrue);
      expect(makeAlert(CrisisAlertStatus.acknowledged).isActive, isTrue);
      expect(makeAlert(CrisisAlertStatus.assigned).isActive, isTrue);
      expect(makeAlert(CrisisAlertStatus.resolved).isActive, isFalse);
      expect(makeAlert(CrisisAlertStatus.falsePositive).isActive, isFalse);
    });
  });

  group('CrisisAlertSeverity', () {
    test('has expected values', () {
      expect(CrisisAlertSeverity.values.length, 3);
      expect(CrisisAlertSeverity.critical.name, 'critical');
      expect(CrisisAlertSeverity.high.name, 'high');
      expect(CrisisAlertSeverity.moderate.name, 'moderate');
    });
  });

  group('CrisisAlertType', () {
    test('has expected values', () {
      expect(CrisisAlertType.values.length, 4);
      expect(CrisisAlertType.crisisKeyword.name, 'crisisKeyword');
      expect(CrisisAlertType.moodTrend.name, 'moodTrend');
      expect(CrisisAlertType.aiFlagged.name, 'aiFlagged');
      expect(CrisisAlertType.communityPost.name, 'communityPost');
    });
  });
}
