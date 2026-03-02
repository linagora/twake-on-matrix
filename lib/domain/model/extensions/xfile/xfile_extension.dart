import 'package:fluffychat/presentation/extensions/uint8list_extension.dart';
import 'package:fluffychat/utils/mime_type_uitls.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';

extension XFileExtension on XFile {
  Future<MatrixFile> toMatrixFileOnWeb() async {
    final mime = MimeTypeUitls.instance.getTwakeMimeType(name);
    final msgType = mime.msgTypeFromMime;
    final bytes = await readAsBytes();
    final size = msgType == MessageTypes.Image ? await bytes.imageSize : null;
    return switch (msgType) {
      MessageTypes.Image => MatrixImageFile(
        bytes: bytes,
        name: name,
        mimeType: mime,
        width: size?.width.toInt(),
        height: size?.height.toInt(),
      ),
      _ => MatrixFile.fromMimeType(bytes: bytes, name: name, mimeType: mime),
    };
  }
}
