import 'dart:typed_data';

import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';
import 'package:video_compress/video_compress.dart';

class VideoAssetEntity extends FileAssetEntity {
  VideoAssetEntity({required super.assetEntity});

  @override
  Future<FileInfo?> toFileInfo() async {
    final file = await assetEntity.loadFile();
    if (file == null) {
      return null;
    }

    // Use VideoCompress.getMediaInfo to read width/height/duration directly
    // from the file path — zero memory overhead, no bytes loaded.
    // Falls back to photo_manager AssetEntity values if the native call fails.
    MediaInfo? mediaInfo;
    try {
      mediaInfo = await VideoCompress.getMediaInfo(file.path);
    } catch (_) {
      // ignore — fallback values used below
    }

    return VideoFileInfo(
      file.path.split('/').last,
      filePath: file.path,
      duration: mediaInfo?.duration != null
          ? Duration(milliseconds: mediaInfo!.duration!.toInt())
          : assetEntity.videoDuration,
      width: mediaInfo?.width,
      height: mediaInfo?.height,
    );
  }

  @override
  Future<Uint8List?> get placeholderBytes async =>
      await assetEntity.thumbnailData;

  @override
  String get messageType => MessageTypes.Video;
}
