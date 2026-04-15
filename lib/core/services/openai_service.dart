import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// OpenAI Service for GPT-4o integration
/// Handles AI chat functionality for mental health support
class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-4o';
  static const int _maxTokens = 1000;
  static const double _temperature = 0.7;

  final Dio _dio;
  final String _apiKey;

  /// System prompt for mental health support context
  static const String _systemPrompt = '''
You are Sanad, a compassionate and empathetic mental health support assistant. Your role is to:

1. LISTEN with empathy and validate the user's feelings without judgment
2. PROVIDE evidence-based coping strategies and emotional support techniques
3. ENCOURAGE healthy behaviors like breathing exercises, mindfulness, and self-care
4. RECOGNIZE crisis situations and recommend professional help when needed
5. MAINTAIN a warm, supportive, and non-judgmental tone

IMPORTANT GUIDELINES:
- Never diagnose mental health conditions or prescribe medication
- Never provide medical advice - always recommend consulting professionals for medical concerns
- If the user expresses suicidal thoughts, severe depression, or crisis:
  * Take it seriously and respond with care
  * Encourage them to contact emergency services or crisis hotlines
  * Offer to connect them with a professional therapist through the app
- Keep responses concise but meaningful (2-4 paragraphs max)
- Use simple, clear language that's easy to understand
- Ask follow-up questions to better understand the user's situation
- Remember context from the conversation to provide personalized support

You can respond in both English and Arabic based on the user's language.
''';

  OpenAIService({required String apiKey})
    : _apiKey = apiKey,
      _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  /// Send a message to GPT-4o and get a response
  /// [messages] - List of conversation history in OpenAI format
  /// [userMood] - Optional mood context to personalize response
  Future<OpenAIResponse> sendMessage({
    required List<ChatMessage> messages,
    String? userMood,
  }) async {
    try {
      // Build messages array with system prompt
      final List<Map<String, String>> apiMessages = [
        {'role': 'system', 'content': _buildSystemPrompt(userMood)},
        ...messages.map((m) => {'role': m.role, 'content': m.content}),
      ];

      final response = await _dio.post(
        '/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
        data: {
          'model': _model,
          'messages': apiMessages,
          'max_tokens': _maxTokens,
          'temperature': _temperature,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final choices = data['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          throw OpenAIException('No choices returned from AI service');
        }
        final choice = choices[0];
        final usage = data['usage'];

        return OpenAIResponse(
          content: choice['message']['content'] as String,
          tokensUsed: usage['total_tokens'] as int,
          promptTokens: usage['prompt_tokens'] as int,
          completionTokens: usage['completion_tokens'] as int,
          model: _model,
          finishReason: choice['finish_reason'] as String?,
        );
      } else {
        throw OpenAIException(
          'API request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint('OpenAI DioException: ${e.message}');

      if (e.response?.statusCode == 429) {
        throw OpenAIException(
          'Rate limit exceeded. Please try again in a moment.',
          statusCode: 429,
          isRetryable: true,
        );
      } else if (e.response?.statusCode == 401) {
        throw OpenAIException(
          'Invalid API key. Please check your configuration.',
          statusCode: 401,
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw OpenAIException(
          'Connection timed out. Please check your internet connection.',
          isRetryable: true,
        );
      }

      throw OpenAIException(
        e.message ?? 'An error occurred while connecting to AI service',
        statusCode: e.response?.statusCode,
        isRetryable: true,
      );
    } catch (e) {
      debugPrint('OpenAI Error: $e');
      if (e is OpenAIException) rethrow;
      throw OpenAIException('Unexpected error: $e');
    }
  }

  /// Build system prompt with optional mood context
  String _buildSystemPrompt(String? userMood) {
    if (userMood == null || userMood.isEmpty) {
      return _systemPrompt;
    }

    return '''
$_systemPrompt

CURRENT CONTEXT:
The user has indicated they are feeling "$userMood". Please acknowledge this and tailor your responses to help them with this emotional state. Provide relevant coping strategies and support.
''';
  }

  /// Check if the message suggests a crisis situation
  static bool detectCrisis(String message) {
    final crisisKeywords = [
      'suicide',
      'kill myself',
      'end my life',
      'want to die',
      'dont want to live',
      "don't want to live",
      'hurt myself',
      'self harm',
      'cutting',
      'overdose',
      'انتحار',
      'اقتل نفسي',
      'أريد الموت',
    ];

    final lowerMessage = message.toLowerCase();
    return crisisKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Suggest escalation based on conversation context
  static bool shouldSuggestEscalation(String message) {
    final escalationKeywords = [
      'talk to someone',
      'real person',
      'human',
      'therapist',
      'professional',
      'doctor',
      'counselor',
      'not helping',
      'need more help',
      'أريد التحدث',
      'معالج',
      'طبيب',
    ];

    final lowerMessage = message.toLowerCase();
    return escalationKeywords.any((keyword) => lowerMessage.contains(keyword));
  }
}

/// Chat message model for OpenAI API
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime? timestamp;

  ChatMessage({required this.role, required this.content, this.timestamp});

  Map<String, String> toJson() => {'role': role, 'content': content};

  factory ChatMessage.user(String content) =>
      ChatMessage(role: 'user', content: content, timestamp: DateTime.now());

  factory ChatMessage.assistant(String content) => ChatMessage(
    role: 'assistant',
    content: content,
    timestamp: DateTime.now(),
  );
}

/// Response from OpenAI API
class OpenAIResponse {
  final String content;
  final int tokensUsed;
  final int promptTokens;
  final int completionTokens;
  final String model;
  final String? finishReason;

  OpenAIResponse({
    required this.content,
    required this.tokensUsed,
    required this.promptTokens,
    required this.completionTokens,
    required this.model,
    this.finishReason,
  });

  bool get wasContentFiltered => finishReason == 'content_filter';
  bool get wasLengthLimited => finishReason == 'length';
}

/// Custom exception for OpenAI errors
class OpenAIException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRetryable;

  OpenAIException(this.message, {this.statusCode, this.isRetryable = false});

  @override
  String toString() => 'OpenAIException: $message (status: $statusCode)';
}
