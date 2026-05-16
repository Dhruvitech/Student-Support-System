import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/chatbot_service.dart';

class ChatbotProvider extends ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();
  final List<Conversation> _conversations = [];
  String? _activeConversationId;
  bool _isLoading = false;
  bool _isInitialized = false;

  static const String _storageKey = 'chatbot_conversations';
  static const String _activeIdKey = 'chatbot_active_conversation_id';

  List<Conversation> get conversations => _conversations;
  String? get activeConversationId => _activeConversationId;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Get active conversation
  Conversation? get activeConversation {
    if (_activeConversationId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _activeConversationId);
    } catch (e) {
      return null;
    }
  }

  /// Get messages from active conversation
  List<Message> get messages => activeConversation?.messages ?? [];

  ChatbotProvider() {
    _initializeConversations();
  }

  /// Initialize conversations - load from storage or create first conversation
  Future<void> _initializeConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString(_storageKey);
      final storedActiveId = prefs.getString(_activeIdKey);

      if (storedData != null && storedData.isNotEmpty) {
        // Load previous conversations
        final List<dynamic> jsonList = jsonDecode(storedData);
        _conversations.addAll(
          jsonList.map((json) => Conversation.fromJson(json as Map<String, dynamic>)).toList()
        );

        // Set active conversation
        if (storedActiveId != null && _conversations.any((c) => c.id == storedActiveId)) {
          _activeConversationId = storedActiveId;
        } else if (_conversations.isNotEmpty) {
          _activeConversationId = _conversations.first.id;
        }
      }

      // If no conversations, create first one
      if (_conversations.isEmpty) {
        await createNewConversation();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // If loading fails, create first conversation
      await createNewConversation();
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Save all conversations to persistent storage
  Future<void> _saveConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _conversations.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
      if (_activeConversationId != null) {
        await prefs.setString(_activeIdKey, _activeConversationId!);
      }
    } catch (e) {
      debugPrint('Error saving conversations: $e');
    }
  }

  /// Create a new conversation
  Future<void> createNewConversation() async {
    final welcomeMessage = Message(
      text: 'Hello! I\'m your mental health support assistant. 💙\n\nHow are you feeling today? I\'m here to listen and support you.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    final newConversation = Conversation(
      title: 'New Conversation',
      messages: [welcomeMessage],
    );

    _conversations.insert(0, newConversation); // Add to beginning
    _activeConversationId = newConversation.id;
    notifyListeners();

    await _saveConversations();
  }

  /// Switch to a different conversation
  Future<void> switchConversation(String conversationId) async {
    if (_conversations.any((c) => c.id == conversationId)) {
      _activeConversationId = conversationId;
      notifyListeners();
      await _saveConversations();
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);

    // If deleted active conversation, switch to first available
    if (_activeConversationId == conversationId) {
      if (_conversations.isNotEmpty) {
        _activeConversationId = _conversations.first.id;
      } else {
        await createNewConversation();
      }
    }

    notifyListeners();
    await _saveConversations();
  }

  /// Update conversation title
  Future<void> updateConversationTitle(String conversationId, String newTitle) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(title: newTitle);
      notifyListeners();
      await _saveConversations();
    }
  }

  /// Send user message and get AI response
  Future<void> sendMessage(String text) async {
    if (activeConversation == null) return;

    // Add user message
    final userMessage = Message(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    final updatedMessages = List<Message>.from(activeConversation!.messages)..add(userMessage);
    
    // Update conversation with new message
    final index = _conversations.indexWhere((c) => c.id == _activeConversationId);
    _conversations[index] = activeConversation!.copyWith(messages: updatedMessages);

    // Auto-generate title from first user message
    if (activeConversation!.title == 'New Conversation') {
      final userMessages = updatedMessages.where((m) => m.isUser).toList();
      if (userMessages.isNotEmpty) {
        final title = Conversation.generateTitle(userMessages.first.text);
        _conversations[index] = _conversations[index].copyWith(title: title);
      }
    }

    notifyListeners();

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Get AI response from Groq API
      final response = await _chatbotService.getAIResponse(text, updatedMessages);

      // Update user message status to sent
      final messagesCopy = List<Message>.from(_conversations[index].messages);
      final userIndex = messagesCopy.indexWhere((m) => m.id == userMessage.id);
      if (userIndex != -1) {
        messagesCopy[userIndex] = userMessage.copyWith(status: MessageStatus.sent);
      }

      // Add AI message
      messagesCopy.add(Message(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.delivered,
      ));

      _conversations[index] = _conversations[index].copyWith(messages: messagesCopy);
    } catch (e) {
      // Update user message to error status
      final messagesCopy = List<Message>.from(_conversations[index].messages);
      final userIndex = messagesCopy.indexWhere((m) => m.id == userMessage.id);
      if (userIndex != -1) {
        messagesCopy[userIndex] = userMessage.copyWith(status: MessageStatus.error);
      }

      // Fallback response on error
      messagesCopy.add(Message(
        text: _chatbotService.getFallbackResponse(text),
        isUser: false,
        timestamp: DateTime.now(),
      ));

      _conversations[index] = _conversations[index].copyWith(messages: messagesCopy);
    } finally {
      _isLoading = false;
      notifyListeners();

      // Auto-save conversations after each message
      await _saveConversations();
    }
  }

  /// Clear active conversation history
  Future<void> clearConversation() async {
    if (activeConversation == null) return;

    final welcomeMessage = Message(
      text: 'Hello! I\'m your mental health support assistant. 💙\n\nHow are you feeling today? I\'m here to listen and support you.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    final index = _conversations.indexWhere((c) => c.id == _activeConversationId);
    _conversations[index] = _conversations[index].copyWith(
      messages: [welcomeMessage],
      title: 'New Conversation',
    );

    notifyListeners();
    await _saveConversations();
  }

  /// Export conversation as text
  String exportConversation() {
    if (activeConversation == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('Mental Health Chat Conversation');
    buffer.writeln('=' * 50);
    buffer.writeln('Title: ${activeConversation!.title}');
    buffer.writeln('Exported: ${DateTime.now()}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final message in activeConversation!.messages) {
      final sender = message.isUser ? 'You' : 'AI Assistant';
      final time = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';
      buffer.writeln('[$time] $sender:');
      buffer.writeln(message.text);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Get conversation statistics
  Map<String, dynamic> getStats() {
    if (activeConversation == null) return {};

    final userMessages = activeConversation!.messages.where((m) => m.isUser).length;
    final aiMessages = activeConversation!.messages.where((m) => !m.isUser).length;
    final firstMessage = activeConversation!.messages.isNotEmpty 
        ? activeConversation!.messages.first.timestamp 
        : null;
    final lastMessage = activeConversation!.messages.isNotEmpty 
        ? activeConversation!.messages.last.timestamp 
        : null;

    return {
      'totalMessages': activeConversation!.messages.length,
      'userMessages': userMessages,
      'aiMessages': aiMessages,
      'firstMessageTime': firstMessage?.toIso8601String(),
      'lastMessageTime': lastMessage?.toIso8601String(),
      'totalConversations': _conversations.length,
      ..._chatbotService.getStats(),
    };
  }
}
