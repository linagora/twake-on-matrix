import 'dart:io';

import 'package:fluffychat/utils/platform_infos.dart';
import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

extension SharedMediaFileExtension on SharedMediaFile {
  Future<MatrixFile> toMatrixFile() async {
    final bytes = await File(path).readAsBytes();
    final name = path.split("/").last;
    if (type == SharedMediaType.image) {
      return MatrixImageFile(bytes: bytes, name: name, mimeType: mimeType);
    }
    if (type == SharedMediaType.video) {
      return MatrixVideoFile(
        bytes: bytes,
        name: name,
        duration: duration,
        mimeType: mimeType,
      );
    }
    return MatrixFile(bytes: bytes, name: name, mimeType: mimeType);
  }

  File toFile() {
    return File(path);
  }

  bool isAndroidText() {
    return PlatformInfos.isAndroid && type == SharedMediaType.text;
  }

  bool isIOSTextAndUrl() {
    return PlatformInfos.isIOS &&
        (type == SharedMediaType.text || type == SharedMediaType.url);
  }
}
