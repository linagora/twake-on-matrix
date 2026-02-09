import 'dart:io';

import 'package:fluffychat/presentation/extensions/uint8list_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:matrix/matrix.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

extension SharedMediaFileExtension on SharedMediaFile {
  Future<MatrixFile> toMatrixFile() async {
    final bytes = await File(path).readAsBytes();
    final name = path.split("/").last;
    if (type == SharedMediaType.image) {
      final size = await bytes.imageSize;
      return MatrixImageFile(
        bytes: bytes,
        name: name,
        mimeType: mimeType,
        width: size?.width.toInt(),
        height: size?.height.toInt(),
      );
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
