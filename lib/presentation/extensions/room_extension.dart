import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide id;
import 'package:fluffychat/data/network/upload_file/file_info_extension.dart';
import 'package:fluffychat/data/network/upload_file/upload_file_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/extensions/asset_entity_extension.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/presentation/model/presentation_search.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/src/utils/file_send_request_credentials.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:matrix/src/utils/file_send_request_credentials.dart';

typedef TransactionId = String;

typedef FakeImageEvent = SyncUpdate;
extension SendImage on Room {

  static const maxImagesCacheInRoom = 10;

  Future<String?> sendImageFileEvent(
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
    fakeImageEvent ??= await sendFakeImageEvent(
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
      Logs().d('SendImage::sendImageFileEvent(): FileSized ${fileInfo.fileSize} || maxMediaSize $maxMediaSize');
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
    final tempEncryptedFile = await File('${tempDir.path}/$formattedDateTime${fileInfo.fileName}').create();
    EncryptedFileInfo? encryptedFileInfo;
    if (encrypted && client.fileEncryptionEnabled) {
      fakeImageEvent.rooms!.join!.values.first.timeline!.events!.first
          .unsigned![fileSendingStatusKey] = FileSendingStatus.encrypting.name;
      await handleImageFakeSync(fakeImageEvent);

      encryptedFileInfo = await encryptedService.encryptFile(
        fileInfo: fileInfo,
        outputFile: tempEncryptedFile,
      );
      tempfileInfo = FileInfo(fileInfo.fileName, tempEncryptedFile.path, fileInfo.fileSize);
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
      if (encryptedFileInfo != null)
        'file': encryptedFileInfo.toJson(),
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

  Future<SyncUpdate> sendFakeImageEvent(
    FileInfo fileInfo, {
    String messageType = MessageTypes.Image,
    required String txid,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    // in order to have placeholder, this line must have,
    // otherwise the sending event will be removed from timeline
    sendingFilePlaceholders[txid] = MatrixFile(
      name: fileInfo.fileName,
      filePath: fileInfo.filePath,
    );
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
    await handleImageFakeSync(fakeImageEvent);
    return fakeImageEvent;
  }

  Future<void> handleImageFakeSync(SyncUpdate fakeImageEvent,
      {Direction? direction}) async {
    if (client.database != null) {
      await client.database?.transaction(() async {
        await client.handleSync(fakeImageEvent, direction: direction);
      });
    } else {
      await client.handleSync(fakeImageEvent, direction: direction);
    }
  }

  Future<Tuple2<Map<TransactionId, FileInfo>, Map<TransactionId, FakeImageEvent>>> sendPlaceholdersForImages({
    required List<AssetEntity> entities,
  }) async {
    // ignore: prefer_const_constructors
    final txIdMapToImageFile = Tuple2<Map<TransactionId, FileInfo>, Map<TransactionId, FakeImageEvent>>({}, {});
    for (final entity in entities) {
      final fileInfo = await entity.toFileInfo();

      if (fileInfo != null) {
        final txid = client.generateUniqueTransactionId();
        final fakeImageEvent = await sendFakeImageEvent(fileInfo, txid: txid);
        txIdMapToImageFile.value1[txid] = fileInfo;
        txIdMapToImageFile.value2[txid] = fakeImageEvent;
      }
    }
    return txIdMapToImageFile;
  }

  User? getUser(mxId) {
    return getParticipants().firstWhereOrNull((user) => user.id == mxId);
  }

  bool isShowInChatList() {
    return _isDirectChatHaveMessage() || _isGroupChat();
  }

  bool _isGroupChat() {
    return !isDirectChat;
  }

  bool _isDirectChatHaveMessage() {
    return isDirectChat && _isLastEventInRoomIsMessage();
  }

  bool _isLastEventInRoomIsMessage() {
    return [
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
    ].contains(lastEvent?.type);
  }

  PresentationSearch toPresentationSearch(BuildContext context) {
    return PresentationSearch(
      displayName: getLocalizedDisplayname(MatrixLocals(L10n.of(context)!)),
      roomSummary: summary,
      directChatMatrixID: directChatMatrixID,
      matrixId: id,
      searchTypeEnum: SearchTypeEnum.recentChat
    );
  }
}