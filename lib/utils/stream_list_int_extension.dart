import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

extension StreamListIntExtension on Stream<List<int>> {
  Future<Uint8List> toUint8List() async {
    // Chunk size for processing the file
    const chunkSize = 1024 * 1024; // 1MB (adjust as needed)

    // Initialize variables
    var byteData = ByteData(chunkSize);
    var length = 0;

    // Iterate over the stream asynchronously
    await for (final chunk in this) {
      final chunkLength = chunk.length;
      var offset = 0;

      while (offset < chunkLength) {
        // Calculate remaining bytes in the chunk
        final remainingBytes = chunkLength - offset;

        // Calculate bytes to copy (either remaining bytes or chunk size, whichever is smaller)
        final bytesToCopy =
            remainingBytes < chunkSize ? remainingBytes : chunkSize;

        // Resize the byteData if necessary
        if (length + bytesToCopy > byteData.lengthInBytes) {
          final newByteData = ByteData(length + bytesToCopy);
          newByteData.buffer
              .asUint8List()
              .setAll(0, byteData.buffer.asUint8List());
          byteData = newByteData;
        }

        // Copy the chunk to byteData
        for (var i = 0; i < bytesToCopy; i++) {
          byteData.setUint8(length++, chunk[offset + i]);
        }

        // Move the offset
        offset += bytesToCopy;
      }
    }

    // Return Uint8List containing the concatenated data
    return Uint8List.view(byteData.buffer, 0, length);
  }

  Future<Uint8List> toBytes() {
    final completer = Completer<Uint8List>();
    final sink = ByteConversionSink.withCallback(
      (bytes) => completer.complete(
        Uint8List.fromList(bytes),
      ),
    );

    late StreamSubscription<List<int>> subscription;
    subscription = listen(
      (val) => sink.add(val),
      onError: (error) {
        completer.completeError(error);
        subscription.cancel();
      },
      onDone: () {
        sink.close();
        subscription.cancel();
      },
      cancelOnError: true,
    );

    return completer.future;
  }
}
