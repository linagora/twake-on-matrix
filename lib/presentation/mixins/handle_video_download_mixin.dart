import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:matrix/matrix.dart';

mixin HandleVideoDownloadMixin {
  String? lastSelectedVideoEventId;

  Future<Uint8List?> handleDownloadVideoEvent({
    required Event event,
    void Function(Uint8List bytes)? playVideoAction,
    void Function(String url)? playVideoActionByUrl,
    ProgressCallback? progressCallback,
    CancelToken? cancelToken,
  }) async {
    lastSelectedVideoEventId = event.eventId;
    if (PlatformInfos.isWeb) {
      final videoBytes = await event.downloadAndDecryptAttachment();

      if (lastSelectedVideoEventId == event.eventId &&
          playVideoAction != null) {
        playVideoAction(videoBytes.bytes);
      }
      return videoBytes.bytes;
    }

    final videoFile = await event.getFileInfo(
      progressCallback: progressCallback,
      cancelToken: cancelToken,
    );
    if (lastSelectedVideoEventId != event.eventId) {
      return null;
    }

    if (videoFile?.filePath == null) {
      return null;
    }

    final fileUri = Uri.file(videoFile!.filePath!).toString();
    playVideoActionByUrl?.call(fileUri);
    return null;
  }
}
