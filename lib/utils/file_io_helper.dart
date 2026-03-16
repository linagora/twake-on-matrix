import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

/// Persistent background isolate for file I/O operations.
///
/// Spawns a single isolate on first use and reuses it for all subsequent
/// calls, avoiding the ~10-20ms spawn overhead of [compute] per call.
///
/// On web, falls back to regular async I/O since isolates are not available.
class FileIOWorker {
  static final FileIOWorker _instance = FileIOWorker._();
  static FileIOWorker get instance => _instance;
  FileIOWorker._();

  SendPort? _workerPort;
  Isolate? _isolate;

  /// Lazily spawns the worker isolate and returns its [SendPort].
  Future<SendPort> _ensureReady() async {
    if (_workerPort != null) return _workerPort!;

    final readyPort = ReceivePort();
    _isolate = await Isolate.spawn(_workerEntryPoint, readyPort.sendPort);
    _workerPort = await readyPort.first as SendPort;
    readyPort.close();
    return _workerPort!;
  }

  /// Worker isolate entry point. Listens for [_FileIORequest] messages
  /// and processes them synchronously (safe because it's a separate isolate).
  static void _workerEntryPoint(SendPort mainPort) {
    final incoming = ReceivePort();
    mainPort.send(incoming.sendPort);

    incoming.listen((message) {
      if (message is _ReadRequest) {
        try {
          final bytes = File(message.filePath).readAsBytesSync();
          message.replyPort.send(_SuccessResponse(bytes));
        } catch (e) {
          message.replyPort.send(_ErrorResponse(e.toString()));
        }
      } else if (message is _WriteRequest) {
        try {
          final file = File(message.filePath);
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(message.bytes);
          message.replyPort.send(const _SuccessResponse(null));
        } catch (e) {
          message.replyPort.send(_ErrorResponse(e.toString()));
        }
      }
    });
  }

  /// Reads file bytes on the background isolate.
  Future<Uint8List> readFileBytes(String filePath) async {
    if (kIsWeb) {
      return File(filePath).readAsBytes();
    }

    final workerPort = await _ensureReady();
    final responsePort = ReceivePort();
    workerPort.send(_ReadRequest(filePath, responsePort.sendPort));

    final response = await responsePort.first;
    responsePort.close();

    if (response is _ErrorResponse) {
      throw Exception('FileIOWorker read error: ${response.error}');
    }
    return (response as _SuccessResponse).data as Uint8List;
  }

  /// Writes bytes to a file on the background isolate.
  Future<void> writeFileBytes(String filePath, Uint8List bytes) async {
    if (kIsWeb) {
      await File(filePath).writeAsBytes(bytes);
      return;
    }

    final workerPort = await _ensureReady();
    final responsePort = ReceivePort();
    workerPort.send(_WriteRequest(filePath, bytes, responsePort.sendPort));

    final response = await responsePort.first;
    responsePort.close();

    if (response is _ErrorResponse) {
      throw Exception('FileIOWorker write error: ${response.error}');
    }
  }

  /// Shuts down the worker isolate. Mostly useful for testing.
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _workerPort = null;
  }

  /// Static convenience methods matching the old FileIOHelper API.
  static Future<Uint8List> readFile(String filePath) =>
      _instance.readFileBytes(filePath);

  static Future<void> writeFile(String filePath, Uint8List bytes) =>
      _instance.writeFileBytes(filePath, bytes);
}

class _ReadRequest {
  final String filePath;
  final SendPort replyPort;
  const _ReadRequest(this.filePath, this.replyPort);
}

class _WriteRequest {
  final String filePath;
  final Uint8List bytes;
  final SendPort replyPort;
  const _WriteRequest(this.filePath, this.bytes, this.replyPort);
}

class _SuccessResponse {
  final dynamic data;
  const _SuccessResponse(this.data);
}

class _ErrorResponse {
  final String error;
  const _ErrorResponse(this.error);
}
