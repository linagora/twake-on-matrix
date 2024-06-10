import 'package:fluffychat/utils/mime_type_uitls.dart';
import 'package:matrix/matrix.dart';

extension FileInfoExtension on FileInfo {
  String get fileExtension => fileName.split('.').last;

  String get mimeType => MimeTypeUitls.instance.getTwakeMimeType(filePath);

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
}
