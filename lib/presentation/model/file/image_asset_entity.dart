import 'dart:typed_data';

import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/file_info/image_file_info.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';

class ImageAssetEntity extends FileAssetEntity {
  ImageAssetEntity({required super.assetEntity});

  @override
  Future<FileInfo?> toFileInfo() async {
    final file = await assetEntity.loadFile();
    if (file == null) {
      return null;
    }
    return ImageFileInfo(
      file.path.split('/').last,
      filePath: file.path,
      width: assetEntity.orientatedWidth,
      height: assetEntity.orientatedHeight,
    );
  }

  @override
  Future<MatrixFile?> toMatrixFile() async {
    final file = await assetEntity.loadFile();
    if (file == null) {
      return null;
    }
    return MatrixImageFile(
      name: file.path.split('/').last,
      bytes: file.readAsBytesSync(),
      width: assetEntity.orientatedWidth,
      height: assetEntity.orientatedHeight,
    );
  }

  @override
  Future<Uint8List?> get placeholderBytes async => null;

  @override
  String get messageType => MessageTypes.Image;
}
