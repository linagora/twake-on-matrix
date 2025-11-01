import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:matrix/matrix.dart';

extension FileInfoExtension on FileInfo {
  String get fileExtension => fileName.split('.').last;

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

  MatrixFile toMatrixFile() {
    return MatrixFile(
      bytes: bytes,
      name: fileName,
      mimeType: mimeType,
    );
  }
}
