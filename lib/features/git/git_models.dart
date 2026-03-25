enum GitFileStatusType {
  modified,
  added,
  deleted,
  renamed,
  copied,
  untracked,
  ignored,
  unmerged,
}

class GitFileStatus {
  final String path;
  final GitFileStatusType status;
  final bool isStaged;
  final String? originalPath;

  const GitFileStatus({
    required this.path,
    required this.status,
    this.isStaged = false,
    this.originalPath,
  });

  String get displayStatus {
    switch (status) {
      case GitFileStatusType.modified:
        return 'M';
      case GitFileStatusType.added:
        return 'A';
      case GitFileStatusType.deleted:
        return 'D';
      case GitFileStatusType.renamed:
        return 'R';
      case GitFileStatusType.copied:
        return 'C';
      case GitFileStatusType.untracked:
        return '?';
      case GitFileStatusType.ignored:
        return '!';
      case GitFileStatusType.unmerged:
        return 'U';
    }
  }

  static GitFileStatusType fromStatusCode(String code) {
    switch (code) {
      case 'M':
        return GitFileStatusType.modified;
      case 'A':
        return GitFileStatusType.added;
      case 'D':
        return GitFileStatusType.deleted;
      case 'R':
        return GitFileStatusType.renamed;
      case 'C':
        return GitFileStatusType.copied;
      case '?':
        return GitFileStatusType.untracked;
      case '!':
        return GitFileStatusType.ignored;
      case 'U':
        return GitFileStatusType.unmerged;
      default:
        return GitFileStatusType.modified;
    }
  }
}

class GitCommit {
  final String hash;
  final String shortHash;
  final String message;
  final String author;
  final String authorEmail;
  final DateTime timestamp;

  const GitCommit({
    required this.hash,
    required this.shortHash,
    required this.message,
    required this.author,
    required this.authorEmail,
    required this.timestamp,
  });

  factory GitCommit.fromLogLine(String line) {
    // Format: hash|shortHash|author|timestamp|message
    final parts = line.split('|');
    if (parts.length < 5) {
      throw FormatException('Invalid git log line: $line');
    }
    return GitCommit(
      hash: parts[0],
      shortHash: parts[1],
      author: parts[2],
      authorEmail: parts[3],
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[4]) * 1000),
      message: parts.sublist(5).join('|'),
    );
  }
}

class GitBranch {
  final String name;
  final bool isCurrent;
  final bool isRemote;
  final String? trackingBranch;

  const GitBranch({
    required this.name,
    this.isCurrent = false,
    this.isRemote = false,
    this.trackingBranch,
  });

  factory GitBranch.parse(String line) {
    final isCurrent = line.startsWith('*');
    final cleanLine = line.replaceFirst('* ', ' ').trim();
    final isRemote = cleanLine.contains('remotes/');
    
    String name = cleanLine;
    if (name.startsWith('remotes/')) {
      name = name.substring('remotes/'.length);
    }
    
    return GitBranch(
      name: name,
      isCurrent: isCurrent,
      isRemote: isRemote,
    );
  }
}

class GitState {
  final String? repoPath;
  final String? repoName;
  final List<GitFileStatus> stagedFiles;
  final List<GitFileStatus> unstagedFiles;
  final List<GitCommit> commits;
  final List<GitBranch> branches;
  final String? currentBranch;
  final bool isLoading;
  final String? error;
  final String? lastOutput;

  const GitState({
    this.repoPath,
    this.repoName,
    this.stagedFiles = const [],
    this.unstagedFiles = const [],
    this.commits = const [],
    this.branches = const [],
    this.currentBranch,
    this.isLoading = false,
    this.error,
    this.lastOutput,
  });

  GitState copyWith({
    String? repoPath,
    String? repoName,
    List<GitFileStatus>? stagedFiles,
    List<GitFileStatus>? unstagedFiles,
    List<GitCommit>? commits,
    List<GitBranch>? branches,
    String? currentBranch,
    bool? isLoading,
    String? error,
    String? lastOutput,
  }) {
    return GitState(
      repoPath: repoPath ?? this.repoPath,
      repoName: repoName ?? this.repoName,
      stagedFiles: stagedFiles ?? this.stagedFiles,
      unstagedFiles: unstagedFiles ?? this.unstagedFiles,
      commits: commits ?? this.commits,
      branches: branches ?? this.branches,
      currentBranch: currentBranch ?? this.currentBranch,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastOutput: lastOutput,
    );
  }

  bool get hasChanges => stagedFiles.isNotEmpty || unstagedFiles.isNotEmpty;
  int get totalChanges => stagedFiles.length + unstagedFiles.length;
}