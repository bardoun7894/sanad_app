import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fcm_service.dart';

/// Provider for FCM service instance
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// Provider for notification settings
final notificationSettingsProvider =
    FutureProvider.family<Map<String, bool>, String>((ref, userId) async {
      final fcm = ref.watch(fcmServiceProvider);
      return fcm.getNotificationSettings(userId);
    });

/// State notifier for managing FCM registration
class FCMNotifier extends StateNotifier<FCMState> {
  final FCMService _service;

  FCMNotifier(this._service) : super(const FCMState());

  /// Initialize FCM
  Future<void> initialize() async {
    state = state.copyWith(isInitializing: true);
    try {
      await _service.initialize();
      state = state.copyWith(isInitializing: false, isInitialized: true);
    } catch (e) {
      state = state.copyWith(isInitializing: false, error: e.toString());
    }
  }

  /// Request permission
  Future<bool> requestPermission() async {
    final granted = await _service.requestPermission();
    state = state.copyWith(hasPermission: granted);
    return granted;
  }

  /// Register user for notifications
  Future<void> registerUser(String userId) async {
    try {
      await _service.registerUser(userId);
      state = state.copyWith(registeredUserId: userId, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Unregister user
  Future<void> unregisterUser() async {
    try {
      await _service.unregisterUser();
      state = state.copyWith(registeredUserId: null, error: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update notification settings
  Future<void> updateSettings({
    required String userId,
    bool? chatEnabled,
    bool? bookingEnabled,
    bool? communityEnabled,
    bool? systemEnabled,
  }) async {
    final success = await _service.updateNotificationSettings(
      userId: userId,
      chatEnabled: chatEnabled,
      bookingEnabled: bookingEnabled,
      communityEnabled: communityEnabled,
      systemEnabled: systemEnabled,
    );
    if (!success) {
      state = state.copyWith(error: 'Failed to update notification settings');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _service.clearAllNotifications();
  }
}

/// FCM State
class FCMState {
  final bool isInitializing;
  final bool isInitialized;
  final bool hasPermission;
  final String? registeredUserId;
  final String? error;

  const FCMState({
    this.isInitializing = false,
    this.isInitialized = false,
    this.hasPermission = false,
    this.registeredUserId,
    this.error,
  });

  FCMState copyWith({
    bool? isInitializing,
    bool? isInitialized,
    bool? hasPermission,
    String? registeredUserId,
    String? error,
  }) {
    return FCMState(
      isInitializing: isInitializing ?? this.isInitializing,
      isInitialized: isInitialized ?? this.isInitialized,
      hasPermission: hasPermission ?? this.hasPermission,
      registeredUserId: registeredUserId ?? this.registeredUserId,
      error: error,
    );
  }
}

/// Provider for FCM state management
final fcmNotifierProvider = StateNotifierProvider<FCMNotifier, FCMState>((ref) {
  final service = ref.watch(fcmServiceProvider);
  return FCMNotifier(service);
});
