import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:dartz/dartz.dart' hide id;
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/data/network/media/cancel_exception.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/utils/exception/upload_exception.dart';
import 'package:fluffychat/utils/extension/web_url_creation_extension.dart';
import 'package:fluffychat/utils/js_window/non_js_window.dart'
    if (dart.library.js) 'package:fluffychat/utils/js_window/js_window.dart';
import 'package:fluffychat/utils/js_window/universal_image_bitmap.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_state.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/run_benchmarked.dart';
import 'package:image/image.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
      uploadStreamController?.add(
        const Right(ConvertingStreamToBytesState()),
      );
      imageBitmap = await convertUint8ListToBitmap(file.bytes);
      uploadStreamController?.add(
        const Right(ConvertedStreamToBytesState()),
      );
      file = MatrixImageFile(
        name: file.name,
        width: imageBitmap?.width,
        height: imageBitmap?.height,
        bytes: file.bytes,
      );
    }
    sendingFilePlaceholders[txid] = file;
    // Check media config of the server before sending the file. Stop if the
    // Media config is unreachable or the file is bigger than the given maxsize.
    try {
      final mediaConfig = await client.getConfig();
      final maxMediaSize = mediaConfig.mUploadSize;
      Logs().d(
        'SendImage::sendImageFileEvent(): FileSized ${file.size} || maxMediaSize $maxMediaSize',
      );
      if (maxMediaSize != null && maxMediaSize < file.size) {
        uploadStreamController?.add(
          Left(
            UploadFileFailedState(
              exception: FileTooBigMatrixException(file.size, maxMediaSize),
            ),
          ),
        );
        throw FileTooBigMatrixException(file.size, maxMediaSize);
      }
    } catch (e) {
      Logs().d('Config error while sending file', e);
      uploadStreamController?.add(
        Left(
          UploadFileFailedState(
            exception: e,
          ),
        ),
      );
      fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
          .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
      await handleImageFakeSync(fakeImageEvent);
      rethrow;
    }
    // computing the thumbnail in case we can
    if (file.msgType == MessageTypes.Image &&
        (thumbnail == null || shrinkImageMaxDimension != null) &&
        file is MatrixImageFile) {
      fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
              .unsigned![fileSendingStatusKey] =
          FileSendingStatus.generatingThumbnail.name;
      await handleImageFakeSync(fakeImageEvent);
      thumbnail ??= await generateThumbnail(file);
      if (thumbnail != null && file.size < thumbnail.size) {
        thumbnail = null; // in this case, the thumbnail is not usefull
      }
    } else if (file is MatrixVideoFile) {
      fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
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
      uploadStreamController?.add(
        const Right(EncryptingFileState()),
      );
      fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
          .unsigned![fileSendingStatusKey] = FileSendingStatus.encrypting.name;
      await handleImageFakeSync(fakeImageEvent);
      encryptedFile = await file.encrypt();
      uploadFile =
          MatrixFile.fromMimeType(bytes: encryptedFile.data, name: 'crypt');
      uploadStreamController?.add(
        const Right(EncryptedFileState()),
      );
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

    fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
        .unsigned![fileSendingStatusKey] = FileSendingStatus.uploading.name;
    while (uploadResp == null) {
      try {
        final mediaApi = getIt.get<MediaAPI>();
        final uploadFileResponse = await mediaApi.uploadFileWeb(
          file: uploadFile,
          cancelToken: cancelToken,
          onSendProgress: (receive, total) {
            uploadStreamController?.add(
              Right(
                UploadingFileState(
                  receive: receive,
                  total: total,
                ),
              ),
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
          Right(
            UploadFileSuccessState(
              eventId: txid,
            ),
          ),
        );
      } on MatrixException catch (e) {
        fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
            .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
        await handleImageFakeSync(fakeImageEvent);
        uploadStreamController?.add(
          Left(
            UploadFileFailedState(
              exception: e,
            ),
          ),
        );
        Logs().v('Error: $e');
        rethrow;
      } catch (e) {
        if (e is CancelRequestException) {
          Logs().i('User cancel the upload');
          uploadStreamController?.add(
            Left(
              UploadFileFailedState(
                exception: CancelUploadException(),
              ),
            ),
          );
          return null;
        }
        fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
            .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
        await handleImageFakeSync(fakeImageEvent);
        uploadStreamController?.add(
          Left(
            UploadFileFailedState(
              exception: e,
            ),
          ),
        );
        Logs().v('Error: $e');
        Logs().v('Send File into room failed. Try again...');
        return null;
      }
    }

    final duration =
        file is MatrixVideoFile ? await _getVideoDuration(file) : null;

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
      if (captionInfo != null) 'body': captionInfo,
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

  Future<SyncUpdate> sendFakeFileEvent(
    MatrixFile file, {
    required String txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
    DateTime? sentDate,
    String? captionInfo,
  }) async {
    // sendingFileThumbnails[txid] =  MatrixImageFile(bytes: file.bytes, name: file.name);

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

    // Create a fake Event object as a placeholder for the uploading file:
    final fakeImageEventEvent = SyncUpdate(
      nextBatch: '',
      rooms: RoomsUpdate(
        join: {
          id: JoinedRoomUpdate(
            timeline: TimelineUpdate(
              events: [
                MatrixEvent(
                  content: {
                    'msgtype': file.msgType,
                    'body': captionInfo ?? file.name,
                    if (contentCaptionFormat != null) ...contentCaptionFormat,
                    'filename': file.name,
                    'info': file.info,
                  },
                  type: EventTypes.Message,
                  eventId: txid,
                  senderId: client.userID!,
                  originServerTs: sentDate ?? DateTime.now(),
                  unsigned: {
                    messageSendingStatusKey: EventStatus.sending.intValue,
                    'transaction_id': txid,
                    if (inReplyTo?.eventId != null)
                      'in_reply_to': inReplyTo?.eventId,
                    if (editEventId != null) 'edit_event_id': editEventId,
                    if (shrinkImageMaxDimension != null)
                      'shrink_image_max_dimension': shrinkImageMaxDimension,
                    if (extraContent != null) 'extra_content': extraContent,
                  },
                ),
              ],
            ),
          ),
        },
      ),
    );
    await handleImageFakeSync(fakeImageEventEvent);
    return fakeImageEventEvent;
  }

  Future<void> handleImageFakeSync(
    SyncUpdate fakeImageEvent, {
    Direction? direction,
  }) async {
    await client.database.transaction(() async {
      await client.handleSync(fakeImageEvent, direction: direction);
    });
  }

  Future<MatrixImageFile?> generateThumbnail(
    MatrixImageFile originalFile, {
    StreamController<Either<Failure, Success>>? uploadStreamController,
  }) async {
    try {
      uploadStreamController?.add(
        const Right(GeneratingThumbnailState()),
      );
      final result = await FlutterImageCompress.compressWithList(
        originalFile.bytes,
        quality: AppConfig.thumbnailQuality,
        format: AppConfig.imageCompressFormmat,
      );

      final blurHash = await runBenchmarked(
        '_generateBlurHash',
        () => _generateBlurHash(result),
      );

      uploadStreamController?.add(
        const Right(GenerateThumbnailSuccess()),
      );

      return MatrixImageFile(
        bytes: result,
        name: '${originalFile.name}.${AppConfig.imageCompressFormmat.name}',
        mimeType: originalFile.mimeType,
        width: originalFile.width,
        height: originalFile.height,
        blurhash: blurHash,
      );
    } catch (e) {
      uploadStreamController?.add(
        Left(
          GenerateThumbnailFailed(
            exception: e,
          ),
        ),
      );
      Logs().e('Error while generating thumbnail', e);
      return null;
    }
  }

  Future<MatrixImageFile?> generateVideoThumbnail(
    MatrixVideoFile originalFile, {
    StreamController<Either<Failure, Success>>? uploadStreamController,
  }) async {
    try {
      uploadStreamController?.add(
        const Right(GeneratingThumbnailState()),
      );
      late String url;
      if (PlatformInfos.isWeb) {
        url = originalFile.bytes.toWebUrl(mimeType: originalFile.mimeType);
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${originalFile.name}');
        await tempFile.writeAsBytes(originalFile.bytes);
        url = tempFile.path;
      }

      final result = await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: AppConfig.videoThumbnailFormat,
        quality: AppConfig.thumbnailQuality,
      );
      final thumbnailBitmap = await convertUint8ListToBitmap(result);
      final blurHash = await runBenchmarked(
        '_generateBlurHash',
        () => _generateBlurHash(result),
      );

      uploadStreamController?.add(
        const Right(GenerateThumbnailSuccess()),
      );

      final thumbnailFileName = _getVideoThumbnailFileName(originalFile);

      if (PlatformInfos.isMobile) await File(url).delete();

      return MatrixImageFile(
        bytes: result,
        name: thumbnailFileName,
        mimeType: lookupMimeType(thumbnailFileName) ?? 'image/jpeg',
        width: thumbnailBitmap?.width,
        height: thumbnailBitmap?.height,
        blurhash: blurHash,
      );
    } catch (e) {
      uploadStreamController?.add(
        Left(
          GenerateThumbnailFailed(
            exception: e,
          ),
        ),
      );
      Logs().e('Error while generating thumbnail', e);
      return null;
    }
  }

  String _getVideoThumbnailFileName(MatrixVideoFile originalFile) =>
      '${originalFile.name}.${AppConfig.videoThumbnailFormat.name.toLowerCase()}';

  Future<int?> _getVideoDuration(
    MatrixVideoFile originalFile,
  ) async {
    VideoPlayerController? videoPlayerController;
    try {
      final url = originalFile.bytes.toWebUrl(mimeType: originalFile.mimeType);
      videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await videoPlayerController.initialize();
      final duration = videoPlayerController.value.duration.inMilliseconds;
      return duration;
    } catch (e) {
      Logs().e('Error while generating thumbnail', e);
      return null;
    } finally {
      videoPlayerController?.dispose();
    }
  }
}

Future<String?> _generateBlurHash(Uint8List data) async {
  try {
    final result = await FlutterImageCompress.compressWithList(
      data,
      minHeight: AppConfig.blurHashSize,
      minWidth: AppConfig.blurHashSize,
    );
    final image = decodeJpg(result);
    final blurHash = image != null ? BlurHash.encode(image) : null;
    return blurHash?.hash;
  } catch (e) {
    Logs().e('_generateBlurHash::error', e);
    return null;
  }
}
