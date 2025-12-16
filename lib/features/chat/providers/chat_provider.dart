import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../../home/home_screen.dart';

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;

  ChatNotifier(this.ref) : super(const ChatState()) {
    _initializeChat();
  }

  void _initializeChat() {
    final mood = ref.read(selectedMoodProvider);
    final welcomeMessage = ChatResponses.getWelcomeMessage(mood);
    final quickReplies = ChatResponses.getQuickReplies(mood);

    state = ChatState(
      messages: [
        Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: welcomeMessage,
          type: MessageType.bot,
          timestamp: DateTime.now(),
        ),
      ],
      currentMood: mood,
      quickReplies: quickReplies,
    );
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
      quickReplies: [], // Clear quick replies after first message
    );

    // Simulate bot response delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      _addBotResponse(content);
    });
  }

  void _addBotResponse(String userMessage) {
    final response = ChatResponses.getBotResponse(userMessage);

    final botMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      type: MessageType.bot,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, botMessage],
      isTyping: false,
    );
  }

  void selectQuickReply(String reply) {
    sendMessage(reply);
  }

  void clearChat() {
    _initializeChat();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
