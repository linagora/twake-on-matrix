import 'dart:io';

import 'package:fluffychat/utils/exception/save_to_gallery_exception.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/storage_directory_utils.dart';
import 'package:matrix/matrix.dart';
import 'package:gal/gal.dart';

mixin SaveMediaToGalleryAndroidMixin {
  Future<File> getFileInDownloadsInAppFolder({
    required File mxcFile,
    required Event downloadEvent,
  }) async {
    final fileNameInAppDownloads =
        await StorageDirectoryUtils.instance.getFilePathInAppDownloads(
      eventId: downloadEvent.eventId,
      fileName: downloadEvent.filename,
    );
    final file = File(fileNameInAppDownloads);

    if (!await file.exists() || await file.length() != await mxcFile.length()) {
      await file.create(recursive: true);
      await mxcFile.copy(fileNameInAppDownloads);
    }
    return file;
  }

  Future<File> getMediaFile(Event event) async {
    if (event.attachmentMxcUrl == null) {
      throw SaveToGalleryException(
        error: 'File not found',
      );
    }
    final filePath = await StorageDirectoryUtils.instance
        .getMediaFilePath(mxcUrl: event.attachmentMxcUrl!);
    return File(filePath);
  }

  Future<void> saveImageToGallery({
    required File file,
  }) async {
    Logs().i('Chat::saveImageToGallery():: file path: ${file.path}');
    await Gal.putImage(
      file.path,
    );
  }

  Future<void> saveVideoToGallery({
    required File file,
  }) async {
    await Gal.putVideo(
      file.path,
    );
  }
}
