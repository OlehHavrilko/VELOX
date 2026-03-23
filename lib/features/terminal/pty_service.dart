import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PtyService {
  static const _methodChannel = MethodChannel('com.velox.app/pty');
  static const _eventChannel = EventChannel('com.velox.app/pty_output');

  Stream<String>? _outputStream;

  Stream<String> get outputStream {
    _outputStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => event.toString());
    return _outputStream!;
  }

  Future<void> start() async {
    await _methodChannel.invokeMethod('startPty');
  }

  Future<void> write(String input) async {
    await _methodChannel.invokeMethod('write', {'input': input});
  }

  Future<void> sendCommand(String command) async {
    await write('$command\n');
  }

  Future<void> resize(int cols, int rows) async {
    await _methodChannel.invokeMethod('resize', {'cols': cols, 'rows': rows});
  }

  Future<void> kill() async {
    await _methodChannel.invokeMethod('kill');
  }
}

final ptyServiceProvider = Provider<PtyService>((ref) => PtyService());