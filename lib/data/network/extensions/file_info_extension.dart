import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/domain/model/file_info/image_file_info.dart';
import 'package:twake_chat/domain/model/file_info/video_file_info.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:matrix/matrix.dart';

extension FileInfoExtension on FileInfo {
  String get fileExtension => fileName.split('.').last;

  String get msgType => mimeType.msgTypeFromMime;

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
    }
    if (msgType == MessageTypes.Image && (width == null || height == null)) {
      final size = await _readImageSize(matrixBytes);
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

Future<Size?> _readImageSize(Uint8List bytes) async {
  ImmutableBuffer? buffer;
  ImageDescriptor? descriptor;
  try {
    buffer = await ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ImageDescriptor.encoded(buffer);
    return Size(descriptor.width.toDouble(), descriptor.height.toDouble());
  } catch (e) {
    Logs().e('FileInfoExtension::_readImageSize: Error reading image size', e);
    return null;
  } finally {
    descriptor?.dispose();
    buffer?.dispose();
  }
}
