import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pty_service.dart';

class TerminalState {
  final bool isRunning;
  final List<String> outputBuffer;

  const TerminalState({
    this.isRunning = false,
    this.outputBuffer = const [],
  });

  TerminalState copyWith({bool? isRunning, List<String>? outputBuffer}) {
    return TerminalState(
      isRunning: isRunning ?? this.isRunning,
      outputBuffer: outputBuffer ?? this.outputBuffer,
    );
  }
}

class TerminalNotifier extends StateNotifier<TerminalState> {
  final PtyService _ptyService;

  TerminalNotifier(this._ptyService) : super(const TerminalState());

  Future<void> start() async {
    await _ptyService.start();
    state = state.copyWith(isRunning: true);
  }

  Future<void> write(String input) async {
    await _ptyService.write(input);
  }

  Stream<String> get outputStream => _ptyService.outputStream;

  @override
  void dispose() {
    _ptyService.kill();
    super.dispose();
  }
}

final terminalProvider =
    StateNotifierProvider<TerminalNotifier, TerminalState>((ref) {
  return TerminalNotifier(ref.watch(ptyServiceProvider));
});