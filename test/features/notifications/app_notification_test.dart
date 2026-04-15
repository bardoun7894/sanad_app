import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/notifications/models/app_notification.dart';

void main() {
  final now = DateTime(2026, 2, 15, 10, 30);

  group('AppNotification', () {
    test('creates with required fields', () {
      final notification = AppNotification(
        id: 'notif-1',
        userId: 'user-1',
        title: 'Test Title',
        body: 'Test Body',
        type: NotificationType.booking,
        createdAt: now,
      );

      expect(notification.id, 'notif-1');
      expect(notification.userId, 'user-1');
      expect(notification.title, 'Test Title');
      expect(notification.body, 'Test Body');
      expect(notification.type, NotificationType.booking);
      expect(notification.isRead, isFalse);
      expect(notification.data, isNull);
      expect(notification.actionRoute, isNull);
    });

    test('copyWith creates updated copy', () {
      final notification = AppNotification(
        id: 'notif-1',
        userId: 'user-1',
        title: 'Test',
        body: 'Body',
        type: NotificationType.message,
        createdAt: now,
      );

      final updated = notification.copyWith(isRead: true);

      expect(updated.isRead, isTrue);
      expect(updated.id, 'notif-1');
      expect(notification.isRead, isFalse);
    });

    test('resolvedRoute returns actionRoute when set', () {
      final notification = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'T',
        body: 'B',
        type: NotificationType.booking,
        createdAt: now,
        actionRoute: '/custom/route',
      );

      expect(notification.resolvedRoute, '/custom/route');
    });

    test('resolvedRoute returns default for booking', () {
      final notification = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'T',
        body: 'B',
        type: NotificationType.booking,
        createdAt: now,
      );

      expect(notification.resolvedRoute, '/bookings');
    });

    test('resolvedRoute returns default for message', () {
      final notification = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'T',
        body: 'B',
        type: NotificationType.message,
        createdAt: now,
      );

      expect(notification.resolvedRoute, '/chat');
    });

    test('resolvedRoute returns chat route with chatId', () {
      final notification = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'T',
        body: 'B',
        type: NotificationType.message,
        createdAt: now,
        data: {'chat_id': 'chat-123'},
      );

      expect(notification.resolvedRoute, '/chat/therapist/chat-123');
    });

    test('resolvedRoute returns default for community', () {
      final notification = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'T',
        body: 'B',
        type: NotificationType.community,
        createdAt: now,
      );

      expect(notification.resolvedRoute, '/community');
    });

    test('resolvedRoute returns default for mood', () {
      final notification = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'T',
        body: 'B',
        type: NotificationType.mood,
        createdAt: now,
      );

      expect(notification.resolvedRoute, '/mood-tracker');
    });

    test('resolvedRoute returns default for payment', () {
      final notification = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'T',
        body: 'B',
        type: NotificationType.payment,
        createdAt: now,
      );

      expect(notification.resolvedRoute, '/subscription');
    });

    test('resolvedRoute returns default for crisis', () {
      final notification = AppNotification(
        id: 'n1',
        userId: 'u1',
        title: 'T',
        body: 'B',
        type: NotificationType.crisis,
        createdAt: now,
      );

      expect(notification.resolvedRoute, '/admin/crisis-alerts');
    });

    test('typeIcon returns correct icon for each type', () {
      final types = {
        NotificationType.booking: '📅',
        NotificationType.message: '💬',
        NotificationType.community: '👥',
        NotificationType.mood: '😊',
        NotificationType.therapist: '👨‍⚕️',
        NotificationType.payment: '💳',
        NotificationType.system: '🔔',
        NotificationType.call: '📞',
        NotificationType.crisis: '🚨',
      };

      for (final entry in types.entries) {
        final notification = AppNotification(
          id: 'n1',
          userId: 'u1',
          title: 'T',
          body: 'B',
          type: entry.key,
          createdAt: now,
        );
        expect(notification.typeIcon, entry.value);
      }
    });
  });

  group('NotificationType', () {
    test('has expected values', () {
      expect(NotificationType.values.length, 9);
      expect(NotificationType.booking.name, 'booking');
      expect(NotificationType.message.name, 'message');
      expect(NotificationType.community.name, 'community');
      expect(NotificationType.mood.name, 'mood');
      expect(NotificationType.system.name, 'system');
      expect(NotificationType.therapist.name, 'therapist');
      expect(NotificationType.payment.name, 'payment');
      expect(NotificationType.call.name, 'call');
      expect(NotificationType.crisis.name, 'crisis');
    });
  });
}
