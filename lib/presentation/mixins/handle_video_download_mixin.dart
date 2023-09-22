import 'dart:io';

import 'package:fluffychat/utils/extension/web_url_creation_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

mixin HandleVideoDownloadMixin {
  String? lastSelectedVideoEventId;

  Future<String> handleDownloadVideoEvent({
    required Event event,
    void Function(String uriOrFilePath)? playVideoAction,
  }) async {
    lastSelectedVideoEventId = event.eventId;
    final videoFile = await event.downloadAndDecryptAttachment();
    if (PlatformInfos.isWeb) {
      final url = videoFile.bytes?.toWebUrl();
      if (url == null) {
        throw Exception('$videoFile is null');
      }
      if (lastSelectedVideoEventId == event.eventId &&
          playVideoAction != null) {
        playVideoAction(url);
      }
      return url;
    } else {
      final tempDir = await getTemporaryDirectory();
      final fileName = Uri.encodeComponent(
        event.attachmentOrThumbnailMxcUrl()!.pathSegments.last,
      );
      final file = File('${tempDir.path}/${fileName}_${videoFile.name}');
      if (await file.exists() == false && videoFile.bytes != null) {
        await file.writeAsBytes(videoFile.bytes!);
      }
      if (lastSelectedVideoEventId == event.eventId &&
          playVideoAction != null) {
        playVideoAction(file.path);
      }
      return file.path;
    }
  }
}
