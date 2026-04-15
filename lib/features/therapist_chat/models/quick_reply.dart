class QuickReply {
  final String category;
  final String label;
  final String text;

  const QuickReply({
    required this.category,
    required this.label,
    required this.text,
  });

  static const List<QuickReply> defaults = [
    // Greetings
    QuickReply(
      category: 'Greetings',
      label: 'Welcome',
      text: 'Hello! Welcome to our session. How are you feeling today?',
    ),
    QuickReply(
      category: 'Greetings',
      label: 'Session Start',
      text: 'Hi there. I am ready for our scheduled session. Shall we begin?',
    ),

    // Session Management
    QuickReply(
      category: 'Session',
      label: '5 Mins Left',
      text:
          'Just a gentle reminder that we have about 5 minutes left in our session today.',
    ),
    QuickReply(
      category: 'Session',
      label: 'Time up',
      text: 'Our session time has come to an end. Thank you for sharing today.',
    ),
    QuickReply(
      category: 'Session',
      label: 'Next Appointment',
      text:
          'Please check your schedule and book our next appointment when you are ready.',
    ),

    // Check-ins
    QuickReply(
      category: 'Check-in',
      label: 'Clarification',
      text: 'Could you tell me a bit more about that?',
    ),
    QuickReply(
      category: 'Check-in',
      label: 'Pause',
      text:
          'Let\'s pause here for a moment and reflect on what you just shared.',
    ),
    QuickReply(
      category: 'Check-in',
      label: 'Empathy',
      text: 'I can hear that this has been very difficult for you.',
    ),

    // Technical
    QuickReply(
      category: 'Technical',
      label: 'Audio Issue',
      text:
          'I am having trouble hearing you. could you please check your microphone?',
    ),
    QuickReply(
      category: 'Technical',
      label: 'Connection',
      text:
          'It seems the connection is a bit unstable. Let me try to reconnect.',
    ),
  ];
}
