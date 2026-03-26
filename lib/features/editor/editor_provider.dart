import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

class EditorState {
  final String? filePath;
  final String content;
  final String language;
  final bool isDirty;
  final int cursorLine;
  final int cursorCol;
  final List<String> openedFiles;
  final Map<String, String> fileContents;
  final Map<String, bool> fileDirtyMap;

  const EditorState({
    this.filePath,
    this.content = '',
    this.language = 'plaintext',
    this.isDirty = false,
    this.cursorLine = 1,
    this.cursorCol = 1,
    this.openedFiles = const [],
    this.fileContents = const {},
    this.fileDirtyMap = const {},
  });

  EditorState copyWith({
    String? filePath,
    String? content,
    String? language,
    bool? isDirty,
    int? cursorLine,
    int? cursorCol,
    List<String>? openedFiles,
    Map<String, String>? fileContents,
    Map<String, bool>? fileDirtyMap,
  }) {
    return EditorState(
      filePath: filePath ?? this.filePath,
      content: content ?? this.content,
      language: language ?? this.language,
      isDirty: isDirty ?? this.isDirty,
      cursorLine: cursorLine ?? this.cursorLine,
      cursorCol: cursorCol ?? this.cursorCol,
      openedFiles: openedFiles ?? this.openedFiles,
      fileContents: fileContents ?? this.fileContents,
      fileDirtyMap: fileDirtyMap ?? this.fileDirtyMap,
    );
  }
}

class EditorNotifier extends Notifier<EditorState> {
  @override
  EditorState build() => const EditorState();

  Future<void> openFile(String path) async {
    // Persist current file's in-memory state before switching tabs.
    final contents = Map<String, String>.from(state.fileContents);
    final dirtyMap = Map<String, bool>.from(state.fileDirtyMap);
    if (state.filePath != null) {
      contents[state.filePath!] = state.content;
      dirtyMap[state.filePath!] = state.isDirty;
    }

    final opened = [...state.openedFiles];
    if (!opened.contains(path)) opened.add(path);

    // Use cached in-memory content when switching to an already-opened tab,
    // otherwise read from disk.
    final String content;
    if (contents.containsKey(path)) {
      content = contents[path]!;
    } else {
      final file = File(path);
      if (!await file.exists()) return;
      content = await file.readAsString();
      contents[path] = content;
    }

    state = state.copyWith(
      filePath: path,
      content: content,
      language: _detectLanguage(path),
      isDirty: dirtyMap[path] ?? false,
      openedFiles: opened,
      fileContents: contents,
      fileDirtyMap: dirtyMap,
    );
  }

  Future<void> saveFile() async {
    if (state.filePath == null) return;
    await File(state.filePath!).writeAsString(state.content);
    final dirtyMap = Map<String, bool>.from(state.fileDirtyMap)
      ..[state.filePath!] = false;
    state = state.copyWith(isDirty: false, fileDirtyMap: dirtyMap);
  }

  void onContentChanged(String content) {
    final contents = Map<String, String>.from(state.fileContents);
    final dirtyMap = Map<String, bool>.from(state.fileDirtyMap);
    if (state.filePath != null) {
      contents[state.filePath!] = content;
      dirtyMap[state.filePath!] = true;
    }
    state = state.copyWith(
      content: content,
      isDirty: true,
      fileContents: contents,
      fileDirtyMap: dirtyMap,
    );
  }

  void onCursorChanged(int line, int col) {
    state = state.copyWith(cursorLine: line, cursorCol: col);
  }

  void closeFile(String path) {
    final opened = state.openedFiles.where((f) => f != path).toList();
    final contents = Map<String, String>.from(state.fileContents)..remove(path);
    final dirtyMap = Map<String, bool>.from(state.fileDirtyMap)..remove(path);
    final newPath = opened.isNotEmpty ? opened.last : null;
    state = state.copyWith(
      filePath: newPath,
      openedFiles: opened,
      fileContents: contents,
      fileDirtyMap: dirtyMap,
    );
    if (newPath != null) openFile(newPath);
  }

  String _detectLanguage(String path) {
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.dart' => 'dart',
      '.kt' || '.kts' => 'kotlin',
      '.py' => 'python',
      '.js' => 'javascript',
      '.ts' => 'typescript',
      '.json' => 'json',
      '.yaml' || '.yml' => 'yaml',
      '.md' => 'markdown',
      '.sh' => 'shell',
      '.html' => 'html',
      '.css' => 'css',
      '.xml' => 'xml',
      '.gradle' => 'kotlin',
      _ => 'plaintext',
    };
  }
}

final editorProvider = NotifierProvider<EditorNotifier, EditorState>(
  EditorNotifier.new,
);

/// Holds the active Monaco WebViewController so other providers (e.g. AI)
/// can call JS methods like insertAtCursor without going through the widget tree.
final editorControllerProvider = StateProvider<WebViewController?>((ref) => null);