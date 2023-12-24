import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:matrix/matrix.dart';

class SendFilesOnWebWithCaptionInteractor {
  Future<void> execute({
    required Room room,
    required List<MatrixFile> files,
    String? caption,
  }) async {
    try {
      final txIdsMapFileEvents = <String, (MatrixFile, SyncUpdate)>{};
      for (final file in files) {
        final txid = room.client.generateUniqueTransactionId();
        room.sendingFilePlaceholders[txid] = file;
        final fakeFileEvent = await room.sendFakeFileEvent(
          file,
          txid: txid,
        );
        txIdsMapFileEvents[txid] = (file, fakeFileEvent);
      }

      String? messageID;
      Map<String, dynamic>? msgEventContent;
      if (caption != null && caption.isNotEmpty == true) {
        messageID = room.client.generateUniqueTransactionId();
        msgEventContent = room.getEventContentFromMsgText(message: caption);
        await room.sendFakeMessage(
          content: msgEventContent,
          messageId: messageID,
        );
      }

      for (final txId in txIdsMapFileEvents.keys) {
        if (txIdsMapFileEvents[txId] != null) {
          await room.sendFileOnWebEvent(
            txIdsMapFileEvents[txId]!.$1,
            fakeImageEvent: txIdsMapFileEvents[txId]!.$2,
            txid: txId,
          );
        }
      }

      if (messageID != null && msgEventContent != null) {
        await room.sendMessageContent(
          EventTypes.Message,
          msgEventContent,
          txid: messageID,
        );
      }
    } catch (e) {
      Logs().e("SendFilesOnWebWithCaptionInteractor: $e");
    }
  }
}
