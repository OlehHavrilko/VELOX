import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class EditorState {
  final String? filePath;
  final String content;
  final String language;
  final bool isDirty;
  final int cursorLine;
  final int cursorCol;
  final List<String> openedFiles;

  const EditorState({
    this.filePath,
    this.content = '',
    this.language = 'plaintext',
    this.isDirty = false,
    this.cursorLine = 1,
    this.cursorCol = 1,
    this.openedFiles = const [],
  });

  EditorState copyWith({
    Object? filePath = _sentinel,
    String? content,
    String? language,
    bool? isDirty,
    int? cursorLine,
    int? cursorCol,
    List<String>? openedFiles,
  }) {
    return EditorState(
      filePath: filePath == _sentinel ? this.filePath : filePath as String?,
      content: content ?? this.content,
      language: language ?? this.language,
      isDirty: isDirty ?? this.isDirty,
      cursorLine: cursorLine ?? this.cursorLine,
      cursorCol: cursorCol ?? this.cursorCol,
      openedFiles: openedFiles ?? this.openedFiles,
    );
  }
}

const Object _sentinel = Object();

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  Future<void> openFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return;
    final content = await file.readAsString();
    final lang = _detectLanguage(path);
    final opened = [...state.openedFiles];
    if (!opened.contains(path)) opened.add(path);
    state = state.copyWith(
      filePath: path,
      content: content,
      language: lang,
      isDirty: false,
      openedFiles: opened,
    );
  }

  Future<void> saveFile() async {
    if (state.filePath == null) return;
    await File(state.filePath!).writeAsString(state.content);
    state = state.copyWith(isDirty: false);
  }

  void onContentChanged(String content) {
    state = state.copyWith(content: content, isDirty: true);
  }

  void onCursorChanged(int line, int col) {
    state = state.copyWith(cursorLine: line, cursorCol: col);
  }

  void closeFile(String path) {
    final opened = state.openedFiles.where((f) => f != path).toList();
    if (opened.isEmpty) {
      state = state.copyWith(
        filePath: null,
        content: '',
        isDirty: false,
        openedFiles: [],
      );
      return;
    }
    final newPath = opened.last;
    state = state.copyWith(openedFiles: opened);
    openFile(newPath);
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

final editorProvider =
    StateNotifierProvider<EditorNotifier, EditorState>(
  (ref) => EditorNotifier(),
);