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
      Uint8List resultBytes = Uint8List(0);
      final videoFile = await event.getFileInfo(
        progressCallback: progressCallback,
        cancelToken: cancelToken,
      );
      if (lastSelectedVideoEventId == event.eventId && videoFile != null) {
        Uint8List? bytes;
        if (videoFile.bytes != null) {
          bytes = videoFile.bytes;
        } else if (videoFile.filePath != null) {
          try {
            bytes = await File(videoFile.filePath!).readAsBytes();
          } catch (e) {
            Logs().e('HandleVideoDownloadMixin::Error reading file', e);
          }
        }
        if (bytes != null) {
          playVideoAction?.call(bytes);
          resultBytes = bytes;
        }
      }
      return resultBytes;
    }
  }
}
