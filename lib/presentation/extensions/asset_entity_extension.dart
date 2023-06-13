import 'package:linagora_design_flutter/images_picker/images_picker.dart';
import 'package:matrix/matrix.dart';

extension AssetEntityExtension on IndexedAssetEntity {
  Future<MatrixFile?> toMatrixFile() async {
    final bytes = await asset.originBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return MatrixFile(bytes: bytes, name: await asset.titleAsync);
    }
    return null;
  }
}