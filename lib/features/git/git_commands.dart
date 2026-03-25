import 'dart:async';
import 'dart:io';
import 'git_models.dart';

class GitCommands {
  GitCommands();

  Future<String> _execute(String command, {String? workDir}) async {
    try {
      final result = await Process.run(
        'sh',
        ['-c', command],
        workingDirectory: workDir,
        runInShell: false,
      );
      // Return stdout, or stderr if stdout is empty
      return (result.stdout as String).isNotEmpty 
          ? result.stdout as String 
          : result.stderr as String;
    } catch (e) {
      return '';
    }
  }

  /// Get git status in porcelain format
  Future<List<GitFileStatus>> status(String repoPath) async {
    final output = await _execute('git status --porcelain', workDir: repoPath);
    return _parseStatus(output);
  }

  List<GitFileStatus> _parseStatus(String output) {
    if (output.isEmpty) return [];
    
    return output.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
      if (line.length < 3) return null;
      
      final indexStatus = line[0];
      final workTreeStatus = line[1];
      final path = line.substring(3).trim();
      
      // Determine if staged (has index status) and unstaged (has worktree status)
      final isStaged = indexStatus != ' ' && indexStatus != '?';
      final isUnstaged = workTreeStatus != ' ';
      
      GitFileStatusType statusType;
      
      // Use index status for staged, worktree for unstaged
      final statusChar = isStaged ? indexStatus : workTreeStatus;
      statusType = GitFileStatus.fromStatusCode(statusChar);
      
      // Handle untracked files
      if (indexStatus == '?' && workTreeStatus == '?') {
        statusType = GitFileStatusType.untracked;
      }
      
      return GitFileStatus(
        path: path,
        status: statusType,
        isStaged: isStaged,
      );
    }).whereType<GitFileStatus>().toList();
  }

  /// Get commit log
  Future<List<GitCommit>> log(String repoPath, {int limit = 50}) async {
    // Format: hash|shortHash|author|email|timestamp|message
    final output = await _execute(
      'git log --format="%H|%h|%an|%ae|%ct|%s" -n $limit',
      workDir: repoPath,
    );
    return _parseLog(output);
  }

  List<GitCommit> _parseLog(String output) {
    if (output.isEmpty) return [];
    
    final commits = <GitCommit>[];
    for (final line in output.split('\n')) {
      if (line.trim().isEmpty) continue;
      // Remove leading/trailing quotes if present
      final cleanLine = line.replaceAll('"', '');
      try {
        commits.add(GitCommit.fromLogLine(cleanLine));
      } catch (_) {
        // Skip malformed lines
      }
    }
    return commits;
  }

  /// Get diff for a file or all files
  Future<String> diff(String repoPath, {String? file, bool cached = false}) async {
    String cmd = 'git diff';
    if (cached) cmd += ' --cached';
    if (file != null) cmd += ' -- "$file"';
    
    return await _execute(cmd, workDir: repoPath);
  }

  /// Stage a file
  Future<void> add(String repoPath, String file) async {
    await _execute('git add "$file"', workDir: repoPath);
  }

  /// Unstage a file
  Future<void> reset(String repoPath, String file) async {
    await _execute('git reset HEAD -- "$file"', workDir: repoPath);
  }

  /// Commit with message
  Future<bool> commit(String repoPath, String message) async {
    final output = await _execute('git commit -m "$message"', workDir: repoPath);
    return output.isNotEmpty && !output.contains('nothing to commit');
  }

  /// Push to remote
  Future<bool> push(String repoPath) async {
    final output = await _execute('git push', workDir: repoPath);
    return output.isNotEmpty && !output.contains('error');
  }

  /// Pull from remote
  Future<bool> pull(String repoPath) async {
    final output = await _execute('git pull', workDir: repoPath);
    return output.isNotEmpty && !output.contains('error');
  }

  /// Clone repository
  Future<bool> clone(String url, String destPath) async {
    final output = await _execute('git clone "$url" "$destPath"');
    return output.isNotEmpty && !output.contains('error');
  }

  /// Get list of branches
  Future<List<GitBranch>> branches(String repoPath) async {
    final output = await _execute('git branch -a', workDir: repoPath);
    return _parseBranches(output);
  }

  /// Checkout a branch
  Future<bool> checkout(String repoPath, String branch) async {
    final output = await _execute('git checkout "$branch"', workDir: repoPath);
    return output.isNotEmpty && !output.contains('error');
  }

  /// Get current branch name
  Future<String?> currentBranch(String repoPath) async {
    final output = await _execute('git rev-parse --abbrev-ref HEAD', workDir: repoPath);
    return output.trim().isEmpty ? null : output.trim();
  }

  /// Check if directory is a git repo
  Future<bool> isGitRepo(String path) async {
    try {
      final output = await _execute('git rev-parse --git-dir', workDir: path);
      return output.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get remote URL
  Future<String?> remoteUrl(String repoPath) async {
    final output = await _execute('git remote get-url origin', workDir: repoPath);
    return output.trim().isEmpty ? null : output.trim();
  }

  List<GitBranch> _parseBranches(String output) {
    if (output.isEmpty) return [];
    
    return output.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
      return GitBranch.parse(line);
    }).toList();
  }
}