import 'dart:io';

import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

extension DownloadFileExtension on Event {
  Future<FileInfo?> getFileInfo({
    getThumbnail = false,
  }) async {
    if (![EventTypes.Message, EventTypes.Sticker].contains(type)) {
      throw ("getFileInfo: This event has the type '$type' and so it can't contain an attachment.");
    }

    if (status.isSending) {
      final localFile = room.sendingFilePlaceholders[eventId];
      if (localFile != null) return FileInfo.fromMatrixFile(localFile);
    }

    final mxcUrl = attachmentOrThumbnailMxcUrl(getThumbnail: getThumbnail);
    if (mxcUrl == null) {
      throw "getFileInfo: This event hasn't any attachment or thumbnail.";
    }
    final isEncrypted =
        getThumbnail ? isThumbnailEncrypted : isAttachmentEncrypted;
    if (isEncrypted && !room.client.encryptionEnabled) {
      throw ('getFileInfo: Encryption is not enabled in your Client.');
    }
    final tempDirectory = await _getFileStoreDirectory();
    final decryptedPath =
        '$tempDirectory/${Uri.encodeComponent(mxcUrl.toString())}-decrypted';
    if (await File(decryptedPath).exists()) {
      return FileInfo(
        body,
        decryptedPath,
        content.tryGet<int>('size') ?? await File(decryptedPath).length(),
      );
    }

    final database = room.client.database;
    final attachment = await database?.getFileEntity(mxcUrl);
    FileInfo? fileInfo;

    final savePath = '$tempDirectory/${Uri.encodeComponent(mxcUrl.toString())}';
    final mediaApi = getIt.get<MediaAPI>();

    final downloadLink = mxcUrl.getDownloadLink(room.client);
    if (attachment == null) {
      final downloadResponse = await mediaApi.downloadFileInfo(
        uriPath: downloadLink,
        savePath: savePath,
      );
      if (downloadResponse.statusCode == 200) {
        fileInfo = FileInfo(
          filename,
          savePath,
          content.tryGet<int>('size') ?? await File(savePath).length(),
          progressCallback: downloadResponse.onReceiveProgress,
        );
      }
    } else {
      fileInfo = FileInfo(
        filename,
        attachment.path,
        content.tryGet<int>('size') ?? await attachment.length(),
      );
    }

    final encryptedService = EncryptedService();
    // Decrypt the file
    if (isEncrypted) {
      final fileMap =
          getThumbnail ? infoMap['thumbnail_file'] : content['file'];
      if (!fileMap['key']['key_ops'].contains('decrypt')) {
        throw ("getFileInfo: Missing 'decrypt' in 'key_ops'.");
      }
      final encryptedFile = EncryptedFileInfo.fromJson(fileMap);
      if (!await File(decryptedPath).exists()) {
        final isSuccess = await encryptedService.decryptFile(
          fileInfo: fileInfo!,
          encryptedFileInfo: encryptedFile,
          outputFile: File(decryptedPath),
        );

        if (!isSuccess) {
          throw ('getFileInfo: Unable to decrypt file');
        }
      }
      fileInfo = FileInfo(
        body,
        decryptedPath,
        content.tryGet<int>('size') ?? await File(decryptedPath).length(),
        progressCallback: fileInfo?.progressCallback,
      );
    }
    return fileInfo;
  }

  Future<String> _getFileStoreDirectory() async {
    try {
      try {
        return (await getTemporaryDirectory()).path;
      } catch (_) {
        return (await getApplicationDocumentsDirectory()).path;
      }
    } catch (_) {
      return (await getDownloadsDirectory())!.path;
    }
  }
}
