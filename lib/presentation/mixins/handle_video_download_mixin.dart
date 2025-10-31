import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:matrix/matrix.dart';

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
        Uint8List? bytes;
        if (videoFile.bytes != null) {
          bytes = videoFile.bytes;
        } else if (videoFile.filePath != null) {
          bytes = await File(videoFile.filePath!).readAsBytes();
        }
        if (bytes != null) {
          playVideoAction(bytes);
        }
      }
      return videoFile?.bytes ?? Uint8List(0);
    }
  }
}
