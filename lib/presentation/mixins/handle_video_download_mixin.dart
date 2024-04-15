import 'package:dio/dio.dart';
import 'package:fluffychat/utils/extension/web_url_creation_extension.dart';
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

  Future<String> handleDownloadVideoEvent({
    required Event event,
    void Function(String uriOrFilePath)? playVideoAction,
    ProgressCallback? progressCallback,
    CancelToken? cancelToken,
  }) async {
    lastSelectedVideoEventId = event.eventId;
    if (PlatformInfos.isWeb) {
      final videoBytes = await event.downloadAndDecryptAttachment();
      final url = videoBytes.bytes?.toWebUrl(mimeType: videoBytes.mimeType);
      if (url == null) {
        throw Exception('$videoBytes is null');
      }
      if (lastSelectedVideoEventId == event.eventId &&
          playVideoAction != null) {
        playVideoAction(url);
      }
      return url;
    } else {
      final videoFile = await event.getFileInfo(
        progressCallback: progressCallback,
        cancelToken: cancelToken,
      );
      if (lastSelectedVideoEventId == event.eventId &&
          playVideoAction != null &&
          videoFile?.filePath != null) {
        playVideoAction(videoFile!.filePath);
      }
      return videoFile?.filePath ?? '';
    }
  }
}
