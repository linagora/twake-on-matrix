import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/file_info/image_file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:fluffychat/presentation/extensions/uint8list_extension.dart';
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
    if (matrixBytes.isEmpty) {
      throw Exception('FileInfoExtension::toMatrixFile: $fileName is empty');
    }
    int? width, height;
    if (this is ImageFileInfo) {
      width = (this as ImageFileInfo).width;
      height = (this as ImageFileInfo).height;
    } else if (msgType == MessageTypes.Image) {
      final size = await matrixBytes.imageSize;
      width = size?.width.toInt();
      height = size?.height.toInt();
    } else if (this is VideoFileInfo) {
      width = (this as VideoFileInfo).width;
      height = (this as VideoFileInfo).height;
    }
    final videoInfo = this is VideoFileInfo ? this as VideoFileInfo : null;
    return switch (msgType) {
      MessageTypes.Image => MatrixImageFile(
        bytes: matrixBytes,
        name: fileName,
        mimeType: mimeType,
        width: width,
        height: height,
      ),
      MessageTypes.Video => MatrixVideoFile(
        bytes: matrixBytes,
        name: fileName,
        mimeType: mimeType,
        width: width,
        height: height,
        duration: videoInfo?.duration?.inSeconds,
      ),
      _ => MatrixFile(bytes: matrixBytes, name: fileName, mimeType: mimeType),
    };
  }
}
