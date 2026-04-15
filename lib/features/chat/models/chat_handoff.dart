import 'package:cloud_firestore/cloud_firestore.dart';

enum HandoffTrigger { crisis, userRequest, moodPattern, aiLowConfidence }

enum HandoffStatus {
  pending,
  accepted,
  inProgress,
  completed,
  expired,
  cancelled,
}

class MoodSnapshot {
  final List<String> dates;
  final List<String> moods;
  final double averageScore;
  final String trend; // 'improving', 'declining', 'stable'
  final int consecutiveLowDays;

  const MoodSnapshot({
    this.dates = const [],
    this.moods = const [],
    this.averageScore = 0.0,
    this.trend = 'stable',
    this.consecutiveLowDays = 0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'dates': dates,
      'moods': moods,
      'average_score': averageScore,
      'trend': trend,
      'consecutive_low_days': consecutiveLowDays,
    };
  }

  factory MoodSnapshot.fromFirestore(Map<String, dynamic> data) {
    return MoodSnapshot(
      dates:
          (data['dates'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      moods:
          (data['moods'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      averageScore: (data['average_score'] as num?)?.toDouble() ?? 0.0,
      trend: data['trend'] as String? ?? 'stable',
      consecutiveLowDays: data['consecutive_low_days'] as int? ?? 0,
    );
  }
}

class ChatHandoff {
  final String id;
  final String userId;
  final String userName;
  final String fromMode; // 'ai' or 'therapist'
  final String toMode; // 'therapist' or 'ai'
  final String? therapistId;
  final String? therapistName;
  final HandoffTrigger triggerReason;
  final String? triggerDetails;
  final String aiSummary;
  final MoodSnapshot moodSnapshot;
  final String? chatHistoryRef;
  final String? riskLevel;
  final String? therapistChatId;
  final String? riskAlertId;
  final HandoffStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;

  const ChatHandoff({
    required this.id,
    required this.userId,
    required this.userName,
    required this.fromMode,
    required this.toMode,
    this.therapistId,
    this.therapistName,
    required this.triggerReason,
    this.triggerDetails,
    required this.aiSummary,
    this.moodSnapshot = const MoodSnapshot(),
    this.chatHistoryRef,
    this.riskLevel,
    this.therapistChatId,
    this.riskAlertId,
    this.status = HandoffStatus.pending,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.expiresAt,
  });

  ChatHandoff copyWith({
    String? id,
    String? userId,
    String? userName,
    String? fromMode,
    String? toMode,
    String? therapistId,
    String? therapistName,
    HandoffTrigger? triggerReason,
    String? triggerDetails,
    String? aiSummary,
    MoodSnapshot? moodSnapshot,
    String? chatHistoryRef,
    String? riskLevel,
    String? therapistChatId,
    String? riskAlertId,
    HandoffStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  }) {
    return ChatHandoff(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      fromMode: fromMode ?? this.fromMode,
      toMode: toMode ?? this.toMode,
      therapistId: therapistId ?? this.therapistId,
      therapistName: therapistName ?? this.therapistName,
      triggerReason: triggerReason ?? this.triggerReason,
      triggerDetails: triggerDetails ?? this.triggerDetails,
      aiSummary: aiSummary ?? this.aiSummary,
      moodSnapshot: moodSnapshot ?? this.moodSnapshot,
      chatHistoryRef: chatHistoryRef ?? this.chatHistoryRef,
      riskLevel: riskLevel ?? this.riskLevel,
      therapistChatId: therapistChatId ?? this.therapistChatId,
      riskAlertId: riskAlertId ?? this.riskAlertId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'user_name': userName,
      'from_mode': fromMode,
      'to_mode': toMode,
      if (therapistId != null) 'therapist_id': therapistId,
      if (therapistName != null) 'therapist_name': therapistName,
      'trigger_reason': triggerReason.name,
      if (triggerDetails != null) 'trigger_details': triggerDetails,
      'ai_summary': aiSummary,
      'mood_snapshot': moodSnapshot.toFirestore(),
      if (chatHistoryRef != null) 'chat_history_ref': chatHistoryRef,
      if (riskLevel != null) 'risk_level': riskLevel,
      if (therapistChatId != null) 'therapist_chat_id': therapistChatId,
      if (riskAlertId != null) 'risk_alert_id': riskAlertId,
      'status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
      if (acceptedAt != null) 'accepted_at': Timestamp.fromDate(acceptedAt!),
      if (completedAt != null) 'completed_at': Timestamp.fromDate(completedAt!),
      if (expiresAt != null) 'expires_at': Timestamp.fromDate(expiresAt!),
    };
  }

  factory ChatHandoff.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatHandoff(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      userName: data['user_name'] as String? ?? '',
      fromMode: data['from_mode'] as String? ?? 'ai',
      toMode: data['to_mode'] as String? ?? 'therapist',
      therapistId: data['therapist_id'] as String?,
      therapistName: data['therapist_name'] as String?,
      triggerReason: HandoffTrigger.values.firstWhere(
        (e) => e.name == data['trigger_reason'],
        orElse: () => HandoffTrigger.userRequest,
      ),
      triggerDetails: data['trigger_details'] as String?,
      aiSummary: data['ai_summary'] as String? ?? '',
      moodSnapshot: data['mood_snapshot'] != null
          ? MoodSnapshot.fromFirestore(
              data['mood_snapshot'] as Map<String, dynamic>,
            )
          : const MoodSnapshot(),
      chatHistoryRef: data['chat_history_ref'] as String?,
      riskLevel: data['risk_level'] as String?,
      therapistChatId: data['therapist_chat_id'] as String?,
      riskAlertId: data['risk_alert_id'] as String?,
      status: HandoffStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => HandoffStatus.pending,
      ),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['accepted_at'] as Timestamp?)?.toDate(),
      completedAt: (data['completed_at'] as Timestamp?)?.toDate(),
      expiresAt: (data['expires_at'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPending => status == HandoffStatus.pending;
  bool get isActive =>
      status == HandoffStatus.pending ||
      status == HandoffStatus.accepted ||
      status == HandoffStatus.inProgress;
}
