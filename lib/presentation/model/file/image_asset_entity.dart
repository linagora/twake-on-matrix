import 'dart:typed_data';

import 'package:fluffychat/presentation/extensions/file_extension.dart';
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
    final imageSize = await file.getImageDimensions();
    return ImageFileInfo(
      file.path.split('/').last,
      filePath: file.path,
      width: imageSize?.width.toInt(),
      height: imageSize?.height.toInt(),
    );
  }

  @override
  Future<Uint8List?> get placeholderBytes async => null;

  @override
  String get messageType => MessageTypes.Image;
}
