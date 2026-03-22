import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'files_provider.dart';

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
            icon: const Icon(Icons.folder_special, size: 18, color: Color(0xFF58A6FF)),
            onPressed: () => ref.read(filesProvider.notifier).pickRootDirectory(),
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
              icon: const Icon(Icons.arrow_upward, size: 18, color: Colors.white70),
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
    String path = '';
    return Container(
      height: 32,
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: parts.length,
        itemBuilder: (context, index) {
          path += (path.isEmpty ? '' : '/') + parts[index];
          return Row(
            children: [
              if (index > 0)
                const Icon(Icons.chevron_right, size: 16, color: Colors.white38),
              InkWell(
                onTap: () => ref.read(filesProvider.notifier).loadDirectory(path),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    parts[index],
                    style: TextStyle(
                      color: index == parts.length - 1 ? Colors.white : Colors.white54,
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
            onPressed: () => ref.read(filesProvider.notifier).pickRootDirectory(),
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
            }
          },
          onDoubleTap: () {
            if (item.isDirectory) {
              ref.read(filesProvider.notifier).navigateTo(item.path);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: isSelected ? const Color(0xFF21262D) : Colors.transparent,
            child: Row(
              children: [
                Icon(
                  item.isDirectory
                      ? Icons.folder
                      : _getFileIcon(item.name),
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
    return switch (ext) {
      'dart' => Icons.code,
      'kt' | 'kts' => Icons.code,
      'py' => Icons.code,
      'js' | 'ts' => Icons.javascript,
      'json' => Icons.data_object,
      'yaml' | 'yml' => Icons.settings,
      'md' => Icons.description,
      'html' | 'css' => Icons.web,
      'xml' => Icons.code,
      'png' | 'jpg' | 'jpeg' | 'gif' | 'svg' => Icons.image,
      'txt' => Icons.text_snippet,
      _ => Icons.insert_drive_file,
    };
  }

  Color _getFileColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' => const Color(0xFF61DAFB),
      'kt' | 'kts' => const Color(0xFFA97BFF),
      'py' => const Color(0xFF3776AB),
      'js' => const Color(0xFFF7DF1E),
      'ts' => const Color(0xFF3178C6),
      'json' => const Color(0xFFCBCB41),
      'yaml' | 'yml' => const Color(0xFFCB171E),
      'md' => const Color(0xFF083FA1),
      'html' => const Color(0xFFE34F26),
      'css' => const Color(0xFF1572B6),
      _ => Colors.white54,
    };
  }
}