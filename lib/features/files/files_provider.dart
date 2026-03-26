import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final bool isHidden;

  const FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.isHidden = false,
  });
}

class FilesState {
  final String? rootPath;
  final List<FileItem> items;
  final String? selectedPath;
  final bool isLoading;
  final String? error;

  const FilesState({
    this.rootPath,
    this.items = const [],
    this.selectedPath,
    this.isLoading = false,
    this.error,
  });

  FilesState copyWith({
    String? rootPath,
    List<FileItem>? items,
    String? selectedPath,
    bool? isLoading,
    String? error,
  }) {
    return FilesState(
      rootPath: rootPath ?? this.rootPath,
      items: items ?? this.items,
      selectedPath: selectedPath ?? this.selectedPath,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FilesNotifier extends StateNotifier<FilesState> {
  FilesNotifier() : super(const FilesState()) {
    _loadSavedPath();
  }

  Future<void> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return;

    // Android 13+ (API 33) uses READ_MEDIA_* permissions instead of storage
    // MANAGE_EXTERNAL_STORAGE is needed for full FS access (developer tool)
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) return;

    // On Android 11+ this shows the "Allow all files access" system page.
    // The permission_handler plugin handles the intent automatically.
    final result = await Permission.manageExternalStorage.request();
    if (!result.isGranted) {
      // Fallback: try scoped read permission for basic access
      await Permission.storage.request();
    }
  }

  Future<void> _loadSavedPath() async {
    await _ensureStoragePermission();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('root_path');
    if (saved != null && await Directory(saved).exists()) {
      await loadDirectory(saved);
    }
  }

  Future<void> pickRootDirectory() async {
    await _ensureStoragePermission();
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('root_path', result);
      await loadDirectory(result);
    }
  }

  Future<void> loadDirectory(String path) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        state = state.copyWith(isLoading: false, error: 'Directory not found');
        return;
      }
      final entries = await dir.list().toList();
      final items = <FileItem>[];
      for (final entry in entries) {
        final name = entry.path.split(Platform.pathSeparator).last;
        if (name.startsWith('.')) {
          items.add(FileItem(
            name: name,
            path: entry.path,
            isDirectory: entry is Directory,
            isHidden: true,
          ));
        } else {
          items.add(FileItem(
            name: name,
            path: entry.path,
            isDirectory: entry is Directory,
          ));
        }
      }
      items.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      state = state.copyWith(
        rootPath: path,
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> navigateUp() async {
    if (state.rootPath == null) return;
    final parent = Directory(state.rootPath!).parent.path;
    await loadDirectory(parent);
  }

  Future<void> navigateTo(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      await loadDirectory(path);
    }
  }

  void selectFile(String path) {
    state = state.copyWith(selectedPath: path);
  }

  Future<void> refresh() async {
    if (state.rootPath != null) {
      await loadDirectory(state.rootPath!);
    }
  }
}

final filesProvider = StateNotifierProvider<FilesNotifier, FilesState>(
  (ref) => FilesNotifier(),
);
