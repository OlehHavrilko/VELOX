import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'editor_provider.dart';

class EditorWebView extends ConsumerStatefulWidget {
  const EditorWebView({super.key});

  @override
  ConsumerState<EditorWebView> createState() => _EditorWebViewState();
}

class _EditorWebViewState extends ConsumerState<EditorWebView> {
  late WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
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
        _loadCurrentFile();
      } else if (type == 'change') {
        notifier.onContentChanged(json['content'] as String);
      } else if (type == 'cursor') {
        notifier.onCursorChanged(json['line'] as int, json['col'] as int);
      }
    } catch (_) {}
  }

  void _loadCurrentFile() {
    final state = ref.read(editorProvider);
    if (state.filePath == null) return;
    final escaped = state.content
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('\$', '\\\$');
    _controller.runJavaScript(
      "setContent(`$escaped`, '${state.language}')",
    );
  }

  @override
  void didUpdateWidget(EditorWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready) _loadCurrentFile();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for file changes and update Monaco
    ref.listen(editorProvider, (prev, next) {
      if (!_ready) return;
      if (prev?.filePath != next.filePath) {
        _loadCurrentFile();
      }
    });
    return WebViewWidget(controller: _controller);
  }
}