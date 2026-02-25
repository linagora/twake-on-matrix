import 'dart:typed_data';

import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';

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
      duration: assetEntity.videoDuration,
    );
  }

  @override
  Future<Uint8List?> get placeholderBytes async =>
      await assetEntity.thumbnailData;

  @override
  String get messageType => MessageTypes.Video;
}
