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
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/manager/storage_directory_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
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
    final size = getThumbnail ? thumbnailInfoMap['size'] : infoMap['size'];
    return size is int ? size : 0;
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
    final attachment = File(savePath);
    final downloadLink = await mxcUrl.getDownloadUri(room.client);
    Logs().d(
      'DownloadFileExtension::downloadOrRetrieveAttachment(): downloadLink = $downloadLink',
    );

    final attachmentExists = await attachment.exists();

    bool needsDownload = true;

    if (attachmentExists) {
      final actualSize = await attachment.length();
      final expectedSize = getFileSize(getThumbnail: getThumbnail);
      if ((expectedSize > 0 && actualSize == expectedSize) ||
          (expectedSize <= 0 && actualSize > 0)) {
        needsDownload = false;
      } else {
        await attachment.delete();
      }
    }

    if (needsDownload) {
      try {
        final mediaAPI = getIt<MediaAPI>();
        final downloadResponse = await mediaAPI.downloadFileInfo(
          uriPath: downloadLink,
          savePath: savePath,
          onReceiveProgress: (receive, total) {
            progressCallback?.call(receive, total);
            downloadStreamController?.add(
              Right(DownloadingFileState(receive: receive, total: total)),
            );
          },
          cancelToken: cancelToken,
        );
        final status = downloadResponse.statusCode ?? 0;
        if (status < 200 || status >= 300 || !await File(savePath).exists()) {
          throw Exception(
            'Download failed (status: ${downloadResponse.statusCode}): $filename',
          );
        }
      } catch (e) {
        if (e is CancelRequestException) {
          Logs().i("downloadOrRetrieveAttachment: user cancel the download");
        } else if (e is DioDuplicateDownloadException) {
          Logs().i("downloadOrRetrieveAttachment: duplicate request");
        } else {
          Logs().e("downloadOrRetrieveAttachment: $e");
          downloadStreamController?.add(
            Left(DownloadFileFailureState(exception: e)),
          );
        }
        return null;
      }
    }

    final fileInfo = FileInfo(filename, filePath: savePath);

    final decryptedFileInfo = await _handleDownloadFileDone(
      mxcUrl: mxcUrl,
      fileInfo: fileInfo,
      savePath: savePath,
      filename: filename,
      streamController: downloadStreamController,
      getThumbnail: getThumbnail,
    );

    return decryptedFileInfo ?? fileInfo;
  }

  Future<FileInfo?> _handleDownloadFileDone({
    required Uri mxcUrl,
    required String savePath,
    required String filename,
    required FileInfo fileInfo,
    bool getThumbnail = false,
    StreamController<Either<Failure, Success>>? streamController,
  }) async {
    Logs().i('DownloadFileExtension::_handleDownloadFileDone(): $mxcUrl');
    if (isAttachmentEncrypted) {
      return await _handleEncryptedFileEvent(
        mxcUrl: mxcUrl,
        streamController: streamController,
        fileInfo: fileInfo,
        savePath: savePath,
        filename: filename,
        getThumbnail: getThumbnail,
      );
    } else {
      streamController?.add(
        Right(DownloadNativeFileSuccessState(filePath: savePath)),
      );
      return null;
    }
  }

  Future<FileInfo?> _handleEncryptedFileEvent({
    required Uri mxcUrl,
    required FileInfo fileInfo,
    required String savePath,
    required String filename,
    bool getThumbnail = false,
    StreamController<Either<Failure, Success>>? streamController,
  }) async {
    streamController?.add(const Right(DecryptingFileState()));
    try {
      final decryptedPath = await StorageDirectoryManager.instance
          .getDecryptedFilePath(eventId: eventId, fileName: filename);

      final decryptedFile = await decryptFile(
        fileInfo,
        decryptedPath,
        filename: filename,
        getThumbnail: getThumbnail,
      );
      if (decryptedFile == null) {
        throw Exception('DownloadManager::download(): decryptedFile is null');
      }
      streamController?.add(
        Right(DownloadNativeFileSuccessState(filePath: decryptedPath)),
      );

      // Delete the encrypted file to save space
      await _clearEncryptedFile(savePath: savePath);

      return decryptedFile;
    } catch (e) {
      Logs().e('DownloadManager::_handleEncryptedFileEvent(): $e');
      streamController?.add(Left(DownloadFileFailureState(exception: e)));
      return null;
    }
  }

  Future<void> _clearEncryptedFile({required String savePath}) async {
    try {
      final encryptedFile = File(savePath);
      if (await encryptedFile.exists()) {
        await encryptedFile.delete();
      }
    } catch (e) {
      Logs().e('_clearEncryptedFile(): $e');
    }
  }

  // Decrypt the file if it's encrypted.
  Future<FileInfo?> decryptFile(
    FileInfo? fileInfo,
    String decryptedPath, {
    required String filename,
    bool getThumbnail = false,
  }) async {
    if (fileInfo == null) {
      throw ArgumentError.notNull('fileInfo');
    }

    if (fileInfo.filePath == null) {
      throw StateError('decryptFile: fileInfo.filePath is null');
    }

    final fileMap = getThumbnail ? infoMap['thumbnail_file'] : content['file'];
    if (fileMap is! Map<String, dynamic> ||
        fileMap['key'] is! Map<String, dynamic> ||
        fileMap['key']['key_ops'] == null ||
        fileMap['hashes'] is! Map<String, dynamic>) {
      throw StateError(
        'decryptFile: Missing encryption metadata in event content',
      );
    }
    if (!fileMap['key']['key_ops'].contains('decrypt')) {
      throw StateError("decryptFile: Missing 'decrypt' in 'key_ops'.");
    }

    final encryptedBytes = await File(fileInfo.filePath!).readAsBytes();

    final encryptedFile = EncryptedFile(
      data: encryptedBytes,
      iv: fileMap['iv'],
      k: fileMap['key']['k'],
      sha256: fileMap['hashes']['sha256'],
    );

    final decryptedBytes = await room.client.nativeImplementations.decryptFile(
      encryptedFile,
    );

    if (decryptedBytes == null) {
      throw Exception('decryptFile: Unable to decrypt file');
    }

    final decryptedFile = File(decryptedPath);
    await decryptedFile.writeAsBytes(decryptedBytes);

    return FileInfo(filename, filePath: decryptedPath);
  }

  Future<FileInfo?> getFileInfo({
    bool getThumbnail = false,
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

    if (getThumbnail && thumbnailMimetype.startsWith('image') != true) {
      throw ('getFileInfo: This event has a thumbnail but it is not an image.');
    }

    final isFileEncrypted = getThumbnail
        ? isThumbnailEncrypted
        : isAttachmentEncrypted;
    if (isEncryptionDisabled(isFileEncrypted)) {
      throw ('getFileInfo: Encryption is not enabled in your Client.');
    }

    final filename = getThumbnail ? thumbnailFilename : this.filename;
    if (isFileEncrypted) {
      final decryptedPath = await StorageDirectoryManager.instance
          .getDecryptedFilePath(eventId: eventId, fileName: filename);
      final decryptedFile = File(decryptedPath);

      if (await decryptedFile.exists()) {
        final decryptedFileLength = await decryptedFile.length();
        if (decryptedFileLength > 0) {
          return FileInfo(filename, filePath: decryptedPath);
        } else {
          await decryptedFile.delete();
        }
      }
    }

    return downloadOrRetrieveAttachment(
      mxcUrl,
      await StorageDirectoryManager.instance.getFilePathInAppDownloads(
        eventId: eventId,
        fileName: filename,
      ),
      downloadStreamController: downloadStreamController,
      getThumbnail: getThumbnail,
      progressCallback: progressCallback,
      cancelToken: cancelToken,
      filename: filename,
    );
  }
}
