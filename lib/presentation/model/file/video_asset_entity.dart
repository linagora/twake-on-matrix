import 'dart:typed_data';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoAssetEntity extends FileAssetEntity {
  VideoAssetEntity({required super.assetEntity});

  @override
  Future<FileInfo?> toFileInfo() async {
    final file = await assetEntity.loadFile();
    if (file == null) {
      return null;
    }
    return VideoFileInfo(
      file.path.split('/').last,
      filePath: file.path,
      width: assetEntity.orientatedWidth,
      height: assetEntity.orientatedHeight,
      duration: assetEntity.videoDuration,
      imagePlaceholderBytes:
          await assetEntity.thumbnailDataWithSize(
            ThumbnailSize(
              assetEntity.orientatedWidth,
              assetEntity.orientatedHeight,
            ),
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
      width: assetEntity.orientatedWidth,
      height: assetEntity.orientatedHeight,
      duration: assetEntity.videoDuration.inSeconds,
      bytes: await file.readAsBytes(),
    );
  }

  @override
  Future<Uint8List?> get placeholderBytes async =>
      await assetEntity.thumbnailData;

  @override
  String get messageType => MessageTypes.Video;
}
