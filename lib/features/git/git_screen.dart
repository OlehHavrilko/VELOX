import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'git_provider.dart';
import 'git_models.dart';

class GitScreen extends ConsumerStatefulWidget {
  const GitScreen({super.key});

  @override
  ConsumerState<GitScreen> createState() => _GitScreenState();
}

class _GitScreenState extends ConsumerState<GitScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gitProvider);

    ref.listen<GitState>(gitProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade800,
          ),
        );
        ref.read(gitProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Column(
        children: [
          _buildHeader(state),
          _buildTabBar(),
          Expanded(
            child: state.repoPath == null
                ? _buildEmptyState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFilesTab(state),
                      _buildLogTab(state),
                      _buildBranchesTab(state),
                    ],
                  ),
          ),
          if (state.repoPath != null) _buildActionBar(state),
        ],
      ),
    );
  }

  Widget _buildHeader(GitState state) {
    return Container(
      height: 48,
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.merge_type, color: Color(0xFF7C3AED), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.repoName ?? 'Git',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (state.currentBranch != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_tree, size: 14, color: Color(0xFF58A6FF)),
                  const SizedBox(width: 4),
                  Text(
                    state.currentBranch!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.folder_open, size: 20, color: Colors.white54),
            onPressed: _openRepo,
            tooltip: 'Open Repository',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white54),
            onPressed: () => ref.read(gitProvider.notifier).refreshStatus(),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF161B22),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF7C3AED),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(text: 'Files'),
          Tab(text: 'Log'),
          Tab(text: 'Branches'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'No Repository Open',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open a git repository to manage version control',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openRepo,
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Repository'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _cloneRepo,
            icon: const Icon(Icons.download),
            label: const Text('Clone Repository'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF58A6FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesTab(GitState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allFiles = [...state.stagedFiles, ...state.unstagedFiles];

    if (allFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Color(0xFF10B981)),
            SizedBox(height: 16),
            Text(
              'Working tree clean',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: allFiles.length,
      itemBuilder: (context, index) {
        final file = allFiles[index];
        return _buildFileItem(file);
      },
    );
  }

  Widget _buildFileItem(GitFileStatus file) {
    final isStaged = file.isStaged;
    final color = _getStatusColor(file.status);

    return InkWell(
      onTap: () => _showFileActions(file),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF21262D)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                file.displayStatus,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file.path,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                isStaged ? Icons.remove_circle_outline : Icons.add_circle_outline,
                size: 18,
                color: Colors.white38,
              ),
              onPressed: () {
                if (isStaged) {
                  ref.read(gitProvider.notifier).unstageFile(file.path);
                } else {
                  ref.read(gitProvider.notifier).stageFile(file.path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTab(GitState state) {
    if (state.commits.isEmpty) {
      return const Center(
        child: Text(
          'No commits yet',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.commits.length,
      itemBuilder: (context, index) {
        final commit = state.commits[index];
        return _buildCommitItem(commit);
      },
    );
  }

  Widget _buildCommitItem(GitCommit commit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF21262D)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  commit.shortHash,
                  style: const TextStyle(color: Color(0xFF58A6FF), fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                commit.author,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Spacer(),
              Text(
                _formatTime(commit.timestamp),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            commit.message,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBranchesTab(GitState state) {
    if (state.branches.isEmpty) {
      return const Center(
        child: Text(
          'No branches',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.branches.length,
      itemBuilder: (context, index) {
        final branch = state.branches[index];
        return _buildBranchItem(branch, state.currentBranch);
      },
    );
  }

  Widget _buildBranchItem(GitBranch branch, String? currentBranch) {
    final isCurrent = branch.name == currentBranch;

    return InkWell(
      onTap: isCurrent ? null : () => _switchBranch(branch.name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent ? const Color(0xFF21262D) : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: Color(0xFF21262D)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCurrent ? Icons.check_circle : (branch.isRemote ? Icons.cloud : Icons.account_tree),
              size: 18,
              color: isCurrent ? const Color(0xFF10B981) : Colors.white38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                branch.name,
                style: TextStyle(
                  color: isCurrent ? Colors.white : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            if (branch.isRemote)
              const Text(
                'remote',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(GitState state) {
    final hasStagedChanges = state.stagedFiles.isNotEmpty;

    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: state.isLoading ? null : () => ref.read(gitProvider.notifier).pull(),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Pull'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (hasStagedChanges && !state.isLoading) ? () => _showCommitDialog() : null,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Commit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF21262D),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              // Push is always available when a repo is open (push doesn't require staged changes)
              onPressed: state.isLoading ? null : () => ref.read(gitProvider.notifier).push(),
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Push'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(GitFileStatusType status) {
    switch (status) {
      case GitFileStatusType.modified:
        return const Color(0xFF58A6FF);
      case GitFileStatusType.added:
        return const Color(0xFF10B981);
      case GitFileStatusType.deleted:
        return const Color(0xFFF85149);
      case GitFileStatusType.renamed:
        return const Color(0xFFA371F7);
      case GitFileStatusType.untracked:
        return const Color(0xFFF0883E);
      default:
        return Colors.white54;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  Future<void> _openRepo() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      ref.read(gitProvider.notifier).openRepo(result);
    }
  }

  Future<void> _cloneRepo() async {
    final urlController = TextEditingController();
    final pathController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Clone Repository', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Repository URL',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C3AED))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pathController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Destination path',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C3AED))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'url': urlController.text,
              'path': pathController.text,
            }),
            child: const Text('Clone', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );

    urlController.dispose();
    pathController.dispose();

    if (result != null && result['url']!.isNotEmpty && result['path']!.isNotEmpty) {
      ref.read(gitProvider.notifier).cloneRepo(result['url']!, result['path']!);
    }
  }

  Future<void> _showCommitDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Commit Changes', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Commit message',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF7C3AED))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Commit', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result != null && result.trim().isNotEmpty) {
      await ref.read(gitProvider.notifier).commit(result);
    }
  }

  void _showFileActions(GitFileStatus file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: Color(0xFF10B981)),
              title: Text(
                file.isStaged ? 'Unstage' : 'Stage',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                if (file.isStaged) {
                  ref.read(gitProvider.notifier).unstageFile(file.path);
                } else {
                  ref.read(gitProvider.notifier).stageFile(file.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows, color: Color(0xFF58A6FF)),
              title: const Text('View Diff', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show diff
              },
            ),
          ],
        ),
      ),
    );
  }

  void _switchBranch(String branch) {
    ref.read(gitProvider.notifier).switchBranch(branch);
  }
}