import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:matrix/matrix.dart';

typedef HandleDownloadVideoEvent = Future<String> Function(
  Event event, {
  void Function(String uriOrFilePath)? playVideoAction,
  ProgressCallback? progressCallback,
});

mixin HandleVideoDownloadMixin {
  String? lastSelectedVideoEventId;

  Future<Uint8List> handleDownloadVideoEvent({
    required Event event,
    void Function(Uint8List bytes)? playVideoAction,
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
    } else {
      final videoFile = await event.getFileInfo(
        progressCallback: progressCallback,
        cancelToken: cancelToken,
      );
      if (lastSelectedVideoEventId == event.eventId &&
          playVideoAction != null &&
          videoFile != null) {
        playVideoAction(videoFile.bytes);
      }
      return videoFile?.bytes ?? Uint8List(0);
    }
  }
}
