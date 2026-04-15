import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/crisis_alert.dart';
import '../models/crisis_keywords.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/app_config.dart';

class CrisisDetectionService {
  final FirebaseFirestore _firestore;

  CrisisDetectionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _alertsCollection = 'risk_alerts';

  /// Analyze a chat message for crisis content using the two-tier system.
  ///
  /// **Tier 1 (Critical)**: Explicit self-harm keywords. Bypasses AI confirmation.
  /// Returns immediately with severity `critical`.
  ///
  /// **Tier 2 (High)**: Ambiguous distress indicators. Returns with severity `high`.
  /// Caller should trigger background AI confirmation via [confirmWithAi].
  CrisisDetectionResult analyzeChatMessage(String message) {
    return CrisisKeywords.analyze(message);
  }

  /// Background AI confirmation for Tier 2 (high severity) alerts.
  /// Sends the message to Gemini with a crisis assessment prompt.
  /// Returns true if AI confirms crisis context.
  Future<bool> confirmWithAi(String message, String language) async {
    try {
      final key = AppConfig.geminiApiKey;
      if (key.isEmpty) return false;

      final gemini = GeminiService(apiKey: key);
      final prompt = buildCrisisAssessmentPrompt(message, language);

      final response = await gemini.sendMessage(
        messages: [GeminiChatMessage(role: 'user', content: prompt)],
        systemPrompt: _crisisAssessmentSystemPrompt,
        language: 'en',
      );

      final responseText = response.content.toLowerCase().trim();
      return responseText.contains('crisis_confirmed') ||
          responseText.contains('"is_crisis": true') ||
          responseText.contains('"is_crisis":true');
    } catch (e) {
      debugPrint('Crisis AI confirmation failed: $e');
      return false;
    }
  }

  static const String _crisisAssessmentSystemPrompt = '''
You are a crisis assessment AI. Analyze the message for genuine crisis indicators.
Respond ONLY with a JSON object:
{"is_crisis": true/false, "confidence": 0.0-1.0, "reason": "brief explanation"}

Consider context: some phrases may be metaphorical or expressions of frustration
rather than genuine crisis. Err on the side of caution (flag if uncertain).
''';

  static String buildCrisisAssessmentPrompt(String message, String language) {
    return '''
Assess this message for mental health crisis indicators.
Language: $language
Message: "$message"

Respond with JSON only: {"is_crisis": true/false, "confidence": 0.0-1.0, "reason": "..."}
''';
  }

  /// Report a crisis alert to Firestore.
  Future<String> reportCrisis({
    required String userId,
    required String userName,
    required CrisisAlertType alertType,
    required CrisisAlertSource source,
    required CrisisAlertSeverity severity,
    required String triggeredText,
    required List<String> matchedKeywords,
    required String language,
    bool aiConfirmed = false,
  }) async {
    try {
      final now = DateTime.now();
      final alert = CrisisAlert(
        id: '',
        userId: userId,
        userName: userName,
        alertType: alertType,
        source: source,
        severity: severity,
        triggeredText: triggeredText,
        matchedKeywords: matchedKeywords,
        language: language,
        aiConfirmed: aiConfirmed,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection(_alertsCollection)
          .add(alert.toFirestore());

      debugPrint(
        'Crisis alert created: ${docRef.id} (severity: ${severity.name})',
      );
      return docRef.id;
    } catch (e) {
      debugPrint('Error reporting crisis: $e');
      rethrow;
    }
  }

  /// Set crisis mode on a user's profile.
  Future<void> setCrisisMode({
    required String userId,
    required bool enabled,
    required String setBy,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'crisis_mode': enabled,
        'crisis_mode_set_at': FieldValue.serverTimestamp(),
        'crisis_mode_set_by': setBy,
        'updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint(
        'Crisis mode ${enabled ? 'enabled' : 'disabled'} for user $userId',
      );
    } catch (e) {
      debugPrint('Error setting crisis mode: $e');
      rethrow;
    }
  }

  /// Acknowledge a crisis alert (admin action).
  Future<void> acknowledgeAlert({
    required String alertId,
    required String acknowledgedBy,
  }) async {
    await _firestore.collection(_alertsCollection).doc(alertId).update({
      'status': CrisisAlertStatus.acknowledged.name,
      'acknowledged_by': acknowledgedBy,
      'acknowledged_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Assign a crisis alert to a therapist.
  Future<void> assignAlert({
    required String alertId,
    required String therapistId,
    required String therapistName,
  }) async {
    await _firestore.collection(_alertsCollection).doc(alertId).update({
      'status': CrisisAlertStatus.assigned.name,
      'assigned_therapist_id': therapistId,
      'assigned_therapist_name': therapistName,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Resolve a crisis alert.
  Future<void> resolveAlert({
    required String alertId,
    required String resolvedBy,
    String? notes,
  }) async {
    await _firestore.collection(_alertsCollection).doc(alertId).update({
      'status': CrisisAlertStatus.resolved.name,
      'resolved_by': resolvedBy,
      'resolved_at': FieldValue.serverTimestamp(),
      if (notes != null) 'resolution_notes': notes,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Mark a crisis alert as false positive.
  Future<void> markFalsePositive({
    required String alertId,
    required String markedBy,
    String? notes,
  }) async {
    await _firestore.collection(_alertsCollection).doc(alertId).update({
      'status': CrisisAlertStatus.falsePositive.name,
      'resolved_by': markedBy,
      'resolved_at': FieldValue.serverTimestamp(),
      if (notes != null) 'resolution_notes': notes,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Stream active crisis alerts (for admin dashboard).
  Stream<List<CrisisAlert>> streamActiveAlerts() {
    return _firestore
        .collection(_alertsCollection)
        .where('status', whereIn: ['newAlert', 'acknowledged', 'assigned'])
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CrisisAlert.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream all crisis alerts.
  Stream<List<CrisisAlert>> streamAllAlerts({int limit = 50}) {
    return _firestore
        .collection(_alertsCollection)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CrisisAlert.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get alerts for a specific user.
  Future<List<CrisisAlert>> getAlertsForUser(String userId) async {
    final snapshot = await _firestore
        .collection(_alertsCollection)
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs.map((doc) => CrisisAlert.fromFirestore(doc)).toList();
  }

  /// Check if user has active crisis mode.
  Future<bool> isUserInCrisisMode(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['crisis_mode'] as bool? ?? false;
  }
}
