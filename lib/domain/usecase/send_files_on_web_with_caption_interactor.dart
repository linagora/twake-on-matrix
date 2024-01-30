import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:matrix/matrix.dart';

class SendFilesOnWebWithCaptionInteractor {
  Future<void> execute({
    required Room room,
    required List<MatrixFile> files,
    Map<MatrixFile, MatrixImageFile?>? thumbnails,
    String? caption,
  }) async {
    try {
      final txIdsMapFileEvents = <String, (MatrixFile, SyncUpdate)>{};
      for (MatrixFile file in files) {
        if (file.readStream != null && file.bytes == null) {
          file = await file.convertReadStreamToBytes();
        }
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
          final matrixFile = txIdsMapFileEvents[txId]!.$1;
          final syncUpdate = txIdsMapFileEvents[txId]!.$2;
          await room.sendFileOnWebEvent(
            matrixFile,
            fakeImageEvent: syncUpdate,
            txid: txId,
            thumbnail: thumbnails?[matrixFile],
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
