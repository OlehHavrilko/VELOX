import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PtyService {
  static const _methodChannel = MethodChannel('com.velox.app/pty');
  static const _eventChannel = EventChannel('com.velox.app/pty_output');

  Stream<String>? _outputStream;

  Stream<String> get outputStream {
    // Always return the same broadcast stream instance.
    // Reset it when the PTY is restarted via [start].
    _outputStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => event.toString());
    return _outputStream!;
  }

  Future<void> start() async {
    // Reset the cached stream so new listeners get fresh data after a restart.
    _outputStream = null;
    await _methodChannel.invokeMethod('startPty');
  }

  Future<void> write(String input) async {
    try {
      await _methodChannel.invokeMethod('write', {'input': input});
    } catch (_) {
      // Ignore write errors when PTY is not running
    }
  }

  Future<void> sendCommand(String command) async {
    await write('$command\n');
  }

  Future<void> resize(int cols, int rows) async {
    try {
      await _methodChannel.invokeMethod('resize', {'cols': cols, 'rows': rows});
    } catch (_) {}
  }

  Future<void> kill() async {
    try {
      await _methodChannel.invokeMethod('kill');
    } catch (_) {}
    _outputStream = null;
  }
}

final ptyServiceProvider = Provider<PtyService>((ref) => PtyService());