import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../editor/editor_provider.dart';
import '../editor/editor_webview.dart';
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

class AiNotifier extends StateNotifier<AiState> {
  static const _apiKeyKey = 'openrouter_api_key';
  static const _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'meta-llama/llama-3.3-70b-instruct:free';

  // References to other providers - will be set via ref
  final Ref _ref;

  AiNotifier(this._ref) : super(const AiState()) {
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
      // Build context from editor and terminal
      final editorState = _ref.read(editorProvider);
      final terminalState = _ref.read(terminalProvider);

      final systemPrompt = _buildSystemPrompt(
        editorState: editorState,
        terminalState: terminalState,
      );

      final messages = [
        {'role': 'system', 'content': systemPrompt},
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

        // Execute any actions embedded in the response.
        _processActions(assistantContent);
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

  /// Parses [INSERT_CODE]...[/INSERT_CODE] and [RUN_COMMAND]...[/RUN_COMMAND]
  /// blocks from an assistant message and executes the corresponding actions.
  void _processActions(String content) {
    // Insert code blocks into the editor.
    final insertRe =
        RegExp(r'\[INSERT_CODE\](.*?)\[/INSERT_CODE\]', dotAll: true);
    for (final match in insertRe.allMatches(content)) {
      final code = match.group(1)?.trim() ?? '';
      if (code.isNotEmpty) insertCode(code);
    }

    // Run command blocks in the terminal.
    final runRe = RegExp(r'\[RUN_COMMAND\](.*?)\[/RUN_COMMAND\]', dotAll: true);
    for (final match in runRe.allMatches(content)) {
      final cmd = match.group(1)?.trim() ?? '';
      if (cmd.isNotEmpty) runCommand(cmd);
    }
  }

  /// Inserts [code] at the current cursor position in the Monaco editor.
  void insertCode(String code) {
    try {
      final controller = _ref.read(editorWebViewControllerProvider);
      if (controller == null) {
        state = state.copyWith(
            error: 'Editor is not open. Navigate to the editor tab first.');
        return;
      }
      // JSON-encode to safely escape quotes and newlines for JS.
      final codeJson = jsonEncode(code);
      controller.runJavaScript('insertText($codeJson)');
    } catch (e) {
      state = state.copyWith(error: 'Failed to insert code: $e');
    }
  }

  void runCommand(String command) {
    _ref.read(terminalProvider.notifier).sendCommand(command);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearHistory() {
    state = state.copyWith(messages: []);
  }
}

final aiProvider = StateNotifierProvider<AiNotifier, AiState>(
  (ref) => AiNotifier(ref),
);
