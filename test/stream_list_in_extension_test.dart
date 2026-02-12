import 'dart:async';
import 'package:fluffychat/utils/stream_list_int_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

void main() {
  group('Performance test', () {
    Future<void> runPerformanceTest(int dataSize) async {
      const chunkSize = 1024 * 1024; // 1MB
      final numChunks = (dataSize / chunkSize).ceil();
      final dataStream = Stream<List<int>>.fromIterable(
        List.generate(numChunks, (index) {
          final chunk = List<int>.filled(chunkSize, index % 256);
          if (index == numChunks - 1 && dataSize % chunkSize != 0) {
            return chunk.sublist(0, dataSize % chunkSize);
          }
          return chunk;
        }),
      );

      final startTime = DateTime.now();

      final result = await dataStream.toUint8List();

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      expect(result.length, dataSize);

      Logs().d('Processed $dataSize bytes in ${duration.inMilliseconds} ms');
    }

    test('Convert 10KB stream to bytes\n', () async {
      await runPerformanceTest(10 * 1024); // 10KB
    });

    test('Convert 100KB stream to bytes\n', () async {
      await runPerformanceTest(100 * 1024); // 100KB
    });

    test('Convert 300KB stream to bytes\n', () async {
      await runPerformanceTest(300 * 1024); // 300KB
    });

    test('Convert 500KB stream to bytes\n', () async {
      await runPerformanceTest(500 * 1024); // 500KB
    });

    test('Convert 1MB stream to bytes\n', () async {
      await runPerformanceTest(1 * 1024 * 1024); // 1MB
    });

    test('Convert 10MB stream to bytes\n', () async {
      await runPerformanceTest(10 * 1024 * 1024); // 10MB
    });

    test('Convert 30MB stream to bytes\n', () async {
      await runPerformanceTest(30 * 1024 * 1024); // 30MB
    });

    test('Convert 50MB stream to bytes\n', () async {
      await runPerformanceTest(50 * 1024 * 1024); // 50MB
    });

    test('Convert 100MB stream to bytes\n', () async {
      await runPerformanceTest(100 * 1024 * 1024); // 100MB
    });
  });
}
