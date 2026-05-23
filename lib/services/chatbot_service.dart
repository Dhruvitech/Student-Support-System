import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/message.dart';

class ChatbotService {
  DateTime? _lastRequestTime;
  int _requestCount = 0;

  // Mental health-focused system prompt for empathetic responses
  static const String _systemPrompt = '''You are a compassionate mental health support chatbot for students. Your role is to:

1. Listen empathetically and validate their feelings
2. Provide supportive, non-judgmental responses
3. Offer coping strategies and self-care suggestions
4. Encourage professional help when needed (counselors, therapists)
5. Keep responses concise and warm (2-3 sentences)

Important guidelines:
- Never diagnose or provide medical advice
- Always be supportive and understanding
- Recognize crisis situations and suggest immediate help
- Use simple, comforting language
- Ask clarifying questions when helpful

Remember: You are a supportive friend, not a replacement for professional mental health care.''';

  /// Get AI response from Groq API with conversation context
  Future<String> getAIResponse(String userMessage, List<Message> conversationHistory) async {
    // Check if API is configured
    if (!AppConfig.isConfigured) {
      return _getConfigurationErrorMessage();
    }

    // Apply rate limiting
    await _applyRateLimit();

    // Try with retry mechanism
    return await _makeRequestWithRetry(userMessage, conversationHistory);
  }

  /// Make API request with retry logic
  Future<String> _makeRequestWithRetry(String userMessage, List<Message> conversationHistory) async {
    int attempt = 0;

    while (attempt < AppConfig.maxRetryAttempts) {
      try {
        return await _makeApiRequest(userMessage, conversationHistory);
      } on http.ClientException {
        attempt++;
        if (attempt < AppConfig.maxRetryAttempts) {
          // Wait before retry with exponential backoff
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      } on FormatException {
        // Don't retry on parsing errors
        return _getErrorMessage('Invalid response format from AI service');
      } catch (e) {
        attempt++;
        if (attempt < AppConfig.maxRetryAttempts) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }

    // All retries failed
    return _getErrorMessage('Unable to connect after $attempt attempts');
  }

  /// Make actual API request
  Future<String> _makeApiRequest(String userMessage, List<Message> conversationHistory) async {
    // Prepare conversation context (last 10 messages for context)
    final contextMessages = _prepareMessages(conversationHistory, userMessage);
    
    // Make API call to Groq
    final response = await http.post(
      Uri.parse(AppConfig.groqApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
      },
      body: jsonEncode({
        'model': AppConfig.groqModel,
        'messages': contextMessages,
        'temperature': 0.7, // Balanced creativity
        'max_tokens': 500, // Concise responses
        'top_p': 0.9,
      }),
    ).timeout(Duration(seconds: AppConfig.apiTimeout));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Validate response structure
      if (data['choices'] == null || data['choices'].isEmpty) {
        throw FormatException('Invalid API response structure');
      }
      
      final aiResponse = data['choices'][0]['message']['content'].toString().trim();
      
      if (aiResponse.isEmpty) {
        throw FormatException('Empty response from AI');
      }
      
      _requestCount++;
      return aiResponse;
    } else if (response.statusCode == 401) {
      return _getErrorMessage('Invalid API key. Please check your Groq API key in app_config.dart');
    } else if (response.statusCode == 429) {
      return _getErrorMessage('Too many requests. Please wait a moment before trying again.');
    } else if (response.statusCode >= 500) {
      return _getErrorMessage('AI service temporarily unavailable. Please try again.');
    } else {
      return _getErrorMessage('AI service error (${response.statusCode})');
    }
  }

  /// Apply rate limiting between requests
  Future<void> _applyRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!).inMilliseconds;
      if (timeSinceLastRequest < AppConfig.minRequestInterval) {
        await Future.delayed(
          Duration(milliseconds: AppConfig.minRequestInterval - timeSinceLastRequest)
        );
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Prepare messages with system prompt and conversation context
  List<Map<String, String>> _prepareMessages(List<Message> history, String currentMessage) {
    final messages = <Map<String, String>>[];
    
    // Add system prompt
    messages.add({
      'role': 'system',
      'content': _systemPrompt,
    });

    // Add recent conversation history (last 10 messages for context)
    final recentHistory = history.length > 10 
        ? history.sublist(history.length - 10) 
        : history;

    for (final msg in recentHistory) {
      if (msg.text.isNotEmpty) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }
    }

    // Add current user message
    messages.add({
      'role': 'user',
      'content': currentMessage,
    });

    return messages;
  }

  /// Get configuration error message
  String _getConfigurationErrorMessage() {
    return "⚙️ ${AppConfig.configurationError}\n\nIn the meantime, I'll use basic responses. For full AI capabilities, please configure your Groq API key.";
  }

  /// Get friendly error message with fallback support
  String _getErrorMessage(String technicalError) {
    return "I'm having trouble connecting right now. 😔 Please try again in a moment, or reach out to campus counseling services if you need immediate support.";
  }

  /// Fallback response when API is unavailable
  String getFallbackResponse(String message) {
    final lowerText = message.toLowerCase();

    if (lowerText.contains('stress') || lowerText.contains('stressed')) {
      return "I understand you're feeling stressed. Take a deep breath and try to relax. Consider talking to a counselor if stress becomes overwhelming. 🌿";
    } else if (lowerText.contains('anxiety') || lowerText.contains('anxious')) {
      return "Anxiety can be tough. Try focusing on your breathing and staying present. Campus counseling services can provide professional support. 🧘‍♂️";
    } else if (lowerText.contains('sad') || lowerText.contains('depressed')) {
      return "I hear you. Feeling sad is valid. Talking to someone you trust or a counselor might help. You're not alone. ❤️";
    } else if (lowerText.contains('help') || lowerText.contains('support')) {
      return "I'm here to listen. Please share what's on your mind, or consider reaching out to professional counselors for deeper support. 🤝";
    } else {
      return "I'm here for you. Can you tell me more about what you're experiencing? 💙";
    }
  }

  /// Get service statistics
  Map<String, dynamic> getStats() {
    return {
      'requestCount': _requestCount,
      'lastRequestTime': _lastRequestTime?.toIso8601String(),
      'isConfigured': AppConfig.isConfigured,
    };
  }
}
