import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  booking,
  message,
  community,
  mood,
  system,
  therapist,
  payment,
  call,
  crisis,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionRoute;
  /// When true, the `onNotificationCreated` Cloud Function dispatches an
  /// FCM push to every device registered for [userId]. Default false so
  /// older write paths (which already push via their own triggers) don't
  /// double-send.
  final bool pushFcm;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
    this.actionRoute,
    this.pushFcm = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['is_read'] ?? false,
      data: data['data'] as Map<String, dynamic>?,
      actionRoute: data['action_route'],
      pushFcm: data['push_fcm'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'created_at': Timestamp.fromDate(createdAt),
      'is_read': isRead,
      'data': data,
      'action_route': actionRoute,
      if (pushFcm) 'push_fcm': true,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
    String? actionRoute,
    bool? pushFcm,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      actionRoute: actionRoute ?? this.actionRoute,
      pushFcm: pushFcm ?? this.pushFcm,
    );
  }

  String get resolvedRoute {
    if (actionRoute != null && actionRoute!.isNotEmpty) {
      return actionRoute!;
    }
    switch (type) {
      case NotificationType.booking:
        return '/bookings';
      case NotificationType.message:
        final chatId = data?['chat_id'] ?? data?['chatId'];
        return chatId != null ? '/chat/therapist/$chatId' : '/chat';
      case NotificationType.community:
        return '/community';
      case NotificationType.mood:
        return '/mood-tracker';
      case NotificationType.therapist:
        return '/therapists';
      case NotificationType.payment:
        return '/subscription';
      case NotificationType.call:
        final chatId = data?['chat_id'] ?? data?['chatId'];
        return chatId != null ? '/chat/therapist/$chatId' : '/call-history';
      case NotificationType.crisis:
        return '/admin/crisis-alerts';
      case NotificationType.system:
        return '/notifications';
    }
  }

  String get typeIcon {
    switch (type) {
      case NotificationType.booking:
        return '📅';
      case NotificationType.message:
        return '💬';
      case NotificationType.community:
        return '👥';
      case NotificationType.mood:
        return '😊';
      case NotificationType.therapist:
        return '👨‍⚕️';
      case NotificationType.payment:
        return '💳';
      case NotificationType.system:
        return '🔔';
      case NotificationType.call:
        return '📞';
      case NotificationType.crisis:
        return '🚨';
    }
  }
}
