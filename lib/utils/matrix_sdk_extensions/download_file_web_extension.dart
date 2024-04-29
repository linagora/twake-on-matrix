import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/media/cancel_exception.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/exception/download_file_web_exception.dart';
import 'package:fluffychat/utils/manager/download_manager/download_file_state.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/stream_list_int_extension.dart';
import 'package:matrix/matrix.dart';

extension DownloadFileWebExtension on Event {
  Future<MatrixFile?> downloadFileWeb({
    required StreamController<Either<Failure, Success>>
        downloadStreamController,
    CancelToken? cancelToken,
  }) async {
    if (!canContainAttachment()) {
      throw DownloadFileWebException(
        error:
            "downloadFileWeb: This event has the type '$type' and so it can't contain an attachment.",
      );
    }

    if (isSending()) {
      final localFile = room.sendingFilePlaceholders[eventId];
      if (localFile != null) return localFile;
    }

    final mxcUrl = getAttachmentOrThumbnailMxcUrl();
    if (mxcUrl == null) {
      throw DownloadFileWebException(
        error:
            "downloadFileWeb: This event hasn't any attachment or thumbnail.",
      );
    }

    final isFileEncrypted = isAttachmentEncrypted;
    if (isEncryptionDisabled(isFileEncrypted)) {
      throw DownloadFileWebException(
        error: 'downloadFileWeb: Encryption is not enabled in your Client.',
      );
    }

    final storeable = isFileStoreable();

    Uint8List? uint8list;

    if (storeable) {
      uint8list = await room.client.database?.getFile(eventId, filename);
    }

    if (uint8list != null) {
      return MatrixFile(
        bytes: await _decryptAttachmentWeb(uint8list: uint8list),
        name: body,
      );
    }

    return await _handleDownloadFileWeb(
      mxcUrl: mxcUrl,
      downloadStreamController: downloadStreamController,
      cancelToken: cancelToken,
      storeable: storeable,
    );
  }

  Future<MatrixFile?> _handleDownloadFileWeb({
    required Uri mxcUrl,
    required StreamController<Either<Failure, Success>>
        downloadStreamController,
    CancelToken? cancelToken,
    bool storeable = true,
  }) async {
    try {
      final database = room.client.database;
      final mediaAPI = getIt<MediaAPI>();
      final downloadLink = mxcUrl.getDownloadLink(room.client);
      final stream = await mediaAPI.downloadFileWeb(
        uri: downloadLink,
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
      final uint8List = await stream.toUint8List();
      if (database != null &&
          storeable &&
          uint8List.length < database.maxFileSize) {
        await database.storeEventFile(
          eventId,
          filename,
          uint8List,
          DateTime.now().millisecondsSinceEpoch,
        );
      }

      await _handleDownloadFileWebSuccess(
        uint8List,
        downloadStreamController,
      );
      return MatrixFile(bytes: uint8List, name: body);
    } catch (e) {
      if (e is CancelRequestException) {
        Logs().i("_handleDownloadFileWeb: user cancel the download");
      }
      Logs().e("_handleDownloadFileWeb: $e");
      downloadStreamController.add(
        Left(
          DownloadFileFailureState(exception: e),
        ),
      );
    }
    return null;
  }

  Future<void> _handleDownloadFileWebSuccess(
    Uint8List uint8List,
    StreamController<Either<Failure, Success>> streamController,
  ) async {
    if (isAttachmentEncrypted) {
      await _handleDecryptedFileWeb(
        streamController: streamController,
        uint8list: uint8List,
      );
    } else {
      streamController.add(
        Right(
          DownloadMatrixFileSuccessState(
            matrixFile: MatrixFile(bytes: uint8List, name: body),
          ),
        ),
      );
    }
    return;
  }

  Future<void> _handleDecryptedFileWeb({
    required StreamController<Either<Failure, Success>> streamController,
    required Uint8List uint8list,
  }) async {
    streamController.add(
      const Right(
        DecryptingFileState(),
      ),
    );
    try {
      final decryptedFile = await _decryptAttachmentWeb(
        uint8list: uint8list,
      );
      if (decryptedFile == null) {
        throw DownloadFileWebException(
          error: '_handleDecryptedFileWeb:: decryptedFile is null',
        );
      }
      streamController.add(
        Right(
          DownloadMatrixFileSuccessState(
            matrixFile: MatrixFile(bytes: decryptedFile, name: body),
          ),
        ),
      );
    } catch (e) {
      Logs().e(
        '_handleDecryptedFileWeb:: $e',
      );
      streamController.add(
        Left(
          DownloadFileFailureState(exception: e),
        ),
      );
    }
  }

  Future<Uint8List?> _decryptAttachmentWeb({
    required Uint8List uint8list,
  }) async {
    final dynamic fileMap = content['file'];
    if (!fileMap['key']['key_ops'].contains('decrypt')) {
      throw DownloadFileWebException(
        error: "_decryptAttachmentWeb: Missing 'decrypt' in 'key_ops'.",
      );
    }
    final encryptedFile = EncryptedFile(
      data: uint8list,
      iv: fileMap['iv'],
      k: fileMap['key']['k'],
      sha256: fileMap['hashes']['sha256'],
    );
    final decryptAttachment =
        await room.client.nativeImplementations.decryptFile(encryptedFile);
    if (decryptAttachment == null) {
      throw DownloadFileWebException(
        error: '_decryptAttachmentWeb: Unable to decrypt file',
      );
    }

    return decryptAttachment;
  }
}
