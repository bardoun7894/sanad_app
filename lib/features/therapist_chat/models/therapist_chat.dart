import 'package:cloud_firestore/cloud_firestore.dart';

/// Therapist-User chat thread model
class TherapistChatThread {
  final String chatId; // Format: {therapistId}_{userId}
  final String therapistId;
  final String userId;
  final String therapistName;
  final String? therapistPhotoUrl;
  final String userName;
  final String? userPhotoUrl;
  final String? bookingId; // Primary linked booking
  final List<String> bookingIds; // All linked bookings
  final ChatThreadStatus status;
  final ChatSource source;
  final String? aiContext; // Transferred context from AI chat
  final String? handoffId; // Linked handoff document ID
  final Map<String, dynamic>? moodContext; // Mood snapshot from handoff
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCountTherapist;
  final int unreadCountUser;
  final TypingStatus typing;

  const TherapistChatThread({
    required this.chatId,
    required this.therapistId,
    required this.userId,
    required this.therapistName,
    this.therapistPhotoUrl,
    required this.userName,
    this.userPhotoUrl,
    this.bookingId,
    this.bookingIds = const [],
    this.status = ChatThreadStatus.active,
    this.source = ChatSource.booking,
    this.aiContext,
    this.handoffId,
    this.moodContext,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCountTherapist = 0,
    this.unreadCountUser = 0,
    this.typing = const TypingStatus(),
  });

  /// Generate chat ID from therapist and user IDs
  static String generateChatId(String therapistId, String userd) =>
      '${therapistId}_$userd';

  Map<String, dynamic> toFirestore() {
    return {
      'chat_id': chatId,
      'therapist_id': therapistId,
      'user_id': userId,
      'therapist_name': therapistName,
      if (therapistPhotoUrl != null) 'therapist_photo_url': therapistPhotoUrl,
      'user_name': userName,
      if (userPhotoUrl != null) 'user_photo_url': userPhotoUrl,
      if (bookingId != null) 'booking_id': bookingId,
      'booking_ids': bookingIds,
      'status': status.name,
      'source': source.name,
      if (aiContext != null) 'ai_context': aiContext,
      if (handoffId != null) 'handoff_id': handoffId,
      if (moodContext != null) 'mood_context': moodContext,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastMessageTime != null)
        'last_message_time': Timestamp.fromDate(lastMessageTime!),
      'unread_count_therapist': unreadCountTherapist,
      'unread_count_user': unreadCountUser,
      'typing': typing.toFirestore(),
    };
  }

  factory TherapistChatThread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TherapistChatThread(
      chatId: data['chat_id'] as String? ?? doc.id,
      therapistId: data['therapist_id'] as String,
      userId: data['user_id'] as String,
      therapistName: data['therapist_name'] as String? ?? 'Therapist',
      therapistPhotoUrl: data['therapist_photo_url'] as String?,
      userName: data['user_name'] as String? ?? 'User',
      userPhotoUrl: data['user_photo_url'] as String?,
      bookingId: data['booking_id'] as String?,
      bookingIds:
          (data['booking_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: ChatThreadStatusX.fromString(data['status'] as String?),
      source: ChatSourceX.fromString(data['source'] as String?),
      aiContext: data['ai_context'] as String?,
      handoffId: data['handoff_id'] as String?,
      moodContext: data['mood_context'] as Map<String, dynamic>?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['last_message'] as String?,
      lastMessageTime: data['last_message_time'] != null
          ? (data['last_message_time'] as Timestamp).toDate()
          : null,
      unreadCountTherapist: data['unread_count_therapist'] as int? ?? 0,
      unreadCountUser: data['unread_count_user'] as int? ?? 0,
      typing: data['typing'] != null
          ? TypingStatus.fromFirestore(data['typing'] as Map<String, dynamic>)
          : const TypingStatus(),
    );
  }

  TherapistChatThread copyWith({
    String? chatId,
    String? therapistId,
    String? userId,
    String? therapistName,
    String? therapistPhotoUrl,
    String? userName,
    String? userPhotoUrl,
    String? bookingId,
    List<String>? bookingIds,
    ChatThreadStatus? status,
    ChatSource? source,
    String? aiContext,
    String? handoffId,
    Map<String, dynamic>? moodContext,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCountTherapist,
    int? unreadCountUser,
    TypingStatus? typing,
  }) {
    return TherapistChatThread(
      chatId: chatId ?? this.chatId,
      therapistId: therapistId ?? this.therapistId,
      userId: userId ?? this.userId,
      therapistName: therapistName ?? this.therapistName,
      therapistPhotoUrl: therapistPhotoUrl ?? this.therapistPhotoUrl,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      bookingId: bookingId ?? this.bookingId,
      bookingIds: bookingIds ?? this.bookingIds,
      status: status ?? this.status,
      source: source ?? this.source,
      aiContext: aiContext ?? this.aiContext,
      handoffId: handoffId ?? this.handoffId,
      moodContext: moodContext ?? this.moodContext,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCountTherapist: unreadCountTherapist ?? this.unreadCountTherapist,
      unreadCountUser: unreadCountUser ?? this.unreadCountUser,
      typing: typing ?? this.typing,
    );
  }
}

/// Chat thread status
enum ChatThreadStatus { active, archived }

extension ChatThreadStatusX on ChatThreadStatus {
  static ChatThreadStatus fromString(String? value) {
    return ChatThreadStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChatThreadStatus.active,
    );
  }
}

/// Source of chat creation
enum ChatSource { booking, aiEscalation, direct }

extension ChatSourceX on ChatSource {
  static ChatSource fromString(String? value) {
    if (value == 'ai_escalation') return ChatSource.aiEscalation;
    return ChatSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ChatSource.booking,
    );
  }
}

/// Typing status for real-time indicators
class TypingStatus {
  final bool therapistTyping;
  final bool userTyping;
  final DateTime? therapistTimestamp;
  final DateTime? userTimestamp;

  const TypingStatus({
    this.therapistTyping = false,
    this.userTyping = false,
    this.therapistTimestamp,
    this.userTimestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'therapist': therapistTyping,
      'user': userTyping,
      if (therapistTimestamp != null)
        'therapist_timestamp': Timestamp.fromDate(therapistTimestamp!),
      if (userTimestamp != null)
        'user_timestamp': Timestamp.fromDate(userTimestamp!),
    };
  }

  factory TypingStatus.fromFirestore(Map<String, dynamic> data) {
    return TypingStatus(
      therapistTyping: data['therapist'] as bool? ?? false,
      userTyping: data['user'] as bool? ?? false,
      therapistTimestamp: data['therapist_timestamp'] != null
          ? (data['therapist_timestamp'] as Timestamp).toDate()
          : null,
      userTimestamp: data['user_timestamp'] != null
          ? (data['user_timestamp'] as Timestamp).toDate()
          : null,
    );
  }
}
