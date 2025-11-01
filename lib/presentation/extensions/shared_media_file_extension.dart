import 'dart:io';
import 'dart:typed_data';

import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

extension SharedMediaFileExtension on SharedMediaFile {
  MatrixFile toMatrixFile() {
    if (type == SharedMediaType.image) {
      return MatrixImageFile(
        bytes: File(path).readAsBytesSync(),
        name: path.split("/").last,
        mimeType: mimeType,
      );
    }
    if (type == SharedMediaType.video) {
      Uint8List? thumbnailBytes;
      if (thumbnail != null) {
        thumbnailBytes = File(thumbnail!).readAsBytesSync();
      }
      return MatrixVideoFile(
        bytes: thumbnailBytes ?? Uint8List(0),
        name: path.split("/").last,
        duration: duration,
        mimeType: mimeType,
      );
    }
    return MatrixFile(
      bytes: File(path).readAsBytesSync(),
      name: path.split("/").last,
      mimeType: mimeType,
    );
  }

  File toFile() {
    return File(
      path,
    );
  }
}
