import 'package:cloud_firestore/cloud_firestore.dart';

/// Message in a therapist-user chat
class TherapistMessage {
  final String id;
  final String senderId;
  final String? senderName;
  final SenderType senderType;
  final String content;
  final TherapistMessageType messageType;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;
  final MessageDeliveryStatus status;
  final List<MessageAttachment>? attachments;
  final MessageMetadata? metadata;

  const TherapistMessage({
    required this.id,
    required this.senderId,
    this.senderName,
    required this.senderType,
    required this.content,
    this.messageType = TherapistMessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
    this.status = MessageDeliveryStatus.sent,
    this.attachments,
    this.metadata,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'sender_id': senderId,
      if (senderName != null) 'sender_name': senderName,
      'sender_type': senderType.name,
      'content': content,
      'message_type': messageType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'is_read': isRead,
      if (readAt != null) 'read_at': Timestamp.fromDate(readAt!),
      'status': status.name,
      if (attachments != null)
        'attachments': attachments!.map((a) => a.toFirestore()).toList(),
      if (metadata != null) 'metadata': metadata!.toFirestore(),
    };
  }

  factory TherapistMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TherapistMessage(
      id: data['id'] as String? ?? doc.id,
      senderId: data['sender_id'] as String,
      senderName: data['sender_name'] as String?,
      senderType: SenderTypeX.fromString(data['sender_type'] as String?),
      content: data['content'] as String,
      messageType: TherapistMessageTypeX.fromString(
        data['message_type'] as String?,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['is_read'] as bool? ?? false,
      readAt: data['read_at'] != null
          ? (data['read_at'] as Timestamp).toDate()
          : null,
      status: MessageDeliveryStatusX.fromString(data['status'] as String?),
      attachments: (data['attachments'] as List<dynamic>?)
          ?.map(
            (a) => MessageAttachment.fromFirestore(a as Map<String, dynamic>),
          )
          .toList(),
      metadata: data['metadata'] != null
          ? MessageMetadata.fromFirestore(
              data['metadata'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  TherapistMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    SenderType? senderType,
    String? content,
    TherapistMessageType? messageType,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    MessageDeliveryStatus? status,
    List<MessageAttachment>? attachments,
    MessageMetadata? metadata,
  }) {
    return TherapistMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if message is from therapist
  bool get isFromTherapist => senderType == SenderType.therapist;

  /// Check if message is from user
  bool get isFromUser => senderType == SenderType.user;
}

/// Who sent the message
enum SenderType { therapist, user, system }

extension SenderTypeX on SenderType {
  static SenderType fromString(String? value) {
    return SenderType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SenderType.user,
    );
  }
}

/// Type of message content
enum TherapistMessageType { text, sessionLink, file, image, system }

extension TherapistMessageTypeX on TherapistMessageType {
  static TherapistMessageType fromString(String? value) {
    if (value == 'session_link') return TherapistMessageType.sessionLink;
    return TherapistMessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TherapistMessageType.text,
    );
  }
}

/// Message delivery status
enum MessageDeliveryStatus { sending, sent, delivered, read, failed }

extension MessageDeliveryStatusX on MessageDeliveryStatus {
  static MessageDeliveryStatus fromString(String? value) {
    return MessageDeliveryStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageDeliveryStatus.sent,
    );
  }
}

/// Attachment for messages (files, images)
class MessageAttachment {
  final String type; // 'image', 'file'
  final String url;
  final String name;
  final int? size;
  final String? mimeType;

  const MessageAttachment({
    required this.type,
    required this.url,
    required this.name,
    this.size,
    this.mimeType,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'url': url,
      'name': name,
      if (size != null) 'size': size,
      if (mimeType != null) 'mime_type': mimeType,
    };
  }

  factory MessageAttachment.fromFirestore(Map<String, dynamic> data) {
    return MessageAttachment(
      type: data['type'] as String,
      url: data['url'] as String,
      name: data['name'] as String,
      size: data['size'] as int?,
      mimeType: data['mime_type'] as String?,
    );
  }
}

/// Additional metadata for messages
class MessageMetadata {
  final String? bookingReference;
  final String? sessionLink;
  final bool? isUrgent;

  const MessageMetadata({
    this.bookingReference,
    this.sessionLink,
    this.isUrgent,
  });

  Map<String, dynamic> toFirestore() {
    return {
      if (bookingReference != null) 'booking_reference': bookingReference,
      if (sessionLink != null) 'session_link': sessionLink,
      if (isUrgent != null) 'is_urgent': isUrgent,
    };
  }

  factory MessageMetadata.fromFirestore(Map<String, dynamic> data) {
    return MessageMetadata(
      bookingReference: data['booking_reference'] as String?,
      sessionLink: data['session_link'] as String?,
      isUrgent: data['is_urgent'] as bool?,
    );
  }
}
