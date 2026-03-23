import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class AiState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String? apiKey;

  const AiState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.apiKey,
  });

  AiState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? apiKey,
  }) {
    return AiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}

class AiNotifier extends StateNotifier<AiState> {
  static const _apiKeyKey = 'openrouter_api_key';
  static const _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'meta-llama/llama-3.3-70b-instruct:free';
  static const _systemPrompt =
      'You are an expert coding assistant integrated into VELOX mobile IDE. '
      'Help with Dart, Flutter, Kotlin, Python, JavaScript, and general coding questions.';

  AiNotifier() : super(const AiState()) {
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_apiKeyKey);
    if (apiKey != null && apiKey.isNotEmpty) {
      state = state.copyWith(apiKey: apiKey);
    }
  }

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
    state = state.copyWith(apiKey: apiKey);
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (state.apiKey == null || state.apiKey!.isEmpty) {
      state = state.copyWith(
          error: 'API key not set. Please add your OpenRouter API key.');
      return;
    }

    final userMessage = ChatMessage(
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        ...state.messages.map((m) => {'role': m.role, 'content': m.content}),
        {'role': 'user', 'content': content.trim()},
      ];

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${state.apiKey}',
          'HTTP-Referer': 'https://github.com/OlehHavrilko/VELOX',
          'X-Title': 'VELOX Mobile IDE',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 2048,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantContent =
            data['choices'][0]['message']['content'] as String;

        final assistantMessage = ChatMessage(
          role: 'assistant',
          content: assistantContent,
          timestamp: DateTime.now(),
        );

        state = state.copyWith(
          messages: [...state.messages, assistantMessage],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearHistory() {
    state = state.copyWith(messages: []);
  }
}

final aiProvider = StateNotifierProvider<AiNotifier, AiState>(
  (ref) => AiNotifier(),
);
