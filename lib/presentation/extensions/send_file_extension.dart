import 'dart:async';
import 'dart:io';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide id;
import 'package:dio/dio.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/data/network/extensions/file_info_extension.dart';
import 'package:fluffychat/data/network/media/cancel_exception.dart';
import 'package:fluffychat/data/network/media/file_not_exist_exception.dart';
import 'package:fluffychat/data/network/media/media_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/file_info/image_file_info.dart';
import 'package:fluffychat/domain/model/file_info/video_file_info.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/presentation/extensions/image_extension.dart';
import 'package:fluffychat/presentation/fake_sending_file_info.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/exception/upload_exception.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/manager/storage_directory_manager.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart';
import 'package:image/image.dart' as img;
import 'package:matrix/matrix.dart';

// ignore: implementation_imports
import 'package:matrix/src/utils/run_benchmarked.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

typedef TransactionId = String;

typedef MessageType = String;

typedef FakeImageEvent = SyncUpdate;

/// Maximum file size (in bytes) to load into memory for placeholder creation.
/// Large files beyond this limit will skip placeholder to prevent OOM.
/// Set to 100MB to balance UX (showing placeholders) with memory safety.
const int maxPlaceholderFileSize = 100 * 1024 * 1024; // 100MB

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
    Map<String, dynamic>? uploadInfo,
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
        'SendImage::sendFileEvent(): file ${fileInfo.fileName}',
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
              txid: txid,
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
      'sendFileEventMobile::File: ${fileInfo.fileName} - mimeType: ${fileInfo.mimeType}',
    );
    if (TwakeMimeTypeExtension.heicMimeTypes.contains(fileInfo.mimeType) &&
        fileInfo is ImageFileInfo) {
      try {
        fileInfo = await convertHeicToJpgImage(fileInfo, tempDir);
      } catch (e) {
        Logs().e('sendFileEventMobile::Error while converting heic to jpg', e);
      }

      final formattedDateTime = DateTime.now().getFormattedCurrentDateTime();
      final fileName = _generateThumbnailFileName(formattedDateTime, fileInfo);
      final targetPath = await _createThumbnailFile(tempDir, fileName);
      Logs().d(
        'sendFileEventMobile::Thumbnail target File Path: ${targetPath.path} - file name: $fileName',
      );
      final generatedThumbnail = await _generateThumbnail(
        fileInfo as ImageFileInfo,
        targetPath: targetPath,
        uploadStreamController: uploadStreamController,
      );
      if (generatedThumbnail != null) {
        thumbnail = generatedThumbnail;
      }
    }

    // Note: Encryption via EncryptedService - using matrix SDK's encrypt() method
    final formattedDateTime = DateTime.now().getFormattedCurrentDateTime();
    File? tempThumbnailFile;
    if (msgType == MessageTypes.Image || msgType == MessageTypes.Video) {
      tempThumbnailFile = await File(
        '${tempDir.path}/${formattedDateTime}_${fileInfo.fileName}_thumbnail.jpg',
      ).create();
    }

    if (fileInfo is! ImageFileInfo && msgType == MessageTypes.Image) {
      fileInfo = ImageFileInfo(
        fileInfo.fileName,
        filePath: fileInfo.filePath,
        bytes: fileInfo.bytes,
      );
    } else if (fileInfo is! VideoFileInfo && msgType == MessageTypes.Video) {
      fileInfo = VideoFileInfo(
        fileInfo.fileName,
        filePath: fileInfo.filePath,
        bytes: fileInfo.bytes,
        imagePlaceholderBytes: Uint8List(0),
      );
    }

    // computing the thumbnail in case we can
    if (fileInfo is ImageFileInfo &&
        (thumbnail == null || shrinkImageMaxDimension != null)) {
      await _updateFakeSync(
        fakeImageEvent,
        fileSendingStatusKey,
        FileSendingStatus.generatingThumbnail.name,
      );
      if (tempThumbnailFile != null) {
        thumbnail ??= await _generateThumbnail(
          fileInfo,
          targetPath: tempThumbnailFile,
          uploadStreamController: uploadStreamController,
        );
      }
      if (thumbnail != null) {
        fileInfo = ImageFileInfo(
          fileInfo.fileName,
          filePath: fileInfo.filePath,
          bytes: fileInfo.bytes,
          width: thumbnail.width,
          height: thumbnail.height,
        );
      }
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
        uploadInfo: uploadInfo,
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
      if (tempThumbnailFile != null) {
        thumbnail ??= await _getThumbnailVideo(
          tempThumbnailFile,
          fileInfo,
          txid,
          uploadStreamController: uploadStreamController,
        );
      }
      if (fileInfo.width == null ||
          fileInfo.height == null ||
          fileInfo.width == 0 ||
          fileInfo.height == 0) {
        fileInfo = VideoFileInfo(
          fileInfo.fileName,
          filePath: fileInfo.filePath,
          bytes: fileInfo.bytes,
          imagePlaceholderBytes: fileInfo.imagePlaceholderBytes,
          width: thumbnail?.width,
          height: thumbnail?.height,
        );
        if (fileInfo.imagePlaceholderBytes.isNotEmpty) {
          storePlaceholderFileInMem(
            fileInfo: fileInfo,
            txid: txid,
          );
        } else if (thumbnail != null) {
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
          uploadInfo: uploadInfo,
        );
      }
    }

    EncryptedFile? encryptedFileInfo;
    EncryptedFile? encryptedThumbnail;
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
        // Create a MatrixFile for encryption
        final matrixFile = MatrixFile(
          bytes: await _resolveBytes(fileInfo),
          name: fileInfo.fileName,
          mimeType: fileInfo.mimeType,
        );
        encryptedFileInfo = await matrixFile.encrypt();
        uploadStreamController?.add(
          const Right(EncryptedFileState()),
        );
      } catch (e) {
        uploadStreamController?.add(
          Left(EncryptFailedFileState(exception: e)),
        );
        await _updateFakeSync(
          fakeImageEvent,
          messageSendingStatusKey,
          EventStatus.error.intValue,
        );
        return null;
      }

      fileInfo = FileInfo(
        fileInfo.fileName,
        filePath: fileInfo.filePath,
        bytes: encryptedFileInfo.data,
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
          // Create a MatrixFile for encryption
          final thumbnailMatrixFile = MatrixFile(
            bytes: await _resolveBytes(thumbnail),
            name: thumbnail.fileName,
            mimeType: thumbnail.mimeType,
          );
          encryptedThumbnail = await thumbnailMatrixFile.encrypt();
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
          // Proceed without thumbnail on encryption failure
          Logs().e(
            'Thumbnail encryption failed, proceeding without thumbnail',
            e,
          );
          thumbnail = null;
          encryptedThumbnail = null;
        }
      }
    }
    Uri? uploadResp, thumbnailUploadResp;

    await _updateFakeSync(
      fakeImageEvent,
      fileSendingStatusKey,
      FileSendingStatus.uploading.name,
    );

    int retryCount = 0;
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 2);

    while (uploadResp == null ||
        (encryptedThumbnail != null && thumbnailUploadResp == null)) {
      if (retryCount >= maxRetries) {
        await _updateFakeSync(
          fakeImageEvent,
          messageSendingStatusKey,
          EventStatus.error.intValue,
        );
        uploadStreamController?.add(
          Left(
            UploadFileFailedState(
              exception: UploadException(
                error: 'Upload failed after $maxRetries retries',
              ),
            ),
          ),
        );
        Logs().e('Upload failed after $maxRetries retries');
        return null;
      }

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
        } else {
          // contentUri is null, increment retry and continue
          retryCount++;
          Logs().w(
            'Upload returned null contentUri, retry $retryCount/$maxRetries',
          );
          if (retryCount < maxRetries) {
            await Future.delayed(baseDelay * retryCount);
          }
          continue;
        }

        if (thumbnail != null) {
          final thumbnailResponse = await mediaApi.uploadFileMobile(
            fileInfo: FileInfo(
              thumbnail.fileName,
              filePath: thumbnail.filePath,
              bytes: encryptedThumbnail?.data ?? thumbnail.bytes,
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
          if (thumbnailUploadResp == null &&
              thumbnailResponse.contentUri == null) {
            // Thumbnail upload returned null, increment retry
            retryCount++;
            Logs().w(
              'Thumbnail upload returned null contentUri, retry $retryCount/$maxRetries',
            );
            uploadResp = null; // Reset to retry both
            if (retryCount < maxRetries) {
              await Future.delayed(baseDelay * retryCount);
            }
            continue;
          }
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
                txid: txid,
              ),
            ),
          );
          return null;
        } else if (e is FileNotExistException) {
          Logs().e('File not exist: ${e.path}');
          uploadStreamController?.add(
            Left(UploadFileFailedState(exception: e, txid: txid)),
          );
          return null;
        }
        retryCount++;
        Logs().e('Error: $e');
        Logs().e('Send File into room failed. Retry $retryCount/$maxRetries');
        if (retryCount >= maxRetries) {
          await _updateFakeSync(
            fakeImageEvent,
            messageSendingStatusKey,
            EventStatus.error.intValue,
          );
          return null;
        }
        // Exponential backoff
        await Future.delayed(baseDelay * retryCount);
      }
    }

    if (encryptedFileInfo != null) {
      encryptedFileInfo = EncryptedFile(
        data: encryptedFileInfo.data,
        iv: encryptedFileInfo.iv,
        k: encryptedFileInfo.k,
        sha256: encryptedFileInfo.sha256,
      );
      Logs().d('RoomExtension::EncryptedFileInfo set with upload URL');
    }

    if (encryptedThumbnail != null) {
      encryptedThumbnail = EncryptedFile(
        data: encryptedThumbnail.data,
        iv: encryptedThumbnail.iv,
        k: encryptedThumbnail.k,
        sha256: encryptedThumbnail.sha256,
      );
      Logs().d('RoomExtension::EncryptedThumbnail set with upload URL');
    }

    final blurHash = thumbnail != null
        ? await runBenchmarked(
            '_generateBlurHash',
            () async =>
                _generateBlurHashFromBytes(await _resolveBytes(thumbnail!)),
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
      if (encryptedFileInfo != null)
        'file': {
          'url': uploadResp.toString(),
          'v': 'v2',
          'key': {
            'kty': 'oct',
            'key_ops': ['encrypt', 'decrypt'],
            'alg': 'A256CTR',
            'k': encryptedFileInfo.k,
            'ext': true,
          },
          'iv': encryptedFileInfo.iv,
          'hashes': {
            'sha256': encryptedFileInfo.sha256,
          },
        },
      'info': {
        ...thumbnail?.metadata ?? {},
        ...fileInfo.metadata,
        if (thumbnail != null && encryptedThumbnail == null)
          'thumbnail_url': thumbnailUploadResp.toString(),
        if (thumbnail != null && encryptedThumbnail != null)
          'thumbnail_file': {
            'url': thumbnailUploadResp.toString(),
            'v': 'v2',
            'key': {
              'kty': 'oct',
              'key_ops': ['encrypt', 'decrypt'],
              'alg': 'A256CTR',
              'k': encryptedThumbnail.k,
              'ext': true,
            },
            'iv': encryptedThumbnail.iv,
            'hashes': {
              'sha256': encryptedThumbnail.sha256,
            },
          },
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
    );
    if (eventId != null) {
      await _copyFileInMemToAppDownloadsFolder(
        eventId: eventId,
        sendingEventId: txid,
        fileName: fileInfo.fileName,
      );
    }
    await Future.wait([
      if (tempThumbnailFile != null) tempThumbnailFile.delete(),
    ]);
    return eventId;
  }

  /// Resolves bytes from FileInfo, always returning current bytes.
  /// This ensures we don't use stale bytes after fileInfo mutations (e.g., HEIC conversion).
  Future<Uint8List> _resolveBytes(FileInfo fileInfo) async {
    if (fileInfo.bytes != null) return fileInfo.bytes!;
    if (fileInfo.filePath != null) {
      return File(fileInfo.filePath!).readAsBytes();
    }
    throw StateError('No bytes or filePath for ${fileInfo.fileName}');
  }

  Future<File> _createThumbnailFile(Directory tempDir, String fileName) async =>
      await File('${tempDir.path}/$fileName').create();

  String _generateThumbnailFileName(
    String formattedDateTime,
    FileInfo fileInfo,
  ) =>
      '$formattedDateTime${fileInfo.fileName}.${AppConfig.imageCompressFormmat.name}';

  Future<ImageFileInfo> convertHeicToJpgImage(
    ImageFileInfo fileInfo,
    Directory tempDir,
  ) async {
    try {
      Logs().d('convertHeicToJpgImage: Starting HEIC conversion');
      Uint8List bytes = Uint8List(0);
      if (fileInfo.bytes != null) {
        bytes = fileInfo.bytes!;
      } else if (fileInfo.filePath != null) {
        bytes = await File(fileInfo.filePath!).readAsBytes();
      }

      // Convert HEIC to JPG using heic_to_png_jpg package
      final convertedBytes = await HeicConverter.convertToJPG(
        heicData: bytes,
      );

      return ImageFileInfo(
        fileInfo.fileName,
        bytes: convertedBytes,
        width: fileInfo.width,
        height: fileInfo.height,
      );
    } catch (e) {
      Logs().e('convertHeicToJpgImage: Error during conversion', e);
      rethrow;
    }
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

      final sendingFile = sendingFilePlaceholders[sendingEventId];
      final file = File(filePathInAppDownloads);
      if (await file.exists() || sendingFile == null) {
        return;
      }
      await file.create(recursive: true);
      await file.writeAsBytes(sendingFile.bytes);
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
    Map<String, dynamic>? uploadInfo,
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
                    'info': <String, dynamic>{
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
                    if (uploadInfo != null) 'upload_info': uploadInfo,
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
    await client.handleSync(fakeImageEvent, direction: direction);
  }

  Future<void> _storePlaceholderFile({
    required String txid,
    required FileAssetEntity assetEntity,
    required FileInfo fileInfo,
  }) async {
    // Check file size before loading into memory to prevent OOM on large files
    final fileSize = fileInfo.fileSize;

    if (fileSize > maxPlaceholderFileSize) {
      Logs().w(
        '_storePlaceholderFile: Skipping placeholder for large file '
        '(${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB). '
        'File will upload without in-memory placeholder to prevent OOM.',
      );
      return;
    }

    // in order to have placeholder, this line must have,
    // otherwise the sending event will be removed from timeline
    final matrixFile =
        await assetEntity.toMatrixFile() ?? await fileInfo.toMatrixFile();
    sendingFilePlaceholders[txid] = switch (fileInfo.msgType) {
      MessageTypes.Image => MatrixImageFile(
          bytes: matrixFile.bytes,
          name: matrixFile.name,
          mimeType: matrixFile.mimeType,
        ),
      MessageTypes.Video => MatrixVideoFile(
          bytes: matrixFile.bytes,
          name: matrixFile.name,
          mimeType: matrixFile.mimeType,
        ),
      _ => matrixFile,
    };
  }

  Future<Map<TransactionId, FakeSendingFileInfo>>
      sendPlaceholdersForImagePickerFiles({
    required List<FileAssetEntity> entities,
    String? captionInfo,
    Event? inReplyTo,
  }) async {
    final txIdMapToImageFile = <TransactionId, FakeSendingFileInfo>{};
    for (final entity in entities) {
      final fileInfo = await entity.toFileInfo();
      if (fileInfo != null) {
        final txid = client.generateUniqueTransactionId();

        await _storePlaceholderFile(
          txid: txid,
          assetEntity: entity,
          fileInfo: fileInfo,
        );

        final fakeImageEvent = await sendFakeFileInfoEvent(
          fileInfo,
          txid: txid,
          messageType: entity.messageType,
          captionInfo: captionInfo,
          inReplyTo: inReplyTo,
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
    required File targetPath,
    required StreamController<Either<Failure, Success>>? uploadStreamController,
  }) async {
    try {
      Logs().d(
        'SendFileExtension::_generateThumbnail originalFile: ${originalFile.fileName} - targetPath: ${targetPath.path}',
      );
      uploadStreamController?.add(const Right(GeneratingThumbnailState()));
      Uint8List bytes = Uint8List(0);
      if (originalFile.bytes != null) {
        bytes = originalFile.bytes!;
      } else if (originalFile.filePath != null) {
        bytes = await File(originalFile.filePath!).readAsBytes();
      }

      final result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: AppConfig.thumbnailQuality,
        format: AppConfig.imageCompressFormmat,
      );
      if (result.isEmpty) return null;
      await targetPath.writeAsBytes(result);
      var width = originalFile.width;
      var height = originalFile.height;
      if (width == null || height == null || width == 0 || height == 0) {
        final imageDimension = await runBenchmarked(
          '_calculateImageDimension',
          () => _calculateImageBytesDimension(result),
        );
        width = imageDimension.width.toInt();
        height = imageDimension.height.toInt();
      }
      uploadStreamController?.add(const Right(GenerateThumbnailSuccess()));
      return ImageFileInfo(
        targetPath.path.split('/').last,
        filePath: targetPath.path,
        bytes: result,
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

  Future<String?> _generateBlurHashFromBytes(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: AppConfig.blurHashSize,
        minWidth: AppConfig.blurHashSize,
      );
      final blurHash = await compute(
        (imageData) {
          final image = img.decodeJpg(imageData);
          return BlurHash.encode(image!);
        },
        result,
      );
      return blurHash.hash;
    } catch (e) {
      Logs().e('_generateBlurHashFromBytes::error', e);
      return null;
    }
  }

  Future<ImageFileInfo?> _getThumbnailVideo(
    File tempThumbnailFile,
    VideoFileInfo fileInfo,
    String txid, {
    required StreamController<Either<Failure, Success>>? uploadStreamController,
  }) async {
    Logs().d('Video thumbnail generation started', fileInfo);
    uploadStreamController?.add(const Right(GeneratingThumbnailState()));
    if (fileInfo.imagePlaceholderBytes.isNotEmpty) {
      await tempThumbnailFile.writeAsBytes(fileInfo.imagePlaceholderBytes);
    } else if (fileInfo.filePath != null) {
      await VideoThumbnail.thumbnailFile(
        video: fileInfo.filePath!,
        imageFormat: AppConfig.videoThumbnailFormat,
        quality: AppConfig.thumbnailQuality,
        thumbnailPath: tempThumbnailFile.path,
      );
    } else {
      return null;
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
    final thumbnailBytes = await tempThumbnailFile.readAsBytes();
    final newThumbnail = ImageFileInfo(
      tempThumbnailFile.path.split('/').last,
      filePath: tempThumbnailFile.path,
      bytes: thumbnailBytes,
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
