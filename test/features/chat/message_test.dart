import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sanad_app/features/chat/models/message.dart';
import 'package:sanad_app/features/mood/models/mood_enums.dart';

void main() {
  final now = DateTime(2026, 2, 15, 10, 30);

  group('Message', () {
    test('creates with required fields', () {
      final message = Message(
        id: 'msg-1',
        content: 'Hello',
        type: MessageType.user,
        timestamp: now,
      );

      expect(message.id, 'msg-1');
      expect(message.content, 'Hello');
      expect(message.type, MessageType.user);
      expect(message.timestamp, now);
      expect(message.isQuickReply, isFalse);
      expect(message.status, MessageStatus.sent);
      expect(message.metadata, isNull);
    });

    test('copyWith creates updated copy', () {
      final message = Message(
        id: 'msg-1',
        content: 'Hello',
        type: MessageType.user,
        timestamp: now,
      );

      final updated = message.copyWith(
        status: MessageStatus.delivered,
        content: 'Hello!',
      );

      expect(updated.status, MessageStatus.delivered);
      expect(updated.content, 'Hello!');
      expect(updated.id, 'msg-1');
      expect(updated.type, MessageType.user);
      expect(message.content, 'Hello');
    });

    test('toFirestore serializes correctly', () {
      final message = Message(
        id: 'msg-1',
        content: 'Hello',
        type: MessageType.bot,
        timestamp: now,
        status: MessageStatus.read,
      );

      final map = message.toFirestore();

      expect(map['id'], 'msg-1');
      expect(map['content'], 'Hello');
      expect(map['type'], 'bot');
      expect(map['timestamp'], isA<Timestamp>());
      expect(map['is_quick_reply'], false);
      expect(map['status'], 'read');
    });

    test('toFirestore includes metadata when present', () {
      final message = Message(
        id: 'msg-1',
        content: 'Hello',
        type: MessageType.bot,
        timestamp: now,
        metadata: const MessageMetadata(
          tokensUsed: 100,
          model: 'gpt-4',
          crisisDetected: true,
          crisisSeverity: 'critical',
        ),
      );

      final map = message.toFirestore();

      expect(map['metadata'], isNotNull);
      expect(map['metadata']['tokens_used'], 100);
      expect(map['metadata']['model'], 'gpt-4');
      expect(map['metadata']['crisis_detected'], true);
      expect(map['metadata']['crisis_severity'], 'critical');
    });

    test('fromFirestore deserializes correctly', () {
      final map = {
        'id': 'msg-1',
        'content': 'Hello',
        'type': 'user',
        'timestamp': Timestamp.fromDate(now),
        'is_quick_reply': true,
        'status': 'delivered',
      };

      final message = Message.fromFirestore(map);

      expect(message.id, 'msg-1');
      expect(message.content, 'Hello');
      expect(message.type, MessageType.user);
      expect(message.isQuickReply, isTrue);
      expect(message.status, MessageStatus.delivered);
    });

    test('fromFirestore defaults to bot for unknown type', () {
      final map = {
        'id': 'msg-1',
        'content': 'Hello',
        'type': 'unknown_type',
        'timestamp': Timestamp.fromDate(now),
      };

      final message = Message.fromFirestore(map);
      expect(message.type, MessageType.bot);
    });

    test('fromFirestore defaults to sent for unknown status', () {
      final map = {
        'id': 'msg-1',
        'content': 'Hello',
        'type': 'user',
        'timestamp': Timestamp.fromDate(now),
        'status': 'unknown_status',
      };

      final message = Message.fromFirestore(map);
      expect(message.status, MessageStatus.sent);
    });

    test('openAIRole returns correct role', () {
      expect(
        Message(
          id: '1',
          content: '',
          type: MessageType.user,
          timestamp: now,
        ).openAIRole,
        'user',
      );
      expect(
        Message(
          id: '1',
          content: '',
          type: MessageType.bot,
          timestamp: now,
        ).openAIRole,
        'assistant',
      );
      expect(
        Message(
          id: '1',
          content: '',
          type: MessageType.system,
          timestamp: now,
        ).openAIRole,
        'system',
      );
      expect(
        Message(
          id: '1',
          content: '',
          type: MessageType.handoff,
          timestamp: now,
        ).openAIRole,
        'system',
      );
    });

    test('geminiRole returns correct role', () {
      expect(
        Message(
          id: '1',
          content: '',
          type: MessageType.user,
          timestamp: now,
        ).geminiRole,
        'user',
      );
      expect(
        Message(
          id: '1',
          content: '',
          type: MessageType.bot,
          timestamp: now,
        ).geminiRole,
        'model',
      );
      expect(
        Message(
          id: '1',
          content: '',
          type: MessageType.system,
          timestamp: now,
        ).geminiRole,
        'user',
      );
      expect(
        Message(
          id: '1',
          content: '',
          type: MessageType.handoff,
          timestamp: now,
        ).geminiRole,
        'user',
      );
    });
  });

  group('MessageType', () {
    test('has expected values', () {
      expect(MessageType.values.length, 4);
      expect(MessageType.user.name, 'user');
      expect(MessageType.bot.name, 'bot');
      expect(MessageType.system.name, 'system');
      expect(MessageType.handoff.name, 'handoff');
    });
  });

  group('MessageStatus', () {
    test('has expected values', () {
      expect(MessageStatus.values.length, 5);
      expect(MessageStatus.sending.name, 'sending');
      expect(MessageStatus.sent.name, 'sent');
      expect(MessageStatus.delivered.name, 'delivered');
      expect(MessageStatus.read.name, 'read');
      expect(MessageStatus.failed.name, 'failed');
    });
  });

  group('ChatState', () {
    test('creates with defaults', () {
      const state = ChatState();

      expect(state.messages, isEmpty);
      expect(state.isTyping, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.isEscalated, isFalse);
      expect(state.isCrisisMode, isFalse);
      expect(state.guestMessageCount, 0);
      expect(state.guestLimitReached, isFalse);
      expect(ChatState.guestMessageLimit, 5);
    });

    test('copyWith creates updated copy', () {
      const state = ChatState();
      final updated = state.copyWith(
        isTyping: true,
        isLoading: true,
        guestMessageCount: 3,
      );

      expect(updated.isTyping, isTrue);
      expect(updated.isLoading, isTrue);
      expect(updated.guestMessageCount, 3);
      expect(updated.isEscalated, isFalse);
    });

    test('copyWith clears error when null is passed', () {
      const state = ChatState(error: 'some error');
      final updated = state.copyWith();

      expect(updated.error, isNull);
    });
  });

  group('ChatResponses', () {
    test('getWelcomeMessage returns mood-specific message', () {
      final happyMsg = ChatResponses.getWelcomeMessage(MoodType.happy);
      expect(happyMsg, contains('wonderful'));

      final anxiousMsg = ChatResponses.getWelcomeMessage(MoodType.anxious);
      expect(anxiousMsg, contains('anxiety'));

      final sadMsg = ChatResponses.getWelcomeMessage(MoodType.sad);
      expect(sadMsg, contains('sad'));

      final defaultMsg = ChatResponses.getWelcomeMessage(null);
      expect(defaultMsg, contains('Sanad'));
    });

    test('getQuickReplies returns mood-specific replies', () {
      final happyReplies = ChatResponses.getQuickReplies(MoodType.happy);
      expect(happyReplies.length, 3);

      final anxiousReplies = ChatResponses.getQuickReplies(MoodType.anxious);
      expect(anxiousReplies.length, 3);

      final defaultReplies = ChatResponses.getQuickReplies(null);
      expect(defaultReplies.length, 3);
    });

    test('getBotResponse returns relevant response for anxiety', () {
      final response = ChatResponses.getBotResponse('I feel anxious');
      expect(response, contains('breath'));
    });

    test('getBotResponse returns relevant response for sadness', () {
      final response = ChatResponses.getBotResponse('I feel sad');
      expect(response, contains('valid'));
    });

    test('getBotResponse returns relevant response for therapist request', () {
      final response = ChatResponses.getBotResponse('I need a therapist');
      expect(response, contains('professional'));
    });

    test('getBotResponse returns relevant response for breathing', () {
      final response = ChatResponses.getBotResponse('breathing exercise');
      expect(response, contains('4-7-8'));
    });

    test('getBotResponse returns relevant response for sleep', () {
      final response = ChatResponses.getBotResponse('I need better sleep');
      expect(response, contains('sleep'));
    });

    test('getBotResponse returns default for unknown input', () {
      final response = ChatResponses.getBotResponse('random text');
      expect(response, contains('Thank you'));
    });
  });

  group('MessageMetadata', () {
    test('toFirestore includes only non-null fields', () {
      const metadata = MessageMetadata(tokensUsed: 50, model: 'gpt-4');

      final map = metadata.toFirestore();

      expect(map['tokens_used'], 50);
      expect(map['model'], 'gpt-4');
      expect(map.containsKey('mood_detected'), isFalse);
      expect(map.containsKey('crisis_detected'), isFalse);
    });

    test('fromFirestore deserializes correctly', () {
      final map = {
        'tokens_used': 100,
        'model': 'gemini-pro',
        'mood_detected': 'happy',
        'escalation_suggested': true,
        'crisis_detected': false,
        'crisis_keywords_matched': ['keyword1'],
        'resources_provided': ['resource1', 'resource2'],
      };

      final metadata = MessageMetadata.fromFirestore(map);

      expect(metadata.tokensUsed, 100);
      expect(metadata.model, 'gemini-pro');
      expect(metadata.moodDetected, 'happy');
      expect(metadata.escalationSuggested, isTrue);
      expect(metadata.crisisDetected, isFalse);
      expect(metadata.crisisKeywordsMatched, ['keyword1']);
      expect(metadata.resourcesProvided, ['resource1', 'resource2']);
    });
  });
}
