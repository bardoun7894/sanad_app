import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/therapist_chat.dart';
import '../models/therapist_message.dart';
import '../services/therapist_chat_service.dart';

/// Provider for therapist chat service
final therapistChatServiceProvider = Provider<TherapistChatService>((ref) {
  return TherapistChatService();
});

/// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});

/// Stream provider for therapist's chat list
final therapistChatsProvider =
    StreamProvider.family<List<TherapistChatThread>, String>((
      ref,
      therapistId,
    ) {
      final service = ref.watch(therapistChatServiceProvider);
      return service.getChatsForTherapist(therapistId);
    });

/// Stream provider for user's chat list
final userChatsProvider =
    StreamProvider.family<List<TherapistChatThread>, String>((ref, userId) {
      final service = ref.watch(therapistChatServiceProvider);
      return service.getChatsForUser(userId);
    });

/// Stream provider for messages in a specific chat
final chatMessagesProvider =
    StreamProvider.family<List<TherapistMessage>, String>((ref, chatId) {
      final service = ref.watch(therapistChatServiceProvider);
      return service.getMessages(chatId);
    });

/// Stream provider for unread count (therapist)
final therapistUnreadCountProvider = StreamProvider.family<int, String>((
  ref,
  therapistId,
) {
  final service = ref.watch(therapistChatServiceProvider);
  return service.getUnreadCountForTherapist(therapistId);
});

/// Stream provider for unread count (user)
final userUnreadCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  final service = ref.watch(therapistChatServiceProvider);
  return service.getUnreadCountForUser(userId);
});

/// Stream provider for typing status
final typingStatusProvider = StreamProvider.family<TypingStatus, String>((
  ref,
  chatId,
) {
  final service = ref.watch(therapistChatServiceProvider);
  return service.getTypingStatus(chatId);
});

/// State notifier for active chat session
class ChatSessionNotifier extends StateNotifier<ChatSessionState> {
  final TherapistChatService _service;
  final String chatId;
  final SenderType senderType;
  Timer? _typingTimer;

  ChatSessionNotifier({
    required TherapistChatService service,
    required this.chatId,
    required this.senderType,
  }) : _service = service,
       super(const ChatSessionState()) {
    _markAsRead();
  }

  /// Mark messages as read when chat is opened
  Future<void> _markAsRead() async {
    await _service.markAsRead(chatId: chatId, readerType: senderType);
  }

  /// Send a message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    state = state.copyWith(isSending: true, error: null);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _service.sendMessage(
        chatId: chatId,
        senderId: userId,
        senderName: FirebaseAuth.instance.currentUser?.displayName,
        senderType: senderType,
        content: content,
      );

      // Stop typing indicator after sending
      _stopTyping();

      state = state.copyWith(isSending: false);
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
      rethrow; // Allow UI to catch and display error
    }
  }

  /// Update typing status (with debounce)
  void onTyping() {
    _typingTimer?.cancel();

    // Set typing to true
    _service.updateTypingStatus(
      chatId: chatId,
      senderType: senderType,
      isTyping: true,
    );

    // Auto-stop typing after 3 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    _service.updateTypingStatus(
      chatId: chatId,
      senderType: senderType,
      isTyping: false,
    );
  }

  @override
  void dispose() {
    _stopTyping();
    _typingTimer?.cancel();
    super.dispose();
  }
}

/// State for active chat session
class ChatSessionState {
  final bool isSending;
  final String? error;

  const ChatSessionState({this.isSending = false, this.error});

  ChatSessionState copyWith({bool? isSending, String? error}) {
    return ChatSessionState(
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

/// Provider for chat session state
final chatSessionProvider =
    StateNotifierProvider.family<
      ChatSessionNotifier,
      ChatSessionState,
      ChatSessionParams
    >((ref, params) {
      final service = ref.watch(therapistChatServiceProvider);
      return ChatSessionNotifier(
        service: service,
        chatId: params.chatId,
        senderType: params.senderType,
      );
    });

/// Parameters for chat session provider
class ChatSessionParams {
  final String chatId;
  final SenderType senderType;

  const ChatSessionParams({required this.chatId, required this.senderType});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSessionParams &&
        other.chatId == chatId &&
        other.senderType == senderType;
  }

  @override
  int get hashCode => chatId.hashCode ^ senderType.hashCode;
}
