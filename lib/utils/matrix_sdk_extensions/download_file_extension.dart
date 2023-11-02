import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/storage_directory_utils.dart';
import 'package:matrix/matrix.dart';

extension DownloadFileExtension on Event {
  bool canContainAttachment() {
    return [EventTypes.Message, EventTypes.Sticker].contains(type);
  }

  bool isSending() {
    return status.isSending;
  }

  Uri? getAttachmentOrThumbnailMxcUrl({bool getThumbnail = false}) {
    return attachmentOrThumbnailMxcUrl(getThumbnail: getThumbnail);
  }

  bool isEncryptionDisabled(bool isEncrypted) {
    return isEncrypted && !room.client.encryptionEnabled;
  }

  int getFileSize({bool getThumbnail = false}) {
    return getThumbnail ? thumbnailInfoMap['size'] : infoMap['size'];
  }

  Future<FileInfo?> downloadOrRetrieveAttachment(
    Uri mxcUrl,
    String savePath, {
    ProgressCallback? progressCallback,
    bool getThumbnail = false,
  }) async {
    final database = room.client.database;
    final attachment = await database?.getFileEntity(mxcUrl);

    final mediaApi = getIt.get<MediaAPI>();
    final downloadLink = mxcUrl.getDownloadLink(room.client);

    if (attachment != null) {
      if (await attachment.length() ==
          getFileSize(getThumbnail: getThumbnail)) {
        return FileInfo(
          filename,
          attachment.path,
          getFileSize(getThumbnail: getThumbnail),
        );
      } else {
        await attachment.delete();
      }
    }

    final downloadResponse = await mediaApi.downloadFileInfo(
      uriPath: downloadLink,
      savePath: savePath,
      onReceiveProgress: progressCallback,
    );
    if (downloadResponse.statusCode == 200) {
      return FileInfo(
        filename,
        savePath,
        content.tryGet<int>('size') ?? await File(savePath).length(),
      );
    }
    throw ('getFileInfo: Download file $filename failed');
  }

  // Decrypt the file if it's encrypted.
  Future<FileInfo?> decryptFile(
    FileInfo? fileInfo,
    Uri mxcUrl,
    String decryptedPath, {
    getThumbnail = false,
  }) async {
    final encryptedService = EncryptedService();
    final fileMap = getThumbnail ? infoMap['thumbnail_file'] : content['file'];
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

    return FileInfo(
      body,
      decryptedPath,
      content.tryGet<int>('size') ?? await File(decryptedPath).length(),
    );
  }

  Future<FileInfo?> getFileInfo({
    getThumbnail = false,
    ProgressCallback? progressCallback,
  }) async {
    if (!canContainAttachment()) {
      throw ("getFileInfo: This event has the type '$type' and so it can't contain an attachment.");
    }

    if (isSending()) {
      final localFile = room.sendingFilePlaceholders[eventId];
      if (localFile != null) return FileInfo.fromMatrixFile(localFile);
    }

    final mxcUrl = getAttachmentOrThumbnailMxcUrl(getThumbnail: getThumbnail);
    if (mxcUrl == null) {
      throw "getFileInfo: This event hasn't any attachment or thumbnail.";
    }

    final isFileEncrypted =
        getThumbnail ? isThumbnailEncrypted : isAttachmentEncrypted;
    if (isEncryptionDisabled(isFileEncrypted)) {
      throw ('getFileInfo: Encryption is not enabled in your Client.');
    }

    final tempDirectory =
        await StorageDirectoryUtils.instance.getFileStoreDirectory();
    String? decryptedPath;
    if (isFileEncrypted) {
      decryptedPath =
          '$tempDirectory/${Uri.encodeComponent(mxcUrl.toString())}-decrypted';
      final decryptedFile = File(decryptedPath);

      if (await File(decryptedPath).exists()) {
        final decryptedFileLength = await decryptedFile.length();
        if (decryptedFileLength == getFileSize(getThumbnail: getThumbnail)) {
          return FileInfo(
            body,
            decryptedPath,
            getFileSize(getThumbnail: getThumbnail),
          );
        } else {
          await decryptedFile.delete();
        }
      }
    }

    final fileInfo = await downloadOrRetrieveAttachment(
      mxcUrl,
      '$tempDirectory/${Uri.encodeComponent(mxcUrl.toString())}',
      progressCallback: progressCallback,
      getThumbnail: getThumbnail,
    );

    if (isFileEncrypted && fileInfo != null && decryptedPath != null) {
      return await decryptFile(
        fileInfo,
        mxcUrl,
        decryptedPath,
        getThumbnail: getThumbnail,
      );
    }

    return fileInfo;
  }
}
