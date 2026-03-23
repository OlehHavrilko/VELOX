import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_provider.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(aiProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(
      text: ref.read(aiProvider).apiKey ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          'OpenRouter API Key',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter your API key',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00E5FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              ref.read(aiProvider.notifier).saveApiKey(controller.text.trim());
              Navigator.pop(context);
            },
            child:
                const Text('Save', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider);

    ref.listen<AiState>(aiProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade800,
          ),
        );
        ref.read(aiProvider.notifier).clearError();
      }
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Column(
        children: [
          _buildHeader(state),
          Expanded(child: _buildChatMessages(state)),
          _buildInputArea(state),
        ],
      ),
    );
  }

  Widget _buildHeader(AiState state) {
    return Container(
      height: 48,
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.smart_toy, color: Color(0xFF00E5FF), size: 24),
          const SizedBox(width: 12),
          const Text(
            'AI Assistant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (state.apiKey != null && state.apiKey!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep,
                  color: Colors.white54, size: 20),
              onPressed: () => ref.read(aiProvider.notifier).clearHistory(),
              tooltip: 'Clear chat',
            ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54, size: 20),
            onPressed: _showApiKeyDialog,
            tooltip: 'API Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages(AiState state) {
    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Start a conversation',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              state.apiKey == null || state.apiKey!.isEmpty
                  ? 'Set your API key to begin'
                  : 'Ask a coding question',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length && state.isLoading) {
          return _buildLoadingIndicator();
        }

        final message = state.messages[index];
        final isUser = message.role == 'user';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) _buildAvatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFFCDD9E5),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isUser) _buildAvatar(isUser: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar({bool isUser = false}) {
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          isUser ? const Color(0xFF7C3AED) : const Color(0xFF00E5FF),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AiState state) {
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Ask a coding question...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF00E5FF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF080B10), size: 20),
              onPressed: state.isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
