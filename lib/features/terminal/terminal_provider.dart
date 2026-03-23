import 'dart:async' show unawaited;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pty_service.dart';

class TerminalState {
  final bool isRunning;
  final List<String> outputBuffer;
  final String lastCommand;

  const TerminalState({
    this.isRunning = false,
    this.outputBuffer = const [],
    this.lastCommand = '',
  });

  TerminalState copyWith({
    bool? isRunning,
    List<String>? outputBuffer,
    String? lastCommand,
  }) {
    return TerminalState(
      isRunning: isRunning ?? this.isRunning,
      outputBuffer: outputBuffer ?? this.outputBuffer,
      lastCommand: lastCommand ?? this.lastCommand,
    );
  }
}

class TerminalNotifier extends StateNotifier<TerminalState> {
  final PtyService _ptyService;
  StreamSubscription<String>? _outputSub;

  TerminalNotifier(this._ptyService) : super(const TerminalState());

  Future<void> start() async {
    if (state.isRunning) return;

    await _ptyService.start();

    // Subscribe to output stream and fill buffer
    _outputSub = _ptyService.outputStream.listen((text) {
      final lines = [...state.outputBuffer, text];
      // Keep last 200 lines for AI context
      state = state.copyWith(
        isRunning: true,
        outputBuffer: lines.length > 200
            ? lines.sublist(lines.length - 200)
            : lines,
      );
    });

    state = state.copyWith(isRunning: true);
  }

  Future<void> write(String input) async {
    await _ptyService.write(input);
  }

  Future<void> sendCommand(String command) async {
    state = state.copyWith(lastCommand: command);
    await _ptyService.write('$command\n');
  }

  Future<void> resize(int cols, int rows) async {
    await _ptyService.resize(cols, rows);
  }

  Stream<String> get outputStream => _ptyService.outputStream;

  @override
  void dispose() {
    unawaited(_ptyService.kill());
    _outputSub?.cancel();
    super.dispose();
  }
}

final terminalProvider =
    StateNotifierProvider<TerminalNotifier, TerminalState>((ref) {
  return TerminalNotifier(ref.watch(ptyServiceProvider));
});
