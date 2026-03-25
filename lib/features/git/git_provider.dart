import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'git_commands.dart';
import 'git_models.dart';

class GitNotifier extends StateNotifier<GitState> {
  final GitCommands _commands;
  static const _lastRepoKey = 'last_git_repo';

  GitNotifier() : _commands = GitCommands(), super(const GitState()) {
    _loadLastRepo();
  }

  Future<void> _loadLastRepo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPath = prefs.getString(_lastRepoKey);
    if (lastPath != null && await Directory(lastPath).exists()) {
      await openRepo(lastPath);
    }
  }

  Future<void> _saveLastRepo(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRepoKey, path);
  }

  Future<void> openRepo(String path) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isRepo = await _commands.isGitRepo(path);
      if (!isRepo) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not a git repository',
        );
        return;
      }

      final branch = await _commands.currentBranch(path);
      final branches = await _commands.branches(path);
      final commits = await _commands.log(path);
      final files = await _commands.status(path);

      final repoName = path.split('/').last;

      state = state.copyWith(
        repoPath: path,
        repoName: repoName,
        currentBranch: branch,
        branches: branches,
        commits: commits,
        stagedFiles: files.where((f) => f.isStaged).toList(),
        unstagedFiles: files.where((f) => !f.isStaged).toList(),
        isLoading: false,
      );

      await _saveLastRepo(path);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to open repository: $e',
      );
    }
  }

  Future<void> refreshStatus() async {
    if (state.repoPath == null) return;

    try {
      final files = await _commands.status(state.repoPath!);
      state = state.copyWith(
        stagedFiles: files.where((f) => f.isStaged).toList(),
        unstagedFiles: files.where((f) => !f.isStaged).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to refresh status: $e');
    }
  }

  Future<void> stageFile(String path) async {
    if (state.repoPath == null) return;

    try {
      await _commands.add(state.repoPath!, path);
      await refreshStatus();
    } catch (e) {
      state = state.copyWith(error: 'Failed to stage file: $e');
    }
  }

  Future<void> unstageFile(String path) async {
    if (state.repoPath == null) return;

    try {
      await _commands.reset(state.repoPath!, path);
      await refreshStatus();
    } catch (e) {
      state = state.copyWith(error: 'Failed to unstage file: $e');
    }
  }

  Future<bool> commit(String message) async {
    if (state.repoPath == null || message.trim().isEmpty) return false;

    state = state.copyWith(isLoading: true);

    try {
      final success = await _commands.commit(state.repoPath!, message);
      if (success) {
        await refreshStatus();
        final commits = await _commands.log(state.repoPath!);
        state = state.copyWith(
          commits: commits,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Commit failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Commit error: $e',
      );
      return false;
    }
  }

  Future<bool> push() async {
    if (state.repoPath == null) return false;

    state = state.copyWith(isLoading: true);

    try {
      final success = await _commands.push(state.repoPath!);
      state = state.copyWith(isLoading: false, lastOutput: success ? 'Push successful' : 'Push failed');
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Push error: $e',
      );
      return false;
    }
  }

  Future<bool> pull() async {
    if (state.repoPath == null) return false;

    state = state.copyWith(isLoading: true);

    try {
      final success = await _commands.pull(state.repoPath!);
      if (success) {
        await refreshStatus();
        final commits = await _commands.log(state.repoPath!);
        state = state.copyWith(
          commits: commits,
          isLoading: false,
          lastOutput: 'Pull successful',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Pull failed',
        );
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Pull error: $e',
      );
      return false;
    }
  }

  Future<bool> cloneRepo(String url, String destPath) async {
    state = state.copyWith(isLoading: true);

    try {
      final success = await _commands.clone(url, destPath);
      if (success) {
        await openRepo(destPath);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Clone failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Clone error: $e',
      );
      return false;
    }
  }

  Future<void> switchBranch(String branch) async {
    if (state.repoPath == null) return;

    state = state.copyWith(isLoading: true);

    try {
      await _commands.checkout(state.repoPath!, branch);
      final currentBranch = await _commands.currentBranch(state.repoPath!);
      state = state.copyWith(
        currentBranch: currentBranch,
        isLoading: false,
      );
      await refreshStatus();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Checkout error: $e',
      );
    }
  }

  Future<String?> getDiff({String? file, bool cached = false}) async {
    if (state.repoPath == null) return null;

    try {
      return await _commands.diff(
        state.repoPath!,
        file: file,
        cached: cached,
      );
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void closeRepo() {
    state = const GitState();
  }
}

final gitProvider = StateNotifierProvider<GitNotifier, GitState>((ref) {
  return GitNotifier();
});