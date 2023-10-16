import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';

extension FileInfoExtension on FileInfo {
  String get fileExtension => fileName.split('.').last;

  String get mimeType =>
      lookupMimeType(kIsWeb ? fileName : filePath) ??
      'application/octet-stream';

  Map<String, dynamic> get metadata => ({
        'mimetype': mimeType,
        'size': fileSize,
      });

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

  FileInfo get detectFileType {
    if (msgType == MessageTypes.Image) {
      return ImageFileInfo(fileName, filePath, fileSize);
    }
    if (msgType == MessageTypes.Video) {
      return VideoFileInfo(fileName, filePath, fileSize);
    }
    return FileInfo(fileName, filePath, fileSize, readStream: readStream);
  }
}
