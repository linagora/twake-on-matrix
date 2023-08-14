import 'dart:io';

import 'package:collection/collection.dart';
import 'package:fluffychat/data/network/upload_file/file_info_extension.dart';
import 'package:fluffychat/data/network/upload_file/upload_file_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/fake_sending_file_info.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

typedef TransactionId = String;

typedef MessageType = String;

typedef FakeImageEvent = SyncUpdate;

extension SendFileExtension on Room {
  static const maxImagesCacheInRoom = 10;

  Future<String?> sendFileEvent(
    FileInfo fileInfo, {
    String msgType = MessageTypes.Image,
    SyncUpdate? fakeImageEvent,
    String? txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    FileInfo tempfileInfo = fileInfo;
    txid ??= client.generateUniqueTransactionId();
    fakeImageEvent ??= await sendFakeImagePickerFileEvent(
      fileInfo,
      txid: txid,
      messageType: msgType,
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
        'SendImage::sendFileEvent(): FileSized ${fileInfo.fileSize} || maxMediaSize $maxMediaSize',
      );
      if (maxMediaSize != null && maxMediaSize < fileInfo.fileSize) {
        throw FileTooBigMatrixException(fileInfo.fileSize, maxMediaSize);
      }
    } catch (e) {
      Logs().d('Config error while sending file', e);
      fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
          .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
      await handleImageFakeSync(fakeImageEvent);
      rethrow;
    }

    final encryptedService = EncryptedService();
    final tempDir = await getTemporaryDirectory();
    final formattedDateTime = DateTime.now().getFormattedCurrentDateTime();
    final tempEncryptedFile =
        await File('${tempDir.path}/$formattedDateTime${fileInfo.fileName}')
            .create();
    EncryptedFileInfo? encryptedFileInfo;
    if (encrypted && client.fileEncryptionEnabled) {
      fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
          .unsigned![fileSendingStatusKey] = FileSendingStatus.encrypting.name;
      await handleImageFakeSync(fakeImageEvent);

      encryptedFileInfo = await encryptedService.encryptFile(
        fileInfo: fileInfo,
        outputFile: tempEncryptedFile,
      );
      tempfileInfo = FileInfo(
        fileInfo.fileName,
        tempEncryptedFile.path,
        fileInfo.fileSize,
      );
    }
    Uri? uploadResp;

    fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
        .unsigned![fileSendingStatusKey] = FileSendingStatus.uploading.name;
    while (uploadResp == null) {
      try {
        final uploadFileApi = getIt.get<UploadFileAPI>();
        final response = await uploadFileApi.uploadFile(fileInfo: tempfileInfo);
        if (response.contentUri != null) {
          uploadResp = Uri.parse(response.contentUri!);
        }
      } on MatrixException catch (e) {
        fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
            .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
        await handleImageFakeSync(fakeImageEvent);
        Logs().e('Error: $e');
        rethrow;
      } catch (e) {
        fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
            .unsigned![messageSendingStatusKey] = EventStatus.error.intValue;
        await handleImageFakeSync(fakeImageEvent);
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

    // Send event
    final content = <String, dynamic>{
      'msgtype': msgType,
      'body': fileInfo.fileName,
      'filename': fileInfo.fileName,
      'url': uploadResp.toString(),
      if (encryptedFileInfo != null) 'file': encryptedFileInfo.toJson(),
      'info': {
        ...fileInfo.metadata,
      },
      if (extraContent != null) ...extraContent,
    };
    final eventId = await sendEvent(
      content,
      txid: txid,
      inReplyTo: inReplyTo,
      editEventId: editEventId,
    );
    await tempEncryptedFile.delete();
    return eventId;
  }

  Future<SyncUpdate> sendFakeImagePickerFileEvent(
    FileInfo fileInfo, {
    String messageType = MessageTypes.Image,
    required String txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
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
                    'body': fileInfo.fileName,
                    'filename': fileInfo.fileName,
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
    await handleImageFakeSync(fakeImageEvent);
    return fakeImageEvent;
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

        final fakeImageEvent = await sendFakeImagePickerFileEvent(
          fileInfo,
          txid: txid,
          messageType: entity.messageType,
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
}
