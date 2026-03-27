import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';

import 'settings_data_and_storage_constants.dart';
import 'settings_data_and_storage_scanner_service.dart';

void _isolateScannerEntryPoint(SendPort sendPort) async {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  final String dirPath = await receivePort.first as String;
  receivePort.close();

  final Map<String, int> result = {
    for (final c in StorageCategory.values) c.name: 0,
  };

  try {
    final dir = Directory(dirPath);
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        final int size = entity.lengthSync();
        final StorageCategory category = StorageCategory.fromFile(entity.path);
        result[category.name] = (result[category.name] ?? 0) + size;
      } catch (_) {
        // Swallow: caller catches errors thrown by [scanDirectory] and logs them.
      }
    }
  } catch (_) {
    // Swallow: caller catches errors thrown by [scanDirectory] and logs them.
  }

  sendPort.send(result);
}

Future<Map<StorageCategory, int>> _scanDirectory(String dirPath) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(_isolateScannerEntryPoint, receivePort.sendPort);

  final events = StreamQueue(receivePort);
  final SendPort isolateSendPort = await events.next as SendPort;
  isolateSendPort.send(dirPath);

  // Convert from wire format (String keys) back to typed enum keys.
  final Map<String, int> raw = Map<String, int>.from(await events.next as Map);
  events.cancel();
  receivePort.close();

  return {for (final c in StorageCategory.values) c: raw[c.name] ?? 0};
}

class IsolateStorageScannerService implements StorageScannerService {
  const IsolateStorageScannerService();

  @override
  Future<Map<StorageCategory, int>> scanDirectory(String dirPath) =>
      _scanDirectory(dirPath);
}
