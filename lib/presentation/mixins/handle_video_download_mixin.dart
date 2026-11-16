import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:matrix/matrix.dart';

mixin HandleVideoDownloadMixin {
  String? lastSelectedVideoEventId;

  Future<Uint8List?> handleDownloadVideoEvent({
    required Event event,
    void Function(String url)? playVideoActionByUrl,
    ProgressCallback? progressCallback,
    CancelToken? cancelToken,
  }) async {
    lastSelectedVideoEventId = event.eventId;
    final videoFile = await event.getFileInfo(
      progressCallback: progressCallback,
      cancelToken: cancelToken,
      throwOnError: true,
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
