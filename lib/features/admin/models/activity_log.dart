import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  sessionCompleted,
  bookingCreated,
  moodLogged,
  postCreated,
  userRegistered,
  userUpdated,
  userSuspended,
  userDeleted,
  therapistApproved,
  therapistRejected,
  paymentVerified,
  subscriptionAssigned,
  subscriptionRevoked,
}

class ActivityLog {
  final String id;
  final ActivityType type;
  final String userId;
  final String userName;
  final String description;
  final DateTime timestamp;
  final String? actorUid;
  final Map<String, dynamic>? metadata;

  const ActivityLog({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    required this.description,
    required this.timestamp,
    this.actorUid,
    this.metadata,
  });

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLog(
      id: doc.id,
      type: _parseActivityType(data['type'] as String?),
      userId: data['user_id'] as String? ?? '',
      userName: data['user_name'] as String? ?? 'Unknown',
      description: data['description'] as String? ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
      actorUid: data['actor_uid'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Parse timestamp from Firestore which may be a Timestamp, String (ISO8601),
  /// int (milliseconds since epoch), or null.
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'user_id': userId,
      'user_name': userName,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      if (actorUid != null) 'actor_uid': actorUid,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static ActivityType _parseActivityType(String? typeString) {
    if (typeString == null) return ActivityType.sessionCompleted;

    switch (typeString) {
      case 'sessionCompleted':
        return ActivityType.sessionCompleted;
      case 'bookingCreated':
        return ActivityType.bookingCreated;
      case 'moodLogged':
        return ActivityType.moodLogged;
      case 'postCreated':
        return ActivityType.postCreated;
      case 'userRegistered':
        return ActivityType.userRegistered;
      case 'userUpdated':
        return ActivityType.userUpdated;
      case 'userSuspended':
        return ActivityType.userSuspended;
      case 'userDeleted':
        return ActivityType.userDeleted;
      case 'therapistApproved':
        return ActivityType.therapistApproved;
      case 'therapistRejected':
        return ActivityType.therapistRejected;
      case 'paymentVerified':
        return ActivityType.paymentVerified;
      case 'subscriptionAssigned':
        return ActivityType.subscriptionAssigned;
      case 'subscriptionRevoked':
        return ActivityType.subscriptionRevoked;
      default:
        return ActivityType.sessionCompleted;
    }
  }

  IconData get icon {
    switch (type) {
      case ActivityType.sessionCompleted:
        return Icons.check_circle;
      case ActivityType.bookingCreated:
        return Icons.calendar_today;
      case ActivityType.moodLogged:
        return Icons.mood;
      case ActivityType.postCreated:
        return Icons.forum;
      case ActivityType.userRegistered:
        return Icons.person_add;
      case ActivityType.userUpdated:
        return Icons.edit;
      case ActivityType.userSuspended:
        return Icons.block;
      case ActivityType.userDeleted:
        return Icons.delete;
      case ActivityType.therapistApproved:
        return Icons.verified;
      case ActivityType.therapistRejected:
        return Icons.cancel_outlined;
      case ActivityType.paymentVerified:
        return Icons.payment;
      case ActivityType.subscriptionAssigned:
        return Icons.card_membership;
      case ActivityType.subscriptionRevoked:
        return Icons.cancel;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${(difference.inDays / 7).floor()} ${(difference.inDays / 7).floor() == 1 ? 'week' : 'weeks'} ago';
    }
  }
}
