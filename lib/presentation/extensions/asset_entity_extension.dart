import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

extension AssetEntityExtension on AssetEntity {
  Future<MatrixFile?> toMatrixFile() async {
    final file = await loadFile();
    if (file != null) {
      return MatrixImageFile(
        bytes: file.readAsBytesSync(),
        name: title ?? await titleAsync,
        mimeType: await mimeTypeAsync,
      );
    }
    return null;
  }
}
