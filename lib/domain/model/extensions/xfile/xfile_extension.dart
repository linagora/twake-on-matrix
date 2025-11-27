import 'package:fluffychat/utils/mime_type_uitls.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';

extension XFileExtension on XFile {
  Future<MatrixFile> toMatrixFileOnWeb() async {
    return MatrixFile.fromMimeType(
      bytes: await readAsBytes(),
      name: name,
      mimeType: MimeTypeUitls.instance.getTwakeMimeType(name),
    );
  }
}
