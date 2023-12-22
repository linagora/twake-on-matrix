import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';

class SendMediaInteractor {
  Future<void> execute({
    required Room room,
    required List<FileAssetEntity> entities,
    String? caption,
  }) async {
    try {
      final txIdMapToFileInfo = await room.sendPlaceholdersForImagePickerFiles(
        entities: entities,
      );

      String? messageID;
      Map<String, dynamic>? msgEventContent;
      if (caption != null && caption.isNotEmpty) {
        messageID = room.client.generateUniqueTransactionId();
        msgEventContent = room.getEventContentFromMsgText(message: caption);
        await room.sendFakeMessage(
          content: msgEventContent,
          messageId: messageID,
        );
      }

      for (final txId in txIdMapToFileInfo.keys) {
        final fakeSendingFileInfo = txIdMapToFileInfo[txId];
        if (fakeSendingFileInfo == null) {
          continue;
        }

        await room.sendFileEvent(
          fakeSendingFileInfo.fileInfo,
          msgType: fakeSendingFileInfo.messageType,
          fakeImageEvent: fakeSendingFileInfo.fakeImageEvent,
          shrinkImageMaxDimension: 1600,
          txid: txId,
        );
      }
      if (messageID != null && msgEventContent != null) {
        await room.sendMessageContent(
          EventTypes.Message,
          msgEventContent,
          txid: messageID,
        );
      }
    } catch (error) {
      Logs().d("SendImagesInteractor: execute(): $error");
    }
  }
}
