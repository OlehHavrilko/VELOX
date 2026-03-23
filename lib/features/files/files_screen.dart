import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'files_provider.dart';
import '../editor/editor_provider.dart';

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Column(
        children: [
          _buildHeader(ref, state),
          _buildBreadcrumb(ref, state),
          Expanded(
            child: state.rootPath == null
                ? _buildEmpty(ref)
                : state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildFileList(ref, state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, FilesState state) {
    return Container(
      height: 40,
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.folder_special,
                size: 18, color: Color(0xFF58A6FF)),
            onPressed: () =>
                ref.read(filesProvider.notifier).pickRootDirectory(),
            tooltip: 'Open Folder',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
            onPressed: () => ref.read(filesProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
          const Spacer(),
          if (state.rootPath != null)
            IconButton(
              icon: const Icon(Icons.arrow_upward,
                  size: 18, color: Colors.white70),
              onPressed: () => ref.read(filesProvider.notifier).navigateUp(),
              tooltip: 'Go Up',
            ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(WidgetRef ref, FilesState state) {
    if (state.rootPath == null) return const SizedBox.shrink();

    final parts = state.rootPath!.split('/');
    return Container(
      height: 32,
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: parts.length,
        itemBuilder: (context, index) {
          final currentPath = '/' + parts.sublist(1, index + 1).join('/');
          return Row(
            children: [
              if (index > 0)
                const Icon(Icons.chevron_right,
                    size: 16, color: Colors.white38),
              InkWell(
                onTap: () =>
                    ref.read(filesProvider.notifier).loadDirectory(currentPath),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    parts[index],
                    style: TextStyle(
                      color: index == parts.length - 1
                          ? Colors.white
                          : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'No Folder Open',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open a folder to browse files',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(filesProvider.notifier).pickRootDirectory(),
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Folder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF238636),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(WidgetRef ref, FilesState state) {
    return ListView.builder(
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        final isSelected = item.path == state.selectedPath;

        return InkWell(
          onTap: () {
            ref.read(filesProvider.notifier).selectFile(item.path);
            if (item.isDirectory) {
              ref.read(filesProvider.notifier).navigateTo(item.path);
            } else {
              ref.read(editorProvider.notifier).openFile(item.path);
              context.go('/editor');
            }
          },
          onDoubleTap: () {
            if (item.isDirectory) {
              ref.read(filesProvider.notifier).navigateTo(item.path);
            } else {
              ref.read(editorProvider.notifier).openFile(item.path);
              context.go('/editor');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: isSelected ? const Color(0xFF21262D) : Colors.transparent,
            child: Row(
              children: [
                Icon(
                  item.isDirectory ? Icons.folder : _getFileIcon(item.name),
                  size: 16,
                  color: item.isDirectory
                      ? const Color(0xFF58A6FF)
                      : _getFileColor(item.name),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: item.isHidden ? Colors.white38 : Colors.white70,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
        return Icons.code;
      case 'kt':
      case 'kts':
        return Icons.code;
      case 'py':
        return Icons.code;
      case 'js':
      case 'ts':
        return Icons.javascript;
      case 'json':
        return Icons.data_object;
      case 'yaml':
      case 'yml':
        return Icons.settings;
      case 'md':
        return Icons.description;
      case 'html':
      case 'css':
        return Icons.web;
      case 'xml':
        return Icons.code;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'svg':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'dart':
        return const Color(0xFF61DAFB);
      case 'kt':
      case 'kts':
        return const Color(0xFFA97BFF);
      case 'py':
        return const Color(0xFF3776AB);
      case 'js':
        return const Color(0xFFF7DF1E);
      case 'ts':
        return const Color(0xFF3178C6);
      case 'json':
        return const Color(0xFFCBCB41);
      case 'yaml':
      case 'yml':
        return const Color(0xFFCB171E);
      case 'md':
        return const Color(0xFF083FA1);
      case 'html':
        return const Color(0xFFE34F26);
      case 'css':
        return const Color(0xFF1572B6);
      default:
        return Colors.white54;
    }
  }
}
