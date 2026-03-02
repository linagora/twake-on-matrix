import 'dart:async';
import 'package:dartz/dartz.dart' hide id;
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/media/cancel_exception.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/presentation/extensions/media_thumbnail_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_fake_event_extension.dart';
import 'package:fluffychat/utils/exception/upload_exception.dart';
import 'package:fluffychat/utils/js_window/non_js_window.dart'
    if (dart.library.js) 'package:fluffychat/utils/js_window/js_window.dart';
import 'package:fluffychat/utils/js_window/universal_image_bitmap.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_state.dart';
import 'package:matrix/matrix.dart';

extension SendFileWebExtension on Room {
  Future<String?> sendFileOnWebEvent(
    MatrixFile matrixFile, {
    required SyncUpdate fakeImageEvent,
    required String txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    MatrixImageFile? thumbnail,
    Map<String, dynamic>? extraContent,
    StreamController<Either<Failure, Success>>? uploadStreamController,
    CancelToken? cancelToken,
    DateTime? sentDate,
    String? captionInfo,
  }) async {
    UniversalImageBitmap? imageBitmap;
    MatrixFile file = matrixFile;
    if (file is MatrixImageFile) {
      uploadStreamController?.add(const Right(ConvertingStreamToBytesState()));
      imageBitmap = await convertUint8ListToBitmap(file.bytes);
      uploadStreamController?.add(const Right(ConvertedStreamToBytesState()));
      file = MatrixImageFile(
        name: file.name,
        width: imageBitmap?.width,
        height: imageBitmap?.height,
        bytes: file.bytes,
      );
    }
    sendingFilePlaceholders[txid] = file;
    try {
      int maxMediaSize = 0;
      try {
        final mediaConfig = await client.getConfig();
        maxMediaSize = mediaConfig.mUploadSize ?? 0;
      } catch (e) {
        Logs().e('Cannot get media config', e);
      }
      Logs().d(
        'SendImage::sendImageFileEvent(): FileSized ${file.size} || maxMediaSize $maxMediaSize',
      );
      if (maxMediaSize > 0 && maxMediaSize < file.size) {
        throw FileTooBigMatrixException(file.size, maxMediaSize);
      }
    } catch (e) {
      Logs().d('Config error while sending file', e);

      fakeImageEvent
              .rooms!
              .join!
              .values
              .first
              .timeline!
              .events!
              .first
              .unsigned![messageSendingStatusKey] =
          EventStatus.error.intValue;
      await handleImageFakeSync(fakeImageEvent);
      rethrow;
    }
    // computing the thumbnail in case we can
    if (file.msgType == MessageTypes.Image &&
        (thumbnail == null || shrinkImageMaxDimension != null) &&
        file is MatrixImageFile) {
      fakeImageEvent
              .rooms!
              .join!
              .values
              .first
              .timeline!
              .events!
              .first
              .unsigned![fileSendingStatusKey] =
          FileSendingStatus.generatingThumbnail.name;
      await handleImageFakeSync(fakeImageEvent);
      thumbnail ??= await generateThumbnail(file);
      if (thumbnail != null && file.size < thumbnail.size) {
        thumbnail = null; // in this case, the thumbnail is not usefull
      }
    } else if (file is MatrixVideoFile) {
      fakeImageEvent
              .rooms!
              .join!
              .values
              .first
              .timeline!
              .events!
              .first
              .unsigned![fileSendingStatusKey] =
          FileSendingStatus.generatingThumbnail.name;
      await handleImageFakeSync(fakeImageEvent);
      thumbnail ??= await generateVideoThumbnail(file);
    }

    EncryptedFile? encryptedFile;
    MatrixFile uploadFile = file;
    MatrixFile? uploadThumbnail = thumbnail;
    EncryptedFile? encryptedThumbnail;
    if (encrypted && client.fileEncryptionEnabled) {
      uploadStreamController?.add(const Right(EncryptingFileState()));
      fakeImageEvent
              .rooms!
              .join!
              .values
              .first
              .timeline!
              .events!
              .first
              .unsigned![fileSendingStatusKey] =
          FileSendingStatus.encrypting.name;
      await handleImageFakeSync(fakeImageEvent);
      encryptedFile = await file.encrypt();
      uploadFile = MatrixFile.fromMimeType(
        bytes: encryptedFile.data,
        name: 'crypt',
      );
      uploadStreamController?.add(const Right(EncryptedFileState()));
      if (thumbnail != null) {
        uploadStreamController?.add(
          const Right(EncryptingFileState(isThumbnail: true)),
        );
        encryptedThumbnail = await thumbnail.encrypt();
        uploadThumbnail = MatrixFile.fromMimeType(
          bytes: encryptedThumbnail.data,
          name: 'crypt',
        );
        uploadStreamController?.add(
          const Right(EncryptedFileState(isThumbnail: true)),
        );
      }
    }
    Uri? uploadResp, thumbnailUploadResp;

    fakeImageEvent
            .rooms!
            .join!
            .values
            .first
            .timeline!
            .events!
            .first
            .unsigned![fileSendingStatusKey] =
        FileSendingStatus.uploading.name;
    while (uploadResp == null) {
      try {
        final mediaApi = getIt.get<MediaAPI>();
        final uploadFileResponse = await mediaApi.uploadFileWeb(
          file: uploadFile,
          cancelToken: cancelToken,
          onSendProgress: (receive, total) {
            uploadStreamController?.add(
              Right(UploadingFileState(receive: receive, total: total)),
            );
          },
        );
        uploadResp = uploadFileResponse.contentUri != null
            ? Uri.tryParse(uploadFileResponse.contentUri!)
            : null;
        if (uploadThumbnail != null) {
          final uploadThumbnailResponse = await mediaApi.uploadFileWeb(
            file: uploadThumbnail,
            cancelToken: cancelToken,
            onSendProgress: (receive, total) {
              uploadStreamController?.add(
                Right(
                  UploadingFileState(
                    receive: receive,
                    total: total,
                    isThumbnail: true,
                  ),
                ),
              );
            },
          );
          thumbnailUploadResp = uploadThumbnailResponse.contentUri != null
              ? Uri.tryParse(uploadThumbnailResponse.contentUri!)
              : null;
        } else {
          thumbnailUploadResp = null;
        }

        uploadStreamController?.add(
          Right(UploadFileSuccessState(eventId: txid)),
        );
      } on MatrixException catch (e) {
        fakeImageEvent
                .rooms!
                .join!
                .values
                .first
                .timeline!
                .events!
                .first
                .unsigned![messageSendingStatusKey] =
            EventStatus.error.intValue;
        await handleImageFakeSync(fakeImageEvent);
        Logs().e('Error: $e');
        rethrow;
      } catch (e) {
        if (e is CancelRequestException) {
          Logs().i('User cancel the upload');
          uploadStreamController?.add(
            Left(
              UploadFileFailedState(
                exception: CancelUploadException(),
                txid: txid,
              ),
            ),
          );
          return null;
        }
        fakeImageEvent
                .rooms!
                .join!
                .values
                .first
                .timeline!
                .events!
                .first
                .unsigned![messageSendingStatusKey] =
            EventStatus.error.intValue;
        await handleImageFakeSync(fakeImageEvent);
        uploadStreamController?.add(
          Left(UploadFileFailedState(exception: e, txid: txid)),
        );
        Logs().v('Error: $e');
        Logs().v('Send File into room failed. Try again...');
        return null;
      }
    }

    final duration = file is MatrixVideoFile
        ? await getVideoDuration(file)
        : null;

    final contentFromCaption = getEventContentFromMsgText(
      message: captionInfo ?? '',
      msgtype: file.msgType,
    );

    final contentCaptionFormat = contentFromCaption['formatted_body'] != null
        ? {
            'format': contentFromCaption['format'],
            'formatted_body': contentFromCaption['formatted_body'],
          }
        : null;
    // Send event
    final content = <String, dynamic>{
      'msgtype': file.msgType,
      'body': captionInfo ?? '',
      if (contentCaptionFormat != null) ...contentCaptionFormat,
      'filename': file.name,
      if (encryptedFile == null) 'url': uploadResp.toString(),
      if (encryptedFile != null)
        'file': {
          'url': uploadResp.toString(),
          'mimetype': file.mimeType,
          'v': 'v2',
          'key': {
            'alg': 'A256CTR',
            'ext': true,
            'k': encryptedFile.k,
            'key_ops': ['encrypt', 'decrypt'],
            'kty': 'oct',
          },
          'iv': encryptedFile.iv,
          'hashes': {'sha256': encryptedFile.sha256},
        },
      'info': {
        ...thumbnail?.info ?? {},
        ...file.info,
        if (thumbnail != null && encryptedThumbnail == null)
          'thumbnail_url': thumbnailUploadResp.toString(),
        if (thumbnail != null && encryptedThumbnail != null)
          'thumbnail_file': {
            'url': thumbnailUploadResp.toString(),
            'mimetype': thumbnail.mimeType,
            'v': 'v2',
            'key': {
              'alg': 'A256CTR',
              'ext': true,
              'k': encryptedThumbnail.k,
              'key_ops': ['encrypt', 'decrypt'],
              'kty': 'oct',
            },
            'iv': encryptedThumbnail.iv,
            'hashes': {'sha256': encryptedThumbnail.sha256},
          },
        if (thumbnail != null) 'thumbnail_info': thumbnail.info,
        if (duration != null) 'duration': duration,
      },
      if (extraContent != null) ...extraContent,
    };
    final eventId = await sendEvent(
      content,
      txid: txid,
      inReplyTo: inReplyTo,
      editEventId: editEventId,
    );

    sendingFilePlaceholders.remove(txid);

    return eventId;
  }
}
