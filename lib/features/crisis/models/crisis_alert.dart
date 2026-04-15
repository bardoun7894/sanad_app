import 'package:cloud_firestore/cloud_firestore.dart';

enum CrisisAlertType { crisisKeyword, moodTrend, aiFlagged, communityPost }

enum CrisisAlertSource { aiChat, community, moodLog }

enum CrisisAlertSeverity { critical, high, moderate }

enum CrisisAlertStatus {
  newAlert,
  acknowledged,
  assigned,
  resolved,
  falsePositive,
}

class CrisisAlert {
  final String id;
  final String userId;
  final String userName;
  final CrisisAlertType alertType;
  final CrisisAlertSource source;
  final CrisisAlertSeverity severity;
  final CrisisAlertStatus status;
  final String triggeredText;
  final List<String> matchedKeywords;
  final bool aiConfirmed;
  final String language;
  final String? assignedTherapistId;
  final String? assignedTherapistName;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CrisisAlert({
    required this.id,
    required this.userId,
    required this.userName,
    required this.alertType,
    required this.source,
    required this.severity,
    this.status = CrisisAlertStatus.newAlert,
    required this.triggeredText,
    this.matchedKeywords = const [],
    this.aiConfirmed = false,
    required this.language,
    this.assignedTherapistId,
    this.assignedTherapistName,
    this.acknowledgedBy,
    this.acknowledgedAt,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  CrisisAlert copyWith({
    String? id,
    String? userId,
    String? userName,
    CrisisAlertType? alertType,
    CrisisAlertSource? source,
    CrisisAlertSeverity? severity,
    CrisisAlertStatus? status,
    String? triggeredText,
    List<String>? matchedKeywords,
    bool? aiConfirmed,
    String? language,
    String? assignedTherapistId,
    String? assignedTherapistName,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolutionNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CrisisAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      alertType: alertType ?? this.alertType,
      source: source ?? this.source,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      triggeredText: triggeredText ?? this.triggeredText,
      matchedKeywords: matchedKeywords ?? this.matchedKeywords,
      aiConfirmed: aiConfirmed ?? this.aiConfirmed,
      language: language ?? this.language,
      assignedTherapistId: assignedTherapistId ?? this.assignedTherapistId,
      assignedTherapistName:
          assignedTherapistName ?? this.assignedTherapistName,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'user_name': userName,
      'alert_type': alertType.name,
      'source': source.name,
      'severity': severity.name,
      'status': status.name,
      'triggered_text': triggeredText,
      'matched_keywords': matchedKeywords,
      'ai_confirmed': aiConfirmed,
      'language': language,
      if (assignedTherapistId != null)
        'assigned_therapist_id': assignedTherapistId,
      if (assignedTherapistName != null)
        'assigned_therapist_name': assignedTherapistName,
      if (acknowledgedBy != null) 'acknowledged_by': acknowledgedBy,
      if (acknowledgedAt != null)
        'acknowledged_at': Timestamp.fromDate(acknowledgedAt!),
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      if (resolvedAt != null) 'resolved_at': Timestamp.fromDate(resolvedAt!),
      if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory CrisisAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CrisisAlert(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      userName: data['user_name'] as String? ?? '',
      alertType: CrisisAlertType.values.firstWhere(
        (e) => e.name == data['alert_type'],
        orElse: () => CrisisAlertType.crisisKeyword,
      ),
      source: CrisisAlertSource.values.firstWhere(
        (e) => e.name == data['source'],
        orElse: () => CrisisAlertSource.aiChat,
      ),
      severity: CrisisAlertSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => CrisisAlertSeverity.moderate,
      ),
      status: CrisisAlertStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CrisisAlertStatus.newAlert,
      ),
      triggeredText: data['triggered_text'] as String? ?? '',
      matchedKeywords:
          (data['matched_keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      aiConfirmed: data['ai_confirmed'] as bool? ?? false,
      language: data['language'] as String? ?? 'ar',
      assignedTherapistId: data['assigned_therapist_id'] as String?,
      assignedTherapistName: data['assigned_therapist_name'] as String?,
      acknowledgedBy: data['acknowledged_by'] as String?,
      acknowledgedAt: (data['acknowledged_at'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolved_by'] as String?,
      resolvedAt: (data['resolved_at'] as Timestamp?)?.toDate(),
      resolutionNotes: data['resolution_notes'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isActive =>
      status == CrisisAlertStatus.newAlert ||
      status == CrisisAlertStatus.acknowledged ||
      status == CrisisAlertStatus.assigned;
}
