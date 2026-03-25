import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'editor_provider.dart';

/// Exposes the editor's insertText capability so other features (e.g. AI) can
/// inject code without going through a platform channel.
final editorWebViewControllerProvider =
    StateProvider<WebViewController?>((ref) => null);

class EditorWebView extends ConsumerStatefulWidget {
  const EditorWebView({super.key});

  @override
  ConsumerState<EditorWebView> createState() => _EditorWebViewState();
}

class _EditorWebViewState extends ConsumerState<EditorWebView> {
  late WebViewController _controller;
  bool _ready = false;
  ProviderSubscription<EditorState>? _subscription;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription?.close();
    _subscription = ref.listenManual(editorProvider, (prev, next) {
      if (!_ready) return;
      if (prev?.filePath != next.filePath) _loadCurrentFile();
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    // Clear the shared controller reference when this widget is removed.
    ref.read(editorWebViewControllerProvider.notifier).state = null;
    super.dispose();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D1117))
      ..addJavaScriptChannel('VeloxEditor', onMessageReceived: _onMessage)
      ..loadFlutterAsset('assets/monaco/monaco.html');
  }

  void _onMessage(JavaScriptMessage msg) {
    try {
      final json = jsonDecode(msg.message);
      final type = json['type'] as String;
      final notifier = ref.read(editorProvider.notifier);
      if (type == 'ready') {
        setState(() => _ready = true);
        // Publish the controller so other providers can call insertText().
        ref.read(editorWebViewControllerProvider.notifier).state = _controller;
        _loadCurrentFile();
      } else if (type == 'change') {
        notifier.onContentChanged(json['content'] as String);
      } else if (type == 'cursor') {
        notifier.onCursorChanged(json['line'] as int, json['col'] as int);
      }
    } catch (e) {
      // Silently ignore malformed messages
    }
  }

  void _loadCurrentFile() {
    try {
      final state = ref.read(editorProvider);
      if (state.filePath == null) return;
      final contentJson = jsonEncode(state.content);
      final langJson = jsonEncode(state.language);
      _controller.runJavaScript('setContent($contentJson, $langJson)');
    } catch (e) {
      // Handle load errors gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
