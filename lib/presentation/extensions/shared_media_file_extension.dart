import 'dart:io';
import 'dart:typed_data';

import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

extension SharedMediaFileExtension on SharedMediaFile {
  MatrixFile toMatrixFile() {
    if (type == SharedMediaType.IMAGE) {
      return MatrixImageFile(
        bytes: null,
        name: path.split("/").last,
        filePath: path,
      );
    }
    if (type == SharedMediaType.VIDEO) {
      Uint8List? thumbnailBytes;
      if (thumbnail != null) {
        thumbnailBytes = File(thumbnail!).readAsBytesSync();
      }
      return MatrixVideoFile(
        bytes: thumbnailBytes,
        name: path.split("/").last,
        filePath: path,
        duration: duration,
      );
    }
    return MatrixFile(
      bytes: null,
      name: path.split("/").last,
      filePath: path,
    );
  }
}
