import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'editor_provider.dart';
import 'editor_webview.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Column(
        children: [
          // Toolbar
          _buildToolbar(context, ref, editorState),
          // Tabs
          _buildTabs(ref, editorState),
          // Editor
          Expanded(
            child: editorState.filePath != null
                ? const EditorWebView()
                : _buildWelcome(),
          ),
          // Status Bar
          _buildStatusBar(editorState),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref, EditorState state) {
    return Container(
      height: 40,
      color: const Color(0xFF161B22),
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.save, size: 18, color: Colors.white70),
            onPressed: state.isDirty
                ? () => ref.read(editorProvider.notifier).saveFile()
                : null,
            tooltip: 'Save',
          ),
          const VerticalDivider(width: 16, color: Colors.white12),
          IconButton(
            icon:
                const Icon(Icons.folder_open, size: 18, color: Colors.white70),
            onPressed: () => _openFile(context, ref),
            tooltip: 'Open File',
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(WidgetRef ref, EditorState state) {
    if (state.openedFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 36,
      color: const Color(0xFF161B22),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.openedFiles.length,
        itemBuilder: (context, index) {
          final path = state.openedFiles[index];
          final name = path.split('/').last;
          final isActive = path == state.filePath;

          return GestureDetector(
            onTap: () => ref.read(editorProvider.notifier).openFile(path),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF0D1117)
                    : const Color(0xFF1C2128),
                border: Border(
                  top: BorderSide(
                    color:
                        isActive ? const Color(0xFF58A6FF) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        ref.read(editorProvider.notifier).closeFile(path),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: isActive ? Colors.white70 : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcome() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.code, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'VELOX Editor',
            style: TextStyle(color: Colors.white54, fontSize: 24),
          ),
          SizedBox(height: 8),
          Text(
            'Open a file to start editing',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(EditorState state) {
    return Container(
      height: 24,
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (state.isDirty)
            const Text(
              '● Modified',
              style: TextStyle(color: Color(0xFF58A6FF), fontSize: 11),
            ),
          const Spacer(),
          if (state.filePath != null) ...[
            Text(
              state.language.toUpperCase(),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(width: 16),
            Text(
              'Ln ${state.cursorLine}, Col ${state.cursorCol}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      await ref
          .read(editorProvider.notifier)
          .openFile(result.files.single.path!);
    }
  }
}
