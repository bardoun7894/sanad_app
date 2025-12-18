import '../../../features/mood/widgets/mood_selector.dart';

enum MessageType { user, bot, system }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isQuickReply;

  const Message({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isQuickReply = false,
  });

  Message copyWith({
    String? id,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isQuickReply,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isQuickReply: isQuickReply ?? this.isQuickReply,
    );
  }
}

class ChatState {
  final List<Message> messages;
  final bool isTyping;
  final MoodType? currentMood;
  final List<String> quickReplies;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.currentMood,
    this.quickReplies = const [],
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isTyping,
    MoodType? currentMood,
    List<String>? quickReplies,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      currentMood: currentMood ?? this.currentMood,
      quickReplies: quickReplies ?? this.quickReplies,
    );
  }
}

// Mood-based responses and quick replies
class ChatResponses {
  static String getWelcomeMessage(MoodType? mood) {
    switch (mood) {
      case MoodType.happy:
        return "That's wonderful to hear! 😊 I'm glad you're feeling good today. Would you like to share what's making you happy?";
      case MoodType.calm:
        return "It's great that you're feeling calm and peaceful. 😌 How can I help you maintain this positive state?";
      case MoodType.anxious:
        return "I understand that anxiety can be overwhelming. 💙 Take a deep breath. I'm here to help you through this. What's on your mind?";
      case MoodType.sad:
        return "I'm sorry you're feeling sad today. 💜 Remember, it's okay to feel this way. Would you like to talk about what's bothering you?";
      case MoodType.tired:
        return "Feeling tired is completely valid. 🌙 Rest is important for your mental health. How can I support you today?";
      case MoodType.angry:
        return "It sounds like you're feeling frustrated or angry. 😤 Processing these intense emotions is important. What's triggering this feeling?";
      case MoodType.neutral:
        return "You're feeling neutral today. 😐 Sometimes a balanced state is the best time for reflection. How can I help you spend your time?";
      default:
        return "Hello! I'm here to support you. How are you feeling today? Feel free to share anything on your mind.";
    }
  }

  static List<String> getQuickReplies(MoodType? mood) {
    switch (mood) {
      case MoodType.happy:
        return [
          "Share my happiness",
          "Set a positive goal",
          "Practice gratitude",
        ];
      case MoodType.calm:
        return [
          "Continue meditation",
          "Journal my thoughts",
          "Plan my day mindfully",
        ];
      case MoodType.anxious:
        return [
          "Try breathing exercise",
          "Talk about my worries",
          "Need grounding techniques",
        ];
      case MoodType.sad:
        return ["I need to vent", "Help me feel better", "Talk to a therapist"];
      case MoodType.tired:
        return [
          "Relaxation tips",
          "Sleep better tonight",
          "Quick energy boost",
        ];
      case MoodType.angry:
        return ["Ways to calm down", "Identify the trigger", "Venting space"];
      case MoodType.neutral:
        return [
          "Set a daily goal",
          "Reflection prompts",
          "Mindfulness exercise",
        ];
      default:
        return [
          "How can you help me?",
          "I need someone to talk to",
          "Show me exercises",
        ];
    }
  }

  static String getBotResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('anxiety') ||
        lowerMessage.contains('anxious') ||
        lowerMessage.contains('worried')) {
      return "Anxiety can feel overwhelming, but you're not alone. Let's try a simple technique: Take a slow, deep breath in for 4 seconds, hold for 4 seconds, and exhale for 6 seconds. Would you like me to guide you through more exercises?";
    }

    if (lowerMessage.contains('sad') ||
        lowerMessage.contains('depressed') ||
        lowerMessage.contains('unhappy')) {
      return "I hear you, and your feelings are valid. Sometimes sadness is our mind's way of processing difficult experiences. Would you like to talk more about what's been happening, or would you prefer some gentle activities to help lift your mood?";
    }

    if (lowerMessage.contains('therapist') ||
        lowerMessage.contains('professional') ||
        lowerMessage.contains('help')) {
      return "I think speaking with a professional could really help. Our licensed therapists are available to support you. Would you like me to help you book a session?";
    }

    if (lowerMessage.contains('breathing') ||
        lowerMessage.contains('exercise') ||
        lowerMessage.contains('calm')) {
      return "Great choice! Breathing exercises are powerful tools. Let's start with the 4-7-8 technique:\n\n1. Breathe in quietly through your nose for 4 seconds\n2. Hold your breath for 7 seconds\n3. Exhale completely through your mouth for 8 seconds\n\nRepeat this 3-4 times. How do you feel?";
    }

    if (lowerMessage.contains('sleep') ||
        lowerMessage.contains('tired') ||
        lowerMessage.contains('rest')) {
      return "Quality sleep is essential for mental health. Here are some tips:\n\n• Try to sleep at the same time each night\n• Avoid screens 1 hour before bed\n• Keep your room cool and dark\n• Try a relaxing bedtime routine\n\nWould you like a guided sleep meditation?";
    }

    return "Thank you for sharing that with me. I'm here to listen and support you. Is there anything specific you'd like to explore or talk about?";
  }
}
