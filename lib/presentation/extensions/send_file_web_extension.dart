import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:matrix/matrix.dart';
import 'package:image/image.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:universal_html/html.dart' as html;

extension SendFileWebExtension on Room {
  Future<String?> sendFileOnWebEvent(
    MatrixFile file, {
    SyncUpdate? fakeImageEvent,
    String? txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    MatrixImageFile? thumbnail,
    Map<String, dynamic>? extraContent,
  }) async {
    txid ??= client.generateUniqueTransactionId();
    Image? img;
    if (file.bytes != null && file is MatrixImageFile) {
      img = decodeImage(file.bytes!);
      file = MatrixImageFile(
        name: file.name,
        width: img?.width,
        height: img?.height,
        bytes: file.bytes,
      );
    }
    sendingFilePlaceholders[txid] = MatrixImageFile(
      name: file.name,
      width: img?.width,
      height: img?.height,
      bytes: file.bytes,
    );
    fakeImageEvent ??= await sendFakeImageEvent(
      file,
      txid: txid,
      inReplyTo: inReplyTo,
      editEventId: editEventId,
      shrinkImageMaxDimension: shrinkImageMaxDimension,
      extraContent: extraContent,
    );
    // Check media config of the server before sending the file. Stop if the
    // Media config is unreachable or the file is bigger than the given maxsize.
    try {
      final mediaConfig = await client.getConfig();
      final maxMediaSize = mediaConfig.mUploadSize;
      Logs().d(
        'SendImage::sendImageFileEvent(): FileSized ${file.size} || maxMediaSize $maxMediaSize',
      );
      if (maxMediaSize != null && maxMediaSize < file.size) {
        throw FileTooBigMatrixException(file.size, maxMediaSize);
      }
    } catch (e) {
      Logs().d('Config error while sending file', e);
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
      thumbnail ??= await _generateThumbnail(file);
      if (thumbnail != null && file.size < thumbnail.size) {
        thumbnail = null; // in this case, the thumbnail is not usefull
      }
    } else if (file is MatrixVideoFile) {
      fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
              .unsigned![fileSendingStatusKey] =
          FileSendingStatus.generatingThumbnail.name;
      await handleImageFakeSync(fakeImageEvent);
      thumbnail ??= await _generateVideoThumbnail(file);
    }

    EncryptedFile? encryptedFile;
    MatrixFile? uploadFile;
    MatrixFile? uploadThumbnail = thumbnail;
    EncryptedFile? encryptedThumbnail;
    if (encrypted && client.fileEncryptionEnabled) {
      fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
          .unsigned![fileSendingStatusKey] = FileSendingStatus.encrypting.name;
      await handleImageFakeSync(fakeImageEvent);
      encryptedFile = await file.encrypt();
      uploadFile =
          MatrixFile.fromMimeType(bytes: encryptedFile!.data, name: 'crypt');
      if (thumbnail != null) {
        encryptedThumbnail = await thumbnail.encrypt();
        uploadThumbnail = MatrixFile.fromMimeType(
          bytes: encryptedThumbnail?.data,
          name: 'crypt',
        );
      }
    }
    Uri? uploadResp, thumbnailUploadResp;

    fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
        .unsigned![fileSendingStatusKey] = FileSendingStatus.uploading.name;
    while (
        uploadResp == null && uploadFile != null && uploadFile.bytes != null) {
      try {
        uploadResp = await client.uploadContent(
          uploadFile.bytes!,
          filename: uploadFile.name,
          contentType: uploadFile.mimeType,
        );
        thumbnailUploadResp =
            uploadThumbnail != null && uploadThumbnail.bytes != null
                ? await client.uploadContent(
                    uploadThumbnail.bytes!,
                    filename: uploadThumbnail.name,
                    contentType: uploadThumbnail.mimeType,
                  )
                : null;
      } on MatrixException catch (e) {
        fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
            .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
        await handleImageFakeSync(fakeImageEvent);
        Logs().v('Error: $e');
        rethrow;
      } catch (e) {
        fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
            .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
        await handleImageFakeSync(fakeImageEvent);
        Logs().v('Error: $e');
        Logs().v('Send File into room failed. Try again...');
        return null;
      }
    }
    final duration =
        file is MatrixVideoFile ? await _getVideoDuration(file) : null;
    // Send event
    final content = <String, dynamic>{
      'msgtype': file.msgType,
      'body': file.name,
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
            'kty': 'oct'
          },
          'iv': encryptedFile.iv,
          'hashes': {'sha256': encryptedFile.sha256}
        },
      'info': {
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
              'kty': 'oct'
            },
            'iv': encryptedThumbnail.iv,
            'hashes': {'sha256': encryptedThumbnail.sha256},
          },
        if (thumbnail != null) 'thumbnail_info': thumbnail.info,
        if (thumbnail?.blurhash != null)
          'xyz.amorgan.blurhash': thumbnail?.blurhash,
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
    return eventId;
  }

  Future<SyncUpdate> sendFakeImageEvent(
    MatrixFile file, {
    required String txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    // sendingFileThumbnails[txid] =  MatrixImageFile(bytes: file.bytes, name: file.name);

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
                    'body': file.name,
                    'filename': file.name,
                  },
                  type: EventTypes.Message,
                  eventId: txid,
                  senderId: client.userID!,
                  originServerTs: DateTime.now(),
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
    if (client.database != null) {
      await client.database?.transaction(() async {
        await client.handleSync(fakeImageEvent, direction: direction);
      });
    } else {
      await client.handleSync(fakeImageEvent, direction: direction);
    }
  }

  Future<MatrixImageFile?> _generateThumbnail(
    MatrixImageFile originalFile,
  ) async {
    if (originalFile.bytes == null) return null;
    try {
      final result = await FlutterImageCompress.compressWithList(
        originalFile.bytes!,
        quality: 70,
      );

      final image = decodeImage(result);
      final blurHash = image != null ? BlurHash.encode(image) : null;

      return MatrixImageFile(
        bytes: result,
        name: originalFile.name,
        mimeType: originalFile.mimeType,
        width: originalFile.width,
        height: originalFile.height,
        blurhash: blurHash?.hash,
      );
    } catch (e) {
      Logs().e('Error while generating thumbnail', e);
      return null;
    }
  }

  Future<MatrixImageFile?> _generateVideoThumbnail(
    MatrixVideoFile originalFile,
  ) async {
    if (originalFile.bytes == null) return null;
    try {
      final blob = html.Blob([originalFile.bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final result = await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        quality: AppConfig.thumbnailQuality,
      );
      final image = decodeImage(result);
      final blurHash = image != null ? BlurHash.encode(image) : null;

      return MatrixImageFile(
        bytes: result,
        name: originalFile.name,
        mimeType: originalFile.mimeType,
        width: originalFile.width,
        height: originalFile.height,
        blurhash: blurHash?.hash,
      );
    } catch (e) {
      Logs().e('Error while generating thumbnail', e);
      return null;
    }
  }

  Future<int?> _getVideoDuration(
    MatrixVideoFile originalFile,
  ) async {
    if (originalFile.bytes == null) {
      return null;
    }
    try {
      final blob = html.Blob([originalFile.bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(url));
      await videoPlayerController.initialize();
      return videoPlayerController.value.duration.inMilliseconds;
    } catch (e) {
      Logs().e('Error while generating thumbnail', e);
      return null;
    }
  }
}
