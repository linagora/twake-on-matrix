import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/exception/dio_duplicate_download_exception.dart';
import 'package:fluffychat/data/network/media/cancel_exception.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/storage_directory_manager.dart';
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
    required StreamController<Either<Failure, Success>>?
        downloadStreamController,
    ProgressCallback? progressCallback,
    bool getThumbnail = false,
    CancelToken? cancelToken,
    required String filename,
  }) async {
    final attachment = File(
      await StorageDirectoryManager.instance.getFilePathInAppDownloads(
        eventId: eventId,
        fileName: filename,
      ),
    );
    final downloadLink = mxcUrl.getDownloadLink(room.client);

    if (await attachment.exists()) {
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
          progressCallback?.call(receive, total);
          downloadStreamController?.add(
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
      if (downloadResponse.statusCode == 200 &&
          await File(savePath).exists() &&
          await File(savePath).length() ==
              getFileSize(getThumbnail: getThumbnail)) {
        final fileInfo = FileInfo(
          filename,
          savePath,
          content.tryGet<int>('size') ?? await File(savePath).length(),
        );
        await _handleDownloadFileDone(
          mxcUrl: mxcUrl,
          fileInfo: fileInfo,
          savePath: savePath,
          filename: filename,
          streamController: downloadStreamController,
          getThumbnail: getThumbnail,
        );
        return fileInfo;
      }
      throw ('getFileInfo: Download file $filename failed');
    } catch (e) {
      if (e is CancelRequestException) {
        Logs().i("downloadOrRetrieveAttachment: user cancel the download");
      } else if (e is DioDuplicateDownloadException) {
        Logs().i("downloadOrRetrieveAttachment: duplicate request");
      } else {
        Logs().e("downloadOrRetrieveAttachment: $e");
        downloadStreamController?.add(
          Left(
            DownloadFileFailureState(exception: e),
          ),
        );
      }
    }
    return null;
  }

  Future<void> _handleDownloadFileDone({
    required Uri mxcUrl,
    required String savePath,
    required String filename,
    required FileInfo fileInfo,
    getThumbnail = false,
    StreamController<Either<Failure, Success>>? streamController,
  }) async {
    if (isAttachmentEncrypted) {
      await _handleEncryptedFileEvent(
        mxcUrl: mxcUrl,
        streamController: streamController,
        fileInfo: fileInfo,
        savePath: savePath,
        filename: filename,
        getThumbnail: getThumbnail,
      );
    } else {
      streamController?.add(
        Right(
          DownloadNativeFileSuccessState(
            filePath: fileInfo.filePath,
          ),
        ),
      );
    }
    return;
  }

  Future<void> _handleEncryptedFileEvent({
    required Uri mxcUrl,
    required FileInfo fileInfo,
    required String savePath,
    required String filename,
    bool getThumbnail = false,
    StreamController<Either<Failure, Success>>? streamController,
  }) async {
    streamController?.add(
      const Right(
        DecryptingFileState(),
      ),
    );
    try {
      final decryptedFile = await decryptFile(
        fileInfo,
        mxcUrl,
        await StorageDirectoryManager.instance.getDecryptedFilePath(
          eventId: eventId,
          fileName: filename,
        ),
        getThumbnail: getThumbnail,
      );
      if (decryptedFile == null) {
        throw Exception(
          'DownloadManager::download(): decryptedFile is null',
        );
      }
      final saveFile = File(
        await StorageDirectoryManager.instance.getDecryptedFilePath(
          eventId: eventId,
          fileName: filename,
        ),
      ).copySync(savePath);
      streamController?.add(
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
      streamController?.add(
        Left(
          DownloadFileFailureState(exception: e),
        ),
      );
    } finally {
      await _clearDecryptedFile(
        eventId: eventId,
        filename: filename,
      );
    }
  }

  Future<void> _clearDecryptedFile({
    required String eventId,
    required String filename,
  }) async {
    try {
      final decryptedFilePath = await StorageDirectoryManager.instance
          .getDecryptedFilePath(eventId: eventId, fileName: filename);
      await File(decryptedFilePath).delete();
    } catch (e) {
      Logs().e(
        '_clearEncryptedFile(): $e',
      );
    }
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
    StreamController<Either<Failure, Success>>? downloadStreamController,
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
    getThumbnail = getThumbnail && hasThumbnail;

    final mxcUrl = getAttachmentOrThumbnailMxcUrl(getThumbnail: getThumbnail);
    if (mxcUrl == null) {
      throw "getFileInfo: This event hasn't any attachment or thumbnail.";
    }

    final isFileEncrypted =
        getThumbnail ? isThumbnailEncrypted : isAttachmentEncrypted;
    if (isEncryptionDisabled(isFileEncrypted)) {
      throw ('getFileInfo: Encryption is not enabled in your Client.');
    }

    final filename = getThumbnail ? thumbnailFilename : this.filename;
    String? decryptedPath;
    if (isFileEncrypted) {
      decryptedPath =
          await StorageDirectoryManager.instance.getDecryptedFilePath(
        eventId: eventId,
        fileName: filename,
      );
      final decryptedFile = File(decryptedPath);

      if (await File(decryptedPath).exists()) {
        final decryptedFileLength = await decryptedFile.length();
        if (decryptedFileLength == getFileSize(getThumbnail: getThumbnail)) {
          return FileInfo(
            filename,
            decryptedPath,
            getFileSize(getThumbnail: getThumbnail),
          );
        } else {
          await decryptedFile.delete();
        }
      }
    }

    return downloadOrRetrieveAttachment(
      mxcUrl,
      await StorageDirectoryManager.instance
          .getFilePathInAppDownloads(eventId: eventId, fileName: filename),
      downloadStreamController: downloadStreamController,
      getThumbnail: getThumbnail,
      progressCallback: progressCallback,
      cancelToken: cancelToken,
      filename: filename,
    );
  }
}
