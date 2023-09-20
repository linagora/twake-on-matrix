import 'dart:typed_data';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoAssetEntity extends FileAssetEntity {
  VideoAssetEntity({
    required super.assetEntity,
  });

  @override
  Future<FileInfo?> toFileInfo() async {
    final file = await assetEntity.loadFile();
    if (file == null) {
      return null;
    }
    return VideoFileInfo(
      file.path.split('/').last,
      file.path,
      file.lengthSync(),
      width: assetEntity.width,
      height: assetEntity.height,
      duration: assetEntity.videoDuration,
      imagePlaceholderBytes: await assetEntity.thumbnailDataWithSize(
            ThumbnailSize(assetEntity.width, assetEntity.height),
            quality: AppConfig.thumbnailQuality,
          ) ??
          Uint8List(0),
    );
  }

  @override
  Future<MatrixFile?> toMatrixFile() async {
    final file = await assetEntity.loadFile();
    if (file == null) {
      return null;
    }
    return MatrixVideoFile(
      name: file.path.split('/').last,
      filePath: file.path,
      width: assetEntity.orientatedWidth,
      height: assetEntity.orientatedHeight,
      duration: assetEntity.videoDuration.inSeconds,
      bytes: await assetEntity.thumbnailData,
    );
  }

  @override
  Future<Uint8List?> get placeholderBytes async =>
      await assetEntity.thumbnailData;

  @override
  String get messageType => MessageTypes.Video;
}
