import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:matrix/matrix.dart';

extension FileInfoExtension on FileInfo {
  String get fileExtension => fileName.split('.').last;

  String get msgType {
    return msgTypeFromMime(mimeType);
  }

  String msgTypeFromMime(String mimeType) {
    if (mimeType.toLowerCase().startsWith('image/')) {
      return MessageTypes.Image;
    }
    if (mimeType.toLowerCase().startsWith('video/')) {
      return MessageTypes.Video;
    }
    if (mimeType.toLowerCase().startsWith('audio/')) {
      return MessageTypes.Audio;
    }
    return MessageTypes.File;
  }

  Future<MatrixFile> toMatrixFile() async {
    Uint8List matrixBytes = Uint8List(0);
    if (bytes != null) {
      matrixBytes = bytes!;
    } else if (filePath != null) {
      try {
        matrixBytes = await File(filePath!).readAsBytes();
      } catch (e) {
        Logs().e('FileInfoExtension::toMatrixFile: Error reading file', e);
      }
    }
    return switch (msgType) {
      MessageTypes.Image => MatrixImageFile(
        bytes: matrixBytes,
        name: fileName,
        mimeType: mimeType,
      ),
      MessageTypes.Video => MatrixVideoFile(
        bytes: matrixBytes,
        name: fileName,
        mimeType: mimeType,
      ),
      _ => MatrixFile(bytes: matrixBytes, name: fileName, mimeType: mimeType),
    };
  }
}
