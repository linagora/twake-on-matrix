import 'dart:typed_data';

import 'package:fluffychat/utils/stream_list_int_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Stream<List<int>> to Uint8List conversion tests', () {
    test('Empty stream results in empty Uint8List', () async {
      const stream = Stream<List<int>>.empty();
      final result = await stream.toUint8List();
      expect(result, equals(Uint8List(0)));
    });

    test('Single chunk stream is correctly converted', () async {
      final stream = Stream.fromIterable([
        [10, 20, 30, 40, 50],
      ]);
      final expectedOutput = Uint8List.fromList([10, 20, 30, 40, 50]);
      final result = await stream.toUint8List();
      expect(result, equals(expectedOutput));
    });

    test('Multiple chunks stream is correctly concatenated', () async {
      final stream = Stream.fromIterable([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
      ]);
      final expectedOutput = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9]);
      final result = await stream.toUint8List();
      expect(result, equals(expectedOutput));
    });

    test('Stream with varying chunk sizes is correctly processed', () async {
      final stream = Stream.fromIterable([
        [100],
        [200, 201],
        [300, 301, 302],
      ]);
      final expectedOutput = Uint8List.fromList([100, 200, 201, 300, 301, 302]);
      final result = await stream.toUint8List();
      expect(result, equals(expectedOutput));
    });

    test('Large data set is correctly processed', () async {
      // Generating a large data set
      final largeDataSet = List.generate(
        10,
        (index) => List.filled(1024 * 1024, index % 256),
      );
      final stream = Stream.fromIterable(largeDataSet);
      final result = await stream.toUint8List();

      // Verifying the size of the result matches the expected size
      const expectedSize = 10 * 1024 * 1024; // 10 chunks of 1MB each
      expect(result.lengthInBytes, equals(expectedSize));

      // Optionally, verify some contents
      expect(result[0], equals(0)); // First byte of the first chunk
      expect(
        result[1024 * 1024 - 1],
        equals(0),
      ); // Last byte of the first chunk
      expect(result[1024 * 1024], equals(1)); // First byte of the second chunk
    });
  });
}
