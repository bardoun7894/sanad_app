import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_support_chat_service.dart';
import '../../admin/services/admin_chat_service.dart';

/// Provider for user support chat service
final userSupportChatServiceProvider = Provider<UserSupportChatService>((ref) {
  return UserSupportChatService();
});

/// Stream provider for support chat messages
final supportMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, userId) {
      final service = ref.watch(userSupportChatServiceProvider);
      return service.getMessages(userId);
    });

/// Stream provider for unread count
final supportUnreadCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  final service = ref.watch(userSupportChatServiceProvider);
  return service.getUnreadCount(userId);
});

/// Stream provider for chat info
final supportChatInfoProvider = StreamProvider.family<SupportChatInfo?, String>(
  (ref, userId) {
    final service = ref.watch(userSupportChatServiceProvider);
    return service.getChatInfo(userId);
  },
);

/// State notifier for support chat session
class SupportChatNotifier extends StateNotifier<SupportChatState> {
  final UserSupportChatService _service;
  final String userId;
  final String userEmail;
  final String? userName;

  SupportChatNotifier({
    required UserSupportChatService service,
    required this.userId,
    required this.userEmail,
    this.userName,
  }) : _service = service,
       super(const SupportChatState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.getOrCreateThread(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
      );
      await _service.markAsRead(userId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Initialize from AI escalation with context
  Future<void> initializeFromEscalation(String aiContext) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.getOrCreateThread(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        source: 'ai_escalation',
        aiContext: aiContext,
      );
      state = state.copyWith(isLoading: false, isEscalated: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Send a message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    state = state.copyWith(isSending: true, error: null);

    try {
      await _service.sendUserMessage(
        userId: userId,
        userEmail: userEmail,
        content: content,
        userName: userName,
      );
      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
      rethrow; // Allow UI to catch and display error
    }
  }

  /// Mark messages as read
  Future<void> markAsRead() async {
    await _service.markAsRead(userId);
  }
}

/// State for support chat session
class SupportChatState {
  final bool isLoading;
  final bool isSending;
  final bool isEscalated;
  final String? error;

  const SupportChatState({
    this.isLoading = false,
    this.isSending = false,
    this.isEscalated = false,
    this.error,
  });

  SupportChatState copyWith({
    bool? isLoading,
    bool? isSending,
    bool? isEscalated,
    String? error,
  }) {
    return SupportChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isEscalated: isEscalated ?? this.isEscalated,
      error: error,
    );
  }
}

/// Provider for support chat session
final supportChatNotifierProvider =
    StateNotifierProvider.family<
      SupportChatNotifier,
      SupportChatState,
      SupportChatParams
    >((ref, params) {
      final service = ref.watch(userSupportChatServiceProvider);
      return SupportChatNotifier(
        service: service,
        userId: params.userId,
        userEmail: params.userEmail,
        userName: params.userName,
      );
    });

/// Parameters for support chat provider
class SupportChatParams {
  final String userId;
  final String userEmail;
  final String? userName;

  const SupportChatParams({
    required this.userId,
    required this.userEmail,
    this.userName,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupportChatParams &&
        other.userId == userId &&
        other.userEmail == userEmail &&
        other.userName == userName;
  }

  @override
  int get hashCode =>
      userId.hashCode ^ userEmail.hashCode ^ (userName?.hashCode ?? 0);
}
