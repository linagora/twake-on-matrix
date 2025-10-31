import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/file_info/image_file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';

class FileInfo with EquatableMixin {
  final String fileName;
  final int fileSize;
  final Uint8List bytes;
  final Stream<List<int>>? readStream;
  final String? customMimeType;

  FileInfo(
    this.fileName,
    this.fileSize, {
    required this.bytes,
    this.readStream,
    this.customMimeType,
  });

  factory FileInfo.empty() {
    return FileInfo('', 0, bytes: Uint8List.fromList([]));
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
        file.size,
        bytes: file.bytes,
        width: file.info['w'],
        height: file.info['h'],
        customMimeType: file.mimeType,
      );
    } else if (file.msgType == MessageTypes.Video) {
      return VideoFileInfo(
        file.name,
        file.size,
        bytes: file.bytes,
        imagePlaceholderBytes: file.bytes,
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
      file.size,
      bytes: file.bytes,
      customMimeType: file.mimeType,
    );
  }

  @override
  List<Object?> get props => [fileName, fileSize, readStream, bytes];
}
