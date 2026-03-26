import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../editor/editor_provider.dart';
import '../terminal/terminal_provider.dart';

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

class AiNotifier extends Notifier<AiState> {
  static const _apiKeyKey = 'openrouter_api_key';
  static const _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'meta-llama/llama-3.3-70b-instruct:free';
  static const _storage = FlutterSecureStorage();

  @override
  AiState build() {
    _loadApiKey();
    return const AiState();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _storage.read(key: _apiKeyKey);
    if (apiKey != null && apiKey.isNotEmpty) {
      state = state.copyWith(apiKey: apiKey);
    }
  }

  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
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
      // Build context from editor and terminal
      final editorState = ref.read(editorProvider);
      final terminalState = ref.read(terminalProvider);

      final systemPrompt = _buildSystemPrompt(
        editorState: editorState,
        terminalState: terminalState,
      );

      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ...state.messages.map((m) => {'role': m.role, 'content': m.content}),
        {'role': 'user', 'content': content.trim()},
      ];

      final client = http.Client();
      final request = http.Request('POST', Uri.parse(_apiUrl))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${state.apiKey}',
          'HTTP-Referer': 'https://github.com/OlehHavrilko/VELOX',
          'X-Title': 'VELOX Mobile IDE',
        })
        ..body = jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 2048,
          'temperature': 0.7,
          'stream': true,
        });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        state = state.copyWith(
          isLoading: false,
          error: 'API Error: ${response.statusCode} - $body',
        );
        client.close();
        return;
      }

      // Seed an empty assistant message; tokens will fill it in.
      final streamStart = DateTime.now();
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(role: 'assistant', content: '', timestamp: streamStart),
        ],
      );

      final contentBuffer = StringBuffer();
      var lineBuffer = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        lineBuffer += chunk;
        final parts = lineBuffer.split('\n');
        lineBuffer = parts.removeLast(); // hold back any incomplete line
        for (final line in parts) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data: ')) continue;
          final data = trimmed.substring(6);
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            final delta =
                json['choices'][0]['delta']['content'] as String? ?? '';
            if (delta.isEmpty) continue;
            contentBuffer.write(delta);
            final updated = [...state.messages];
            updated[updated.length - 1] = ChatMessage(
              role: 'assistant',
              content: contentBuffer.toString(),
              timestamp: streamStart,
            );
            state = state.copyWith(messages: updated);
          } catch (_) {
            // skip malformed SSE chunks
          }
        }
      }

      client.close();
      state = state.copyWith(isLoading: false);
      _processActionBlocks(contentBuffer.toString());
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: $e',
      );
    }
  }

  String _buildSystemPrompt({
    required EditorState editorState,
    required TerminalState terminalState,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('You are an expert coding assistant integrated into VELOX mobile IDE.');
    buffer.writeln('Help with Dart, Flutter, Kotlin, Python, JavaScript, and general coding questions.');
    buffer.writeln();

    // Add current file context
    if (editorState.filePath != null) {
      buffer.writeln('Current file: ${editorState.filePath}');
      buffer.writeln('Language: ${editorState.language}');
      buffer.writeln('Content:');
      buffer.writeln(editorState.content);
      buffer.writeln();
    }

    // Add terminal output context (last 50 lines for brevity)
    if (terminalState.outputBuffer.isNotEmpty) {
      buffer.writeln('Recent terminal output (last ${terminalState.outputBuffer.length} lines):');
      final lines = terminalState.outputBuffer.length > 50
          ? terminalState.outputBuffer.sublist(terminalState.outputBuffer.length - 50)
          : terminalState.outputBuffer;
      for (final line in lines) {
        buffer.writeln(line);
      }
      buffer.writeln();
    }

    // Add available actions
    buffer.writeln('Available actions:');
    buffer.writeln('- Insert code at cursor: Use [INSERT_CODE] block in response');
    buffer.writeln('- Run command: Use [RUN_COMMAND] block in response');
    buffer.writeln();

    return buffer.toString();
  }

  void _processActionBlocks(String content) {
    final insertPattern =
        RegExp(r'\[INSERT_CODE\](.*?)\[/INSERT_CODE\]', dotAll: true);
    for (final match in insertPattern.allMatches(content)) {
      insertCode(match.group(1)!.trim());
    }

    final runPattern =
        RegExp(r'\[RUN_COMMAND\](.*?)\[/RUN_COMMAND\]', dotAll: true);
    for (final match in runPattern.allMatches(content)) {
      runCommand(match.group(1)!.trim());
    }
  }

  void insertCode(String code) {
    final controller = ref.read(editorControllerProvider);
    if (controller == null) return;
    controller.runJavaScript('insertAtCursor(${jsonEncode(code)})');
  }

  void runCommand(String command) {
    ref.read(terminalProvider.notifier).sendCommand(command);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearHistory() {
    state = state.copyWith(messages: []);
  }
}

final aiProvider = NotifierProvider<AiNotifier, AiState>(AiNotifier.new);
