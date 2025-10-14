import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide id;
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/media/cancel_exception.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/presentation/extensions/image_extension.dart';
import 'package:fluffychat/presentation/fake_sending_file_info.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/exception/upload_exception.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/manager/storage_directory_manager.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_state.dart';
import 'package:flutter/widgets.dart';
import 'package:heif_converter/heif_converter.dart';
import 'package:image/image.dart' as img;
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

typedef TransactionId = String;

typedef MessageType = String;

typedef FakeImageEvent = SyncUpdate;

extension SendFileExtension on Room {
  Future<String?> sendFileEventMobile(
    FileInfo fileInfo, {
    String msgType = MessageTypes.Image,
    required SyncUpdate fakeImageEvent,
    required String txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    ImageFileInfo? thumbnail,
    Map<String, dynamic>? extraContent,
    StreamController<Either<Failure, Success>>? uploadStreamController,
    CancelToken? cancelToken,
    DateTime? sentDate,
    String? captionInfo,
  }) async {
    // Check media config of the server before sending the file. Stop if the
    // Media config is unreachable or the file is bigger than the given maxsize.
    try {
      final mediaConfig = await client.getConfig();
      final maxMediaSize = mediaConfig.mUploadSize;
      Logs().d(
        'SendImage::sendFileEvent(): FileSized ${fileInfo.fileSize} || maxMediaSize $maxMediaSize',
      );
      Logs().d(
        'SendImage::sendFileEvent(): path ${fileInfo.filePath}',
      );

      Logs().d(
        'SendImage::sendFileEvent(): File info $fileInfo',
      );
      if (maxMediaSize != null && maxMediaSize < fileInfo.fileSize) {
        uploadStreamController?.add(
          Left(
            UploadFileFailedState(
              exception: FileTooBigMatrixException(
                fileInfo.fileSize,
                maxMediaSize,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      Logs().d('Config error while sending file', e);
      await _updateFakeSync(
        fakeImageEvent,
        messageSendingStatusKey,
        EventStatus.error.intValue,
      );
      rethrow;
    }

    final tempDir = await getTemporaryDirectory();

    Logs().d(
      'sendFileEventMobile::File Path: ${fileInfo.filePath} - mimeType: ${fileInfo.mimeType}',
    );
    if (TwakeMimeTypeExtension.heicMimeTypes.contains(fileInfo.mimeType) &&
        fileInfo is ImageFileInfo) {
      try {
        final oldFilePath = fileInfo.filePath;
        fileInfo = await convertHeicToJpgImage(fileInfo);
        File(oldFilePath).delete();
      } catch (e) {
        Logs().e('sendFileEventMobile::Error while converting heic to jpg', e);
      }

      final formattedDateTime = DateTime.now().getFormattedCurrentDateTime();
      final fileName = _generateThumbnailFileName(formattedDateTime, fileInfo);
      final targetPath = await _createThumbnailFile(tempDir, fileName);
      Logs().d(
        'sendFileEventMobile::Thumbnail target File Path: ${targetPath.path} - file name: $fileName',
      );
      await _generateThumbnail(
        fileInfo as ImageFileInfo,
        targetPath: targetPath.path,
        uploadStreamController: uploadStreamController,
      );
      thumbnail = ImageFileInfo(
        fileName,
        targetPath.path,
        await targetPath.length(),
        width: fileInfo.width,
        height: fileInfo.height,
      );
    }

    final encryptedService = EncryptedService();
    final formattedDateTime = DateTime.now().getFormattedCurrentDateTime();
    final tempEncryptedFile =
        await File('${tempDir.path}/$formattedDateTime${fileInfo.fileName}')
            .create();
    File? tempThumbnailFile;
    File? tempEncryptedThumbnailFile;
    if (msgType == MessageTypes.Image || msgType == MessageTypes.Video) {
      tempThumbnailFile = await File(
        '${tempDir.path}/${formattedDateTime}_${fileInfo.fileName}_thumbnail.jpg',
      ).create();
      tempEncryptedThumbnailFile = await File(
        '${tempDir.path}/${formattedDateTime}_${fileInfo.fileName}_encrypted_thumbnail',
      ).create();
    }

    // computing the thumbnail in case we can
    if (fileInfo is ImageFileInfo &&
        (thumbnail == null || shrinkImageMaxDimension != null)) {
      await _updateFakeSync(
        fakeImageEvent,
        fileSendingStatusKey,
        FileSendingStatus.generatingThumbnail.name,
      );
      thumbnail ??= await _generateThumbnail(
        fileInfo,
        targetPath: tempThumbnailFile?.path ?? '',
        uploadStreamController: uploadStreamController,
      );
      fileInfo = ImageFileInfo(
        fileInfo.fileName,
        fileInfo.filePath,
        fileInfo.fileSize,
        width: thumbnail?.width,
        height: thumbnail?.height,
      );
      storePlaceholderFileInMem(
        fileInfo: fileInfo,
        txid: txid,
      );
      fakeImageEvent = await sendFakeFileInfoEvent(
        fileInfo,
        txid: txid,
        messageType: msgType,
        inReplyTo: inReplyTo,
        editEventId: editEventId,
        shrinkImageMaxDimension: shrinkImageMaxDimension,
        extraContent: extraContent,
        captionInfo: captionInfo,
      );

      if (thumbnail != null &&
          fileInfo.fileSize > 0 &&
          fileInfo.fileSize < thumbnail.fileSize) {
        Logs().d(
          'sendFileEventMobile::Thumbnail is bigger than the original file',
        );
        thumbnail = null; // in this case, the thumbnail is not usefull
      }
    } else if (fileInfo is VideoFileInfo) {
      await _updateFakeSync(
        fakeImageEvent,
        fileSendingStatusKey,
        FileSendingStatus.generatingThumbnail.name,
      );
      Logs().d('Video thumbnail generation started', thumbnail != null);
      thumbnail ??= await _getThumbnailVideo(
        tempThumbnailFile ?? File(''),
        fileInfo,
        txid,
        uploadStreamController: uploadStreamController,
      );
      if (fileInfo.width == null ||
          fileInfo.height == null ||
          fileInfo.width == 0 ||
          fileInfo.height == 0) {
        fileInfo = VideoFileInfo(
          fileInfo.fileName,
          fileInfo.filePath,
          fileInfo.fileSize,
          imagePlaceholderBytes: fileInfo.imagePlaceholderBytes,
          width: thumbnail.width,
          height: thumbnail.height,
        );
        if (fileInfo.imagePlaceholderBytes.isNotEmpty) {
          storePlaceholderFileInMem(
            fileInfo: fileInfo,
            txid: txid,
          );
        } else {
          storePlaceholderFileInMem(
            fileInfo: thumbnail,
            txid: txid,
          );
        }

        fakeImageEvent = await sendFakeFileInfoEvent(
          fileInfo,
          txid: txid,
          messageType: msgType,
          inReplyTo: inReplyTo,
          editEventId: editEventId,
          shrinkImageMaxDimension: shrinkImageMaxDimension,
          extraContent: extraContent,
          captionInfo: captionInfo,
        );
      }
    }

    EncryptedFileInfo? encryptedFileInfo;
    EncryptedFileInfo? encryptedThumbnail;
    if (isRoomEncrypted()) {
      await _updateFakeSync(
        fakeImageEvent,
        fileSendingStatusKey,
        FileSendingStatus.encrypting.name,
      );

      try {
        uploadStreamController?.add(
          const Right(EncryptingFileState()),
        );
        encryptedFileInfo = await encryptedService.encryptFile(
          fileInfo: fileInfo,
          outputFile: tempEncryptedFile,
        );
        uploadStreamController?.add(
          const Right(EncryptedFileState()),
        );
      } catch (e) {
        uploadStreamController?.add(
          Left(EncryptFailedFileState(exception: e)),
        );
      }

      fileInfo = FileInfo(
        fileInfo.fileName,
        tempEncryptedFile.path,
        fileInfo.fileSize,
      );
      if (thumbnail != null) {
        try {
          uploadStreamController?.add(
            const Right(
              EncryptingFileState(
                isThumbnail: true,
              ),
            ),
          );
          encryptedThumbnail = await encryptedService.encryptFile(
            fileInfo: thumbnail,
            outputFile: tempEncryptedThumbnailFile ?? File(''),
          );
          uploadStreamController?.add(
            const Right(
              EncryptedFileState(
                isThumbnail: true,
              ),
            ),
          );
        } catch (e) {
          uploadStreamController?.add(
            Left(EncryptFailedFileState(exception: e, isThumbnail: true)),
          );
        }
      }
    }
    Uri? uploadResp, thumbnailUploadResp;

    await _updateFakeSync(
      fakeImageEvent,
      fileSendingStatusKey,
      FileSendingStatus.uploading.name,
    );
    while (uploadResp == null ||
        (encryptedThumbnail != null && thumbnailUploadResp == null)) {
      try {
        final mediaApi = getIt.get<MediaAPI>();
        final response = await mediaApi.uploadFileMobile(
          fileInfo: fileInfo,
          cancelToken: cancelToken,
          onSendProgress: (receive, total) {
            if (uploadStreamController?.isClosed == true) return;
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
        if (response.contentUri != null) {
          uploadResp = Uri.parse(response.contentUri!);
        }
        if (uploadResp != null && thumbnail != null) {
          final thumbnailResponse = await mediaApi.uploadFileMobile(
            fileInfo: FileInfo(
              thumbnail.fileName,
              isRoomEncrypted()
                  ? tempEncryptedThumbnailFile?.path ?? ''
                  : thumbnail.filePath,
              thumbnail.fileSize,
            ),
            cancelToken: cancelToken,
            onSendProgress: (receive, total) {
              if (uploadStreamController?.isClosed == true) return;
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
          thumbnailUploadResp =
              Uri.tryParse(thumbnailResponse.contentUri ?? "");
        }
        uploadStreamController?.add(
          Right(
            UploadFileSuccessState(
              eventId: txid,
            ),
          ),
        );
      } on MatrixException catch (e) {
        await _updateFakeSync(
          fakeImageEvent,
          messageSendingStatusKey,
          EventStatus.error.name,
        );
        Logs().e('Error: $e');
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
        await _updateFakeSync(
          fakeImageEvent,
          messageSendingStatusKey,
          EventStatus.error.intValue,
        );
        Logs().e('Error: $e');
        Logs().e('Send File into room failed. Try again...');
        return null;
      }
    }

    if (encryptedFileInfo != null) {
      encryptedFileInfo = EncryptedFileInfo(
        key: encryptedFileInfo.key,
        version: encryptedFileInfo.version,
        initialVector: encryptedFileInfo.initialVector,
        hashes: encryptedFileInfo.hashes,
        url: uploadResp.toString(),
      );
      Logs().d('RoomExtension::EncryptedFileInfo: $encryptedFileInfo');
    }

    if (encryptedThumbnail != null) {
      encryptedThumbnail = EncryptedFileInfo(
        key: encryptedThumbnail.key,
        version: encryptedThumbnail.version,
        initialVector: encryptedThumbnail.initialVector,
        hashes: encryptedThumbnail.hashes,
        url: thumbnailUploadResp.toString(),
      );
      Logs().d('RoomExtension::EncryptedThumbnail: $encryptedThumbnail');
    }

    final blurHash = thumbnail?.filePath != null
        ? await runBenchmarked(
            '_generateBlurHash',
            () => _generateBlurHash(thumbnail!.filePath),
          )
        : null;

    final contentFromCaption = getEventContentFromMsgText(
      message: captionInfo ?? '',
      msgtype: msgType,
    );

    final contentCaptionFormat = contentFromCaption['formatted_body'] != null
        ? {
            'format': contentFromCaption['format'],
            'formatted_body': contentFromCaption['formatted_body'],
          }
        : null;

    // Send event
    final content = <String, dynamic>{
      'msgtype': msgType,
      'body': captionInfo ?? '',
      if (contentCaptionFormat != null) ...contentCaptionFormat,
      'filename': fileInfo.fileName,
      'url': uploadResp.toString(),
      if (encryptedFileInfo != null) 'file': encryptedFileInfo.toJson(),
      'info': {
        ...thumbnail?.metadata ?? {},
        ...fileInfo.metadata,
        if (thumbnail != null && encryptedThumbnail == null)
          'thumbnail_url': thumbnailUploadResp.toString(),
        if (thumbnail != null && encryptedThumbnail != null)
          'thumbnail_file': encryptedThumbnail.toJson(),
        if (thumbnail != null) 'thumbnail_info': thumbnail.metadata,
        if (blurHash != null) 'xyz.amorgan.blurhash': blurHash,
      },
      if (extraContent != null) ...extraContent,
    };
    final eventId = await sendEvent(
      content,
      txid: txid,
      inReplyTo: inReplyTo,
      editEventId: editEventId,
      sentDate: sentDate,
    );
    if (eventId != null) {
      await _copyFileInMemToAppDownloadsFolder(
        eventId: eventId,
        sendingEventId: txid,
        fileName: fileInfo.fileName,
      );
    }
    await Future.wait([
      tempEncryptedFile.delete(),
      if (tempThumbnailFile != null) tempThumbnailFile.delete(),
      if (tempEncryptedThumbnailFile != null)
        tempEncryptedThumbnailFile.delete(),
    ]);
    return eventId;
  }

  Future<File> _createThumbnailFile(Directory tempDir, String fileName) async =>
      await File('${tempDir.path}/$fileName').create();

  String _generateThumbnailFileName(
    String formattedDateTime,
    FileInfo fileInfo,
  ) =>
      '$formattedDateTime${fileInfo.fileName}.${AppConfig.imageCompressFormmat.name}';

  Future<ImageFileInfo> convertHeicToJpgImage(ImageFileInfo fileInfo) async {
    final convertedFilePath =
        StorageDirectoryManager.instance.convertFileExtension(
      fileInfo.filePath,
      'jpg',
    );
    final newPath = await HeifConverter.convert(
      fileInfo.filePath,
      output: convertedFilePath,
    );
    Logs().d('sendFileEvent::Heic converted to jpg', newPath);
    if (newPath != null) {
      final newConvertedFile = File(convertedFilePath);
      fileInfo = ImageFileInfo(
        newConvertedFile.path.split("/").last,
        newConvertedFile.path,
        await newConvertedFile.length(),
        width: fileInfo.width,
        height: fileInfo.height,
      );
    } else {
      Logs().e(
        'sendFileEvent::Error while converting heic to jpg:newPath is null',
      );
      throw Exception('sendFileEvent::Error while converting heic to jpg');
    }
    return fileInfo;
  }

  Future<void> _copyFileInMemToAppDownloadsFolder({
    required String sendingEventId,
    required String eventId,
    required String fileName,
  }) async {
    try {
      String? filePathInAppDownloads;
      if (isRoomEncrypted()) {
        filePathInAppDownloads =
            await StorageDirectoryManager.instance.getDecryptedFilePath(
          eventId: eventId,
          fileName: fileName,
        );
      } else {
        filePathInAppDownloads =
            await StorageDirectoryManager.instance.getFilePathInAppDownloads(
          eventId: eventId,
          fileName: fileName,
        );
      }

      final sendingFilePath = sendingFilePlaceholders[sendingEventId]?.filePath;
      final file = File(filePathInAppDownloads);
      if (await file.exists() || sendingFilePath == null) {
        return;
      }
      await file.create(recursive: true);
      await File(sendingFilePath).copy(filePathInAppDownloads);
      Logs().d('File copied in app downloads folder', filePathInAppDownloads);
    } catch (e) {
      Logs().e('Error while copying file in app downloads folder', e);
    }
  }

  Future<SyncUpdate> sendFakeFileInfoEvent(
    FileInfo fileInfo, {
    String messageType = MessageTypes.Image,
    required String txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
    DateTime? sentDate,
    String? captionInfo,
  }) async {
    final contentFromCaption = getEventContentFromMsgText(
      message: captionInfo ?? '',
      msgtype: messageType,
    );

    final contentCaptionFormat = contentFromCaption['formatted_body'] != null
        ? {
            'format': contentFromCaption['format'],
            'formatted_body': contentFromCaption['formatted_body'],
          }
        : null;
    // Create a fake Event object as a placeholder for the uploading file:
    final fakeImageEvent = SyncUpdate(
      nextBatch: '',
      rooms: RoomsUpdate(
        join: {
          id: JoinedRoomUpdate(
            timeline: TimelineUpdate(
              events: [
                MatrixEvent(
                  content: {
                    'msgtype': messageType,
                    'body': captionInfo ?? '',
                    'filename': fileInfo.fileName,
                    'info': {
                      ...fileInfo.metadata,
                    },
                    if (contentCaptionFormat != null) ...contentCaptionFormat,
                    if (extraContent != null) ...extraContent,
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
    await handleFakeSync(fakeImageEvent);
    return fakeImageEvent;
  }

  Future<void> handleFakeSync(
    SyncUpdate fakeImageEvent, {
    Direction? direction,
  }) async {
    if (client.database != null) {
      await client.database?.transaction(() async {
        await client.handleSync(fakeImageEvent, direction: direction);
      });
    } else {
      await client.handleSync(fakeImageEvent, direction: direction);
    }
  }

  Future<void> _storePlaceholderFile({
    required String txid,
    required FileAssetEntity assetEntity,
  }) async {
    // in order to have placeholder, this line must have,
    // otherwise the sending event will be removed from timeline
    final matrixFile = await assetEntity.toMatrixFile();
    if (matrixFile != null) {
      sendingFilePlaceholders[txid] = matrixFile;
    }
  }

  Future<Map<TransactionId, FakeSendingFileInfo>>
      sendPlaceholdersForImagePickerFiles({
    required List<FileAssetEntity> entities,
    String? captionInfo,
  }) async {
    final txIdMapToImageFile = <TransactionId, FakeSendingFileInfo>{};
    for (final entity in entities) {
      final fileInfo = await entity.toFileInfo();
      if (fileInfo != null) {
        final txid = client.generateUniqueTransactionId();

        await _storePlaceholderFile(
          txid: txid,
          assetEntity: entity,
        );

        final fakeImageEvent = await sendFakeFileInfoEvent(
          fileInfo,
          txid: txid,
          messageType: entity.messageType,
          captionInfo: captionInfo,
        );
        txIdMapToImageFile[txid] = FakeSendingFileInfo(
          fileInfo: fileInfo,
          fakeImageEvent: fakeImageEvent,
          messageType: entity.messageType,
        );
      }
    }
    return txIdMapToImageFile;
  }

  User? getUser(mxId) {
    return getParticipants().firstWhereOrNull((user) => user.id == mxId);
  }

  Future<ImageFileInfo?> _generateThumbnail(
    ImageFileInfo originalFile, {
    required String targetPath,
    required StreamController<Either<Failure, Success>>? uploadStreamController,
  }) async {
    try {
      Logs().d(
        'SendFileExtension::_generateThumbnail originalFile: ${originalFile.filePath} - targetPath: $targetPath',
      );
      uploadStreamController?.add(const Right(GeneratingThumbnailState()));

      final result = await FlutterImageCompress.compressAndGetFile(
        originalFile.filePath,
        targetPath,
        quality: AppConfig.thumbnailQuality,
        format: AppConfig.imageCompressFormmat,
      );
      if (result == null) return null;
      final size = await result.length();
      var width = originalFile.width;
      var height = originalFile.height;
      if (width == null || height == null || width == 0 || height == 0) {
        final imageDimension = await runBenchmarked(
          '_calculateImageDimension',
          () => _calculateImageDimension(result.path),
        );
        width = imageDimension.width.toInt();
        height = imageDimension.height.toInt();
      }
      uploadStreamController?.add(const Right(GenerateThumbnailSuccess()));
      return ImageFileInfo(
        result.name,
        result.path,
        size,
        width: width,
        height: height,
      );
    } catch (e) {
      uploadStreamController?.add(
        Left(GenerateThumbnailFailed(exception: e)),
      );
      Logs().e(
        'SendFileExtension::_generateThumbnail() Error while generating thumbnail',
        e,
      );
      return null;
    }
  }

  Future<String?> _generateBlurHash(String filePath) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        filePath,
        minHeight: AppConfig.blurHashSize,
        minWidth: AppConfig.blurHashSize,
      );
      final blurHash = await compute(
        (imageData) {
          final image = img.decodeJpg(imageData);
          return BlurHash.encode(image!);
        },
        result!,
      );
      return blurHash.hash;
    } catch (e) {
      Logs().e('_generateBlurHash::error', e);
      return null;
    }
  }

  Future<ImageFileInfo> _getThumbnailVideo(
    File tempThumbnailFile,
    VideoFileInfo fileInfo,
    String txid, {
    required StreamController<Either<Failure, Success>>? uploadStreamController,
  }) async {
    Logs().d('Video thumbnail generation started', fileInfo);
    uploadStreamController?.add(const Right(GeneratingThumbnailState()));
    final int fileSize;
    if (fileInfo.imagePlaceholderBytes.isNotEmpty) {
      await tempThumbnailFile.writeAsBytes(fileInfo.imagePlaceholderBytes);
      fileSize = fileInfo.imagePlaceholderBytes.lengthInBytes;
    } else {
      await VideoThumbnail.thumbnailFile(
        video: fileInfo.filePath,
        imageFormat: ImageFormat.JPEG,
        quality: AppConfig.thumbnailQuality,
        thumbnailPath: tempThumbnailFile.path,
      );
      fileSize = await tempThumbnailFile.length();
    }
    var width = fileInfo.width;
    var height = fileInfo.height;
    if (width == null || height == null) {
      try {
        final imageDimension = await _calculateImageBytesDimension(
          await tempThumbnailFile.readAsBytes(),
        );
        width = imageDimension.width.toInt();
        height = imageDimension.height.toInt();
      } catch (e) {
        uploadStreamController?.add(
          Left(GenerateThumbnailFailed(exception: e)),
        );
        Logs().e(
          '_getThumbnailVideo():: Error while calculating image dimension',
          e,
        );
      }
    }
    Logs().d('Video thumbnail generated', tempThumbnailFile.path);
    uploadStreamController?.add(const Right(GenerateThumbnailSuccess()));
    final newThumbnail = ImageFileInfo(
      tempThumbnailFile.path.split("/").last,
      tempThumbnailFile.path,
      fileSize,
      width: width,
      height: height,
    );
    return newThumbnail;
  }

  Future<void> _updateFakeSync(
    SyncUpdate fakeImageEvent,
    String key,
    Object? value,
  ) async {
    fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
        .unsigned![key] = value;
    await handleFakeSync(fakeImageEvent);
  }

  Future<Size> _calculateImageDimension(String filePath) {
    return Image.file(File(filePath)).calculateImageDimension();
  }

  Future<Size> _calculateImageBytesDimension(Uint8List bytes) {
    return Image.memory(bytes).calculateImageDimension();
  }

  bool isRoomEncrypted() {
    return encrypted && client.fileEncryptionEnabled;
  }

  Future<void> sendFakeMessage({
    required Map<String, Object?> content,
    required String messageId,
  }) async {
    final sentDate = DateTime.now();
    final syncUpdate = SyncUpdate(
      nextBatch: '',
      rooms: RoomsUpdate(
        join: {
          id: JoinedRoomUpdate(
            timeline: TimelineUpdate(
              events: [
                MatrixEvent(
                  content: content,
                  type: EventTypes.Message,
                  eventId: messageId,
                  senderId: client.userID!,
                  originServerTs: sentDate,
                  unsigned: {
                    messageSendingStatusKey: EventStatus.sending.intValue,
                    'transaction_id': messageId,
                  },
                ),
              ],
            ),
          ),
        },
      ),
    );
    await handleFakeSync(syncUpdate);
  }
}
