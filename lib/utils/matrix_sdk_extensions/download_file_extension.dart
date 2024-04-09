import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/media/cancel_exception.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
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
    required StreamController<Either<Failure, Success>>
        downloadStreamController,
    bool getThumbnail = false,
    CancelToken? cancelToken,
  }) async {
    final database = room.client.database;
    final attachment = await database?.getFileEntity(mxcUrl);
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
    try {
      final mediaAPI = getIt<MediaAPI>();
      final downloadResponse = await mediaAPI.downloadFileInfo(
        uriPath: downloadLink,
        savePath: savePath,
        onReceiveProgress: (receive, total) {
          downloadStreamController.add(
            Right(
              DownloadingFileState(
                receive: receive,
                total: total,
              ),
            ),
          );
        },
        cancelToken: cancelToken,
      );
      if (downloadResponse.statusCode == 200) {
        final fileInfo = FileInfo(
          filename,
          savePath,
          content.tryGet<int>('size') ?? await File(savePath).length(),
        );
        await _handleDownloadFileDone(
          this,
          fileInfo,
          downloadStreamController,
          savePath,
        );
        return fileInfo;
      }
      throw ('getFileInfo: Download file $filename failed');
    } catch (e) {
      if (e is CancelRequestException) {
        Logs().i("downloadOrRetrieveAttachment: user cancel the download");
      }
      Logs().e("downloadOrRetrieveAttachment: $e");
    }
    return null;
  }

  Future<void> _handleDownloadFileDone(
    Event event,
    FileInfo fileInfo,
    StreamController<Either<Failure, Success>> streamController,
    String savePath,
  ) async {
    if (event.isAttachmentEncrypted) {
      await _handleEncryptedFileEvent(
        streamController,
        event,
        fileInfo,
        savePath,
      );
    } else {
      streamController.add(
        Right(
          DownloadNativeFileSuccessState(
            filePath: fileInfo.filePath,
          ),
        ),
      );
    }
    return;
  }

  Future<void> _handleEncryptedFileEvent(
    StreamController<Either<Failure, Success>> streamController,
    Event event,
    FileInfo fileInfo,
    String savePath,
  ) async {
    streamController.add(
      const Right(
        DecryptingFileState(),
      ),
    );
    try {
      final decryptedFile = await event.decryptFile(
        fileInfo,
        event.getAttachmentOrThumbnailMxcUrl()!,
        StorageDirectoryUtils.instance.getDecryptedFilePath(savePath: savePath),
      );
      if (decryptedFile == null) {
        throw Exception(
          'DownloadManager::download(): decryptedFile is null',
        );
      }
      final saveFile = File(
        StorageDirectoryUtils.instance.getDecryptedFilePath(
          savePath: savePath,
        ),
      ).copySync(savePath);
      streamController.add(
        Right(
          DownloadNativeFileSuccessState(
            filePath: saveFile.path,
          ),
        ),
      );
    } catch (e) {
      Logs().e(
        'DownloadManager::_handleEncryptedFileEvent(): $e',
      );
      streamController.add(
        Left(
          DownloadFileFailureState(exception: e),
        ),
      );
    }
  }

  Future<FileInfo?> downloadOrRetrieveAttachmentForMedia(
    Uri mxcUrl,
    String savePath, {
    ProgressCallback? progressCallback,
    CancelToken? cancelToken,
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
    try {
      final downloadResponse = await mediaApi.downloadFileInfo(
        uriPath: downloadLink,
        savePath: savePath,
        cancelToken: cancelToken,
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
    } catch (e) {
      if (e is CancelRequestException) {
        Logs().i("downloadOrRetrieveAttachment: user cancel the download");
      }
    }
    return null;
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
    required StreamController<Either<Failure, Success>>
        downloadStreamController,
    CancelToken? cancelToken,
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

    return downloadOrRetrieveAttachment(
      mxcUrl,
      await StorageDirectoryUtils.instance.getFilePathInAppDownloads(
        eventId: eventId,
        fileName: filename,
      ),
      downloadStreamController: downloadStreamController,
      getThumbnail: getThumbnail,
      cancelToken: cancelToken,
    );
  }

  Future<FileInfo?> getMediaFileInfo({
    getThumbnail = false,
    ProgressCallback? progressCallback,
    CancelToken? cancelToken,
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

    String? decryptedPath;
    if (isFileEncrypted) {
      decryptedPath = StorageDirectoryUtils.instance.getDecryptedFilePath(
        savePath: await StorageDirectoryUtils.instance.getMediaFilePath(
          mxcUrl: mxcUrl,
        ),
      );
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

    final fileInfo = await downloadOrRetrieveAttachmentForMedia(
      mxcUrl,
      await StorageDirectoryUtils.instance.getMediaFilePath(mxcUrl: mxcUrl),
      progressCallback: progressCallback,
      getThumbnail: getThumbnail,
      cancelToken: cancelToken,
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
