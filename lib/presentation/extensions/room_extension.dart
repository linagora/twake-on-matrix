import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/file_send_request_credentials.dart';

extension SendImage on Room {

  static const maxSendingImage = 20;

  Future<String?> sendImageFileEvent(
    MatrixFile file, {
    String? txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    if (sendingFileThumbnails.entries.length > maxSendingImage) {
      sendingFileThumbnails.clear();
    }
    if (sendingFilePlaceholders.entries.length > maxSendingImage) {
      sendingFilePlaceholders.clear();
    }

    txid ??= client.generateUniqueTransactionId();
    sendingFilePlaceholders[txid] = file;
    sendingFileThumbnails[txid] =  MatrixImageFile(bytes: file.bytes, name: file.name);

    // Create a fake Event object as a placeholder for the uploading file:
    final syncUpdate = SyncUpdate(
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
                    ...FileSendRequestCredentials(
                      inReplyTo: inReplyTo?.eventId,
                      editEventId: editEventId,
                      shrinkImageMaxDimension: shrinkImageMaxDimension,
                      extraContent: extraContent,
                    ).toJson(),
                  },
                ),
              ],
            ),
          ),
        },
      ),
    );
    await handleImageFakeSync(syncUpdate);
    // Check media config of the server before sending the file. Stop if the
    // Media config is unreachable or the file is bigger than the given maxsize.
    try {
      final mediaConfig = await client.getConfig();
      final maxMediaSize = mediaConfig.mUploadSize;
      if (maxMediaSize != null && maxMediaSize < file.bytes.lengthInBytes) {
        throw FileTooBigMatrixException(file.bytes.lengthInBytes, maxMediaSize);
      }
    } catch (e) {
      Logs().d('Config error while sending file', e);
      syncUpdate.rooms!.join!.values.first.timeline!.events!.first
          .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
      await handleImageFakeSync(syncUpdate);
      rethrow;
    }

    MatrixFile uploadFile = file; // ignore: omit_local_variable_types
    var thumbnail = sendingFileThumbnails[txid];
    // computing the thumbnail in case we can
    if (file is MatrixImageFile && shrinkImageMaxDimension != null) {
      file = await MatrixImageFile.shrink(
        bytes: file.bytes,
        name: file.name,
        maxDimension: shrinkImageMaxDimension,
        customImageResizer: client.customImageResizer,
        nativeImplementations: client.nativeImplementations,
      );

      if (thumbnail != null && file.size < thumbnail.size) {
        thumbnail = null; // in this case, the thumbnail is not usefull
      }
    }

    MatrixFile? uploadThumbnail = thumbnail; // ignore: omit_local_variable_types
    EncryptedFile? encryptedFile;
    EncryptedFile? encryptedThumbnail;
    if (encrypted && client.fileEncryptionEnabled) {
      syncUpdate.rooms!.join!.values.first.timeline!.events!.first
          .unsigned![fileSendingStatusKey] = FileSendingStatus.encrypting.name;
      await handleImageFakeSync(syncUpdate);
      encryptedFile = await file.encrypt();
      uploadFile = encryptedFile.toMatrixFile();

      if (thumbnail != null) {
        encryptedThumbnail = await thumbnail.encrypt();
        uploadThumbnail = encryptedThumbnail.toMatrixFile();
      }
    }
    Uri? uploadResp, thumbnailUploadResp;

    final timeoutDate = DateTime.now();

    syncUpdate.rooms!.join!.values.first.timeline!.events!.first
        .unsigned![fileSendingStatusKey] = FileSendingStatus.uploading.name;
    while (uploadResp == null ||
        (uploadThumbnail != null && thumbnailUploadResp == null)) {
      try {
        uploadResp = await client.uploadContent(
          uploadFile.bytes,
          filename: uploadFile.name,
          contentType: uploadFile.mimeType,
        );
        thumbnailUploadResp = uploadThumbnail != null
            ? await client.uploadContent(
                uploadThumbnail.bytes,
                filename: uploadThumbnail.name,
                contentType: uploadThumbnail.mimeType,
              )
            : null;
      } on MatrixException catch (_) {
        syncUpdate.rooms!.join!.values.first.timeline!.events!.first
            .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
        await handleImageFakeSync(syncUpdate);
        rethrow;
      } catch (_) {
        if (DateTime.now().isAfter(timeoutDate)) {
          syncUpdate.rooms!.join!.values.first.timeline!.events!.first
              .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
          await handleImageFakeSync(syncUpdate);
          rethrow;
        }
        Logs().v('Send File into room failed. Try again...');
        await Future.delayed(const Duration(seconds: 1));
      }
    }

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
            'hashes': {'sha256': encryptedThumbnail.sha256}
          },
        if (thumbnail != null) 'thumbnail_info': thumbnail.info,
        if (thumbnail?.blurhash != null &&
            file is MatrixImageFile &&
            file.blurhash == null)
          'xyz.amorgan.blurhash': thumbnail!.blurhash
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

  Future<void> handleImageFakeSync(SyncUpdate syncUpdate,
      {Direction? direction}) async {
    if (client.database != null) {
      await client.database?.transaction(() async {
        await client.handleSync(syncUpdate, direction: direction);
      });
    } else {
      await client.handleSync(syncUpdate, direction: direction);
    }
  }
}