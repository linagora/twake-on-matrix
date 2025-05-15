import 'dart:io';
import 'dart:typed_data';

import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

extension SharedMediaFileExtension on SharedMediaFile {
  MatrixFile? toMatrixFile() {
    switch (type) {
      case SharedMediaType.text:
      case SharedMediaType.url:
      case SharedMediaType.mailto:
        return null;
      case SharedMediaType.file:
        return MatrixFile(
          bytes: File(path).readAsBytesSync(),
          name: path.split("/").last,
          filePath: path,
          mimeType: mimeType,
        );
      case SharedMediaType.image:
        return MatrixImageFile(
          bytes: null,
          name: path.split("/").last,
          filePath: path,
          mimeType: mimeType,
        );
      case SharedMediaType.video:
        Uint8List? thumbnailBytes;
        if (thumbnail != null) {
          thumbnailBytes = File(thumbnail!).readAsBytesSync();
        }
        return MatrixVideoFile(
          bytes: thumbnailBytes,
          name: path.split("/").last,
          filePath: path,
          duration: duration,
          mimeType: mimeType,
        );
    }
  }

  File toFile() {
    return File(
      path,
    );
  }
}
