import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';

class DefaultAssetEntity extends FileAssetEntity {
  DefaultAssetEntity({
    required super.assetEntity,
  });

  @override
  String get messageType => MessageTypes.File;

  @override
  Future<FileInfo?> toFileInfo() async {
    final file = await assetEntity.loadFile();
    if (file == null) {
      return null;
    }
    return FileInfo(
      file.path.split('/').last,
      file.path,
      file.lengthSync(),
    );
  }

  @override
  Future<MatrixFile?> toMatrixFile() async {
    final file = await assetEntity.loadFile();
    if (file == null) {
      return null;
    }
    return MatrixFile(
      name: file.path.split('/').last,
      filePath: file.path,
    );
  }
}
