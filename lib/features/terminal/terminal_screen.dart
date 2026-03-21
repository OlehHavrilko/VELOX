import 'package:flutter/material.dart';
import 'terminal_webview.dart';

class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1117),
      body: SafeArea(
        child: TerminalWebView(),
      ),
    );
  }
}