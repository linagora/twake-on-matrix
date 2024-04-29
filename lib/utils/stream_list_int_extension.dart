import 'dart:typed_data';

extension StreamListIntExtension on Stream<List<int>> {
  Future<Uint8List> toUint8List() async {
    var byteData = ByteData(0);
    var length = 0;

    await for (final chunk in this) {
      final chunkLength = chunk.length;
      final newLength = length + chunkLength;

      if (newLength > byteData.lengthInBytes) {
        final newByteData = ByteData(newLength);

        for (var i = 0; i < length; i++) {
          newByteData.setUint8(i, byteData.getUint8(i));
        }

        byteData = newByteData;
      }

      for (var i = 0; i < chunkLength; i++) {
        byteData.setUint8(length + i, chunk[i]);
      }

      length = newLength;
    }

    return Uint8List.view(byteData.buffer, 0, length);
  }
}
