import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/file_info/image_file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';

class FileInfo with EquatableMixin {
  final String fileName;
  final String? filePath;
  final Uint8List? bytes;
  final String? customMimeType;

  FileInfo(
    this.fileName, {
    this.filePath,
    this.bytes,
    this.customMimeType,
  });

  factory FileInfo.empty() {
    return FileInfo('');
  }

  int get fileSize {
    if (filePath != null) {
      return File(filePath!).lengthSync();
    } else {
      return bytes?.length ?? 0;
    }
  }

  String get mimeType =>
      customMimeType ?? lookupMimeType(fileName) ?? 'application/octet-stream';

  Map<String, dynamic> get metadata => ({
        'mimetype': mimeType,
        'size': fileSize,
      });

  factory FileInfo.fromMatrixFile(MatrixFile file) {
    if (file.msgType == MessageTypes.Image) {
      return ImageFileInfo(
        file.name,
        bytes: file.bytes,
        width: file.info['w'],
        height: file.info['h'],
        customMimeType: file.mimeType,
      );
    } else if (file.msgType == MessageTypes.Video) {
      return VideoFileInfo(
        file.name,
        bytes: file.bytes,
        imagePlaceholderBytes: Uint8List(0),
        width: file.info['w'],
        height: file.info['h'],
        duration: file.info['duration'] != null && file.info['duration'] is int
            ? Duration(milliseconds: file.info['duration'])
            : null,
        customMimeType: file.mimeType,
      );
    }
    return FileInfo(
      file.name,
      bytes: file.bytes,
      customMimeType: file.mimeType,
    );
  }

  @override
  List<Object?> get props => [fileName, filePath, customMimeType, bytes];
}
