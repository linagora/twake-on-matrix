import 'package:fluffychat/presentation/model/image_type.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

extension AssetEntityExtension on AssetEntity {
  Future<MatrixFile?> toMatrixFile() async {
    if (await isHEICImageFile) {
      final bytes = await (await file)?.readAsBytes();
      if (bytes != null && bytes.isNotEmpty) {
        return MatrixImageFile(bytes: bytes, name: title ?? await titleAsync);
      }
    }
    final bytes = await originBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return MatrixImageFile(
        bytes: bytes,
        name: title ?? await titleAsync,
        mimeType: await mimeTypeAsync,
      );
    }
    return null;
  }

  Future<bool> get isHEICImageFile async {
    return await mimeTypeAsync == ImageType.heic.name;
  }
}
