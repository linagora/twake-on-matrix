import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/config/app_constants.dart';
import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

extension SharedMediaFileExtension on SharedMediaFile {
  MatrixFile toMatrixFile() {
    if (type == SharedMediaType.image) {
      return MatrixImageFile(
        bytes: null,
        name: path.split("/").last,
        filePath: path,
        mimeType: mimeType,
      );
    }
    if (type == SharedMediaType.video) {
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
    return MatrixFile(
      bytes: File(path).readAsBytesSync(),
      name: path.split("/").last,
      filePath: path,
      mimeType: mimeType,
    );
  }

  File toFile() {
    return File(
      path,
    );
  }

  bool isNotAFile() {
    final uri = Uri.tryParse(path);
    return uri?.host == AppConstants.appLinkUniversalLinkDomain;
  }
}
