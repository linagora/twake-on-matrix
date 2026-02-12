import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/file_info/image_file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';

part 'file_info.g.dart';

@JsonSerializable()
class FileInfo with EquatableMixin {
  final String fileName;
  final String? filePath;
  @JsonKey(includeToJson: false, includeFromJson: false)
  final Uint8List? bytes;
  final String? customMimeType;

  FileInfo(this.fileName, {this.filePath, this.bytes, this.customMimeType});

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

  Map<String, dynamic> get metadata =>
      ({'mimetype': mimeType, 'size': fileSize});

  factory FileInfo.fromMatrixFile(MatrixFile file) {
    if (file.msgType == MessageTypes.Image) {
      final w = file.info['w'];
      final h = file.info['h'];
      return ImageFileInfo(
        file.name,
        bytes: file.bytes,
        width: w is num ? w.toInt() : null,
        height: h is num ? h.toInt() : null,
        customMimeType: file.mimeType,
      );
    } else if (file.msgType == MessageTypes.Video) {
      final w = file.info['w'];
      final h = file.info['h'];
      final duration = file.info['duration'];
      final durationMs = duration is num ? duration.toInt() : null;
      return VideoFileInfo(
        file.name,
        bytes: file.bytes,
        imagePlaceholderBytes: Uint8List(0),
        width: w is num ? w.toInt() : null,
        height: h is num ? h.toInt() : null,
        duration: durationMs != null
            ? Duration(milliseconds: durationMs)
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

  factory FileInfo.fromJson(Map<String, dynamic> json) =>
      _$FileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoToJson(this);

  @override
  List<Object?> get props => [fileName, filePath, customMimeType, bytes];
}
