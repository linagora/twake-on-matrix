import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:matrix/matrix.dart';

class SendMediaOnWebWithCaptionInteractor {
  Future<void> execute({
    required Room room,
    required MatrixFile media,
    String caption = "",
  }) async {
    try {
      final txid = room.client.generateUniqueTransactionId();
      room.sendingFilePlaceholders[txid] = media;
      final fakeImageEvent = await room.sendFakeImageEvent(
        media,
        txid: txid,
      );
      String? messageID;
      Map<String, dynamic>? msgEventContent;
      if (caption.isNotEmpty) {
        messageID = room.client.generateUniqueTransactionId();
        msgEventContent = room.getEventContentFromMsgText(message: caption);
        await room.sendFakeMessage(
          content: msgEventContent,
          messageId: messageID,
        );
      }

      await room.sendFileOnWebEvent(
        media,
        fakeImageEvent: fakeImageEvent,
        txid: txid,
      );
      if (messageID != null && msgEventContent != null) {
        await room.sendMessageContent(
          EventTypes.Message,
          msgEventContent,
          txid: messageID,
        );
      }
    } catch (e) {
      Logs().e("SendMediaOnWebWithCaptionInteractor: $e");
    }
  }
}
