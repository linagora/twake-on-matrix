import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

extension AssetEntityExtension on AssetEntity {
  Future<MatrixFile?> toMatrixFile() async {
    final bytes = await originBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return MatrixFile(bytes: bytes, name: title ?? await titleAsync);
    }
    return null;
  }
}