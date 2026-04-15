import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<AppNotification> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  List<AppNotification> get readNotifications =>
      notifications.where((n) => n.isRead).toList();

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;
  final Ref _ref;
  StreamSubscription? _subscription;

  NotificationNotifier(this._service, this._ref)
    : super(const NotificationState()) {
    _init();
  }

  void _init() {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    // Clean up old notifications without routes on first load
    _service.deleteNotificationsWithoutRoute(user.uid);

    _subscription = _service
        .getNotificationsStream(user.uid)
        .listen(
          (notifications) {
            state = state.copyWith(
              notifications: notifications,
              isLoading: false,
            );
          },
          onError: (e) {
            state = state.copyWith(
              isLoading: false,
              error: 'Failed to load notifications: $e',
            );
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Optimistic update
      final updated = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      state = state.copyWith(notifications: updated);

      final result = await _service.markAsRead(notificationId);
      if (!result.success) {
        state = state.copyWith(error: result.error ?? 'Failed to mark as read');
      }
    } catch (e) {
      // Revert on error - will sync from stream
      state = state.copyWith(error: 'Failed to mark as read');
    }
  }

  Future<void> markAllAsRead() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      // Optimistic update
      final updated = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      state = state.copyWith(notifications: updated);

      final result = await _service.markAllAsRead(user.uid);
      if (!result.success || result.hasPartialFailure) {
        state = state.copyWith(
          error: result.error ?? 'Some notifications could not be marked read',
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark all as read');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      // Optimistic update
      final updated = state.notifications
          .where((n) => n.id != notificationId)
          .toList();
      state = state.copyWith(notifications: updated);

      final result = await _service.deleteNotification(notificationId);
      if (!result.success) {
        state = state.copyWith(
          error: result.error ?? 'Failed to delete notification',
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete notification');
    }
  }

  Future<void> clearAll() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      state = state.copyWith(notifications: []);
      final result = await _service.clearAllNotifications(user.uid);
      if (!result.success || result.hasPartialFailure) {
        state = state.copyWith(
          error: result.error ?? 'Some notifications could not be cleared',
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear notifications');
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final service = ref.watch(notificationServiceProvider);
      return NotificationNotifier(service, ref);
    });

/// Convenience provider for just the unread count
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

/// Stream provider for real-time unread count (more efficient for badges)
final unreadCountStreamProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);

  final service = ref.watch(notificationServiceProvider);
  return service.getUnreadCountStream(user.uid);
});
