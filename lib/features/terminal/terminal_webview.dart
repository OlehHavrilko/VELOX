import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'terminal_provider.dart';

class TerminalWebView extends ConsumerStatefulWidget {
  const TerminalWebView({super.key});

  @override
  ConsumerState<TerminalWebView> createState() => _TerminalWebViewState();
}

class _TerminalWebViewState extends ConsumerState<TerminalWebView> {
  late WebViewController _controller;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D1117))
      ..addJavaScriptChannel(
        'VeloxChannel',
        onMessageReceived: _onMessageFromJs,
      )
      ..loadFlutterAsset('assets/xterm/xterm.html');
  }

  void _onMessageFromJs(JavaScriptMessage message) {
    try {
      final json = jsonDecode(message.message);
      final type = json['type'] as String;

      if (type == 'ready') {
        setState(() => _webViewReady = true);
        _startPty();
      } else if (type == 'input') {
        final data = json['data'] as String;
        ref.read(terminalProvider.notifier).write(data);
      }
    } catch (_) {}
  }

  Future<void> _startPty() async {
    final notifier = ref.read(terminalProvider.notifier);
    await notifier.start();

    notifier.outputStream.listen((text) {
      if (_webViewReady) {
        final bytes = utf8.encode(text);
        final b64 = base64Encode(bytes);
        _controller.runJavaScript("writeBase64('$b64')");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
