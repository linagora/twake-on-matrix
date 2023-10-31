import 'dart:io';

import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

extension DownloadFileExtension on Event {
  bool canContainAttachment() {
    return [EventTypes.Message, EventTypes.Sticker].contains(type);
  }

  bool isSending() {
    return status.isSending;
  }

  Uri? getAttachmentOrThumbnailMxcUrl(bool getThumbnail) {
    return attachmentOrThumbnailMxcUrl(getThumbnail: getThumbnail);
  }

  bool isEncryptionDisabled(bool isEncrypted) {
    return isEncrypted && !room.client.encryptionEnabled;
  }

  Future<FileInfo?> downloadOrRetrieveAttachment(
    Uri mxcUrl,
    String savePath,
  ) async {
    final database = room.client.database;
    final attachment = await database?.getFileEntity(mxcUrl);

    final mediaApi = getIt.get<MediaAPI>();
    final downloadLink = mxcUrl.getDownloadLink(room.client);

    if (attachment != null) {
      return FileInfo(
        filename,
        attachment.path,
        content.tryGet<int>('size') ?? attachment.lengthSync(),
      );
    }

    final downloadResponse = await mediaApi.downloadFileInfo(
      uriPath: downloadLink,
      savePath: savePath,
    );
    if (downloadResponse.statusCode == 200) {
      return FileInfo(
        filename,
        savePath,
        content.tryGet<int>('size') ?? File(savePath).lengthSync(),
        progressCallback: downloadResponse.onReceiveProgress,
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

    if (!File(decryptedPath).existsSync()) {
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
      content.tryGet<int>('size') ?? File(decryptedPath).lengthSync(),
      progressCallback: fileInfo?.progressCallback,
    );
  }

  Future<FileInfo?> getFileInfo({
    getThumbnail = false,
  }) async {
    if (!canContainAttachment()) {
      throw ("getFileInfo: This event has the type '$type' and so it can't contain an attachment.");
    }

    if (isSending()) {
      final localFile = room.sendingFilePlaceholders[eventId];
      if (localFile != null) return FileInfo.fromMatrixFile(localFile);
    }

    final mxcUrl = getAttachmentOrThumbnailMxcUrl(getThumbnail);
    if (mxcUrl == null) {
      throw "getFileInfo: This event hasn't any attachment or thumbnail.";
    }

    final isEncrypted =
        getThumbnail ? isThumbnailEncrypted : isAttachmentEncrypted;
    if (isEncryptionDisabled(isEncrypted)) {
      throw ('getFileInfo: Encryption is not enabled in your Client.');
    }

    final tempDirectory = await _getFileStoreDirectory();

    final decryptedPath =
        '$tempDirectory/${Uri.encodeComponent(mxcUrl.toString())}-decrypted';
    if (File(decryptedPath).existsSync()) {
      return FileInfo(
        body,
        decryptedPath,
        content.tryGet<int>('size') ?? File(decryptedPath).lengthSync(),
      );
    }

    final fileInfo = await downloadOrRetrieveAttachment(
      mxcUrl,
      '$tempDirectory/${Uri.encodeComponent(mxcUrl.toString())}',
    );

    if (isEncrypted && fileInfo != null) {
      return await decryptFile(
        fileInfo,
        mxcUrl,
        decryptedPath,
        getThumbnail: getThumbnail,
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
