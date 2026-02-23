import 'dart:io';
import 'dart:typed_data';

import 'package:fluffychat/domain/model/extensions/file_extension.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:fluffychat/presentation/extensions/uint8list_extension.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoAssetEntity extends FileAssetEntity {
  VideoAssetEntity({required super.assetEntity});

  @override
  Future<FileInfo?> toFileInfo() async {
    final file = await assetEntity.loadFile();
    if (file == null) {
      return null;
    }
    final tempDir = await getTemporaryDirectory();
    final thumbnailFile = await VideoThumbnail.thumbnailFile(
      video: file.path,
      thumbnailPath: tempDir.path,
    );
    final thumbnailSize = await File(thumbnailFile.path).getImageDimensions();
    return VideoFileInfo(
      file.path.split('/').last,
      filePath: file.path,
      width: thumbnailSize?.width.toInt(),
      height: thumbnailSize?.height.toInt(),
      duration: assetEntity.videoDuration,
      imagePlaceholderBytes: await thumbnailFile.readAsBytes(),
    );
  }

  @override
  Future<MatrixFile?> toMatrixFile() async {
    final file = await assetEntity.loadFile();
    if (file == null) {
      return null;
    }
    final thumbnailData = await VideoThumbnail.thumbnailData(video: file.path);
    final thumbnailSize = await thumbnailData.imageSize;
    return MatrixVideoFile(
      name: file.path.split('/').last,
      width: thumbnailSize?.width.toInt(),
      height: thumbnailSize?.height.toInt(),
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
