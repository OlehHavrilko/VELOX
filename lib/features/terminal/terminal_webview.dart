import 'dart:async';
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
  bool _ptyStarted = false;
  StreamSubscription<String>? _outputSub;

  // Approximate glyph dimensions for the default monospace font at 13px.
  static const double _charWidth = 7.8;
  static const double _charHeight = 17.0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _outputSub?.cancel();
    super.dispose();
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
        if (mounted) setState(() => _webViewReady = true);
        _startPty();
      } else if (type == 'input') {
        final data = json['data'] as String;
        ref.read(terminalProvider.notifier).write(data);
      }
    } catch (e) {
      // Silently ignore malformed messages
    }
  }

  Future<void> _startPty() async {
    if (_ptyStarted) return;
    _ptyStarted = true;

    try {
      final notifier = ref.read(terminalProvider.notifier);
      await notifier.start();

      _outputSub = notifier.outputStream.listen(
        (text) {
          if (_webViewReady && mounted) {
            try {
              final bytes = utf8.encode(text);
              final b64 = base64Encode(bytes);
              _controller.runJavaScript("writeBase64('$b64')");
            } catch (e) {
              // Ignore encoding errors
            }
          }
        },
        onError: (error) {
          // Handle stream errors gracefully
        },
      );
    } catch (e) {
      // Handle PTY start errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _onLayoutChanged(constraints);
        return WebViewWidget(controller: _controller);
      },
    );
  }

  void _onLayoutChanged(BoxConstraints constraints) {
    // Skip if the WebView isn't ready or has no valid size yet.
    if (!_webViewReady || constraints.maxWidth <= 0) return;
    final cols = (constraints.maxWidth / _charWidth).floor().clamp(20, 500);
    final rows = (constraints.maxHeight / _charHeight).floor().clamp(5, 200);
    _controller.runJavaScript('resizeTerminal($cols, $rows)');
    ref.read(terminalProvider.notifier).resize(cols, rows);
  }
}
