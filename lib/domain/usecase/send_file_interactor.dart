import 'package:fluffychat/data/network/extensions/file_info_extension.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:matrix/matrix.dart';

class SendFileInteractor {
  Future<void> execute({
    required Room room,
    required List<FileInfo> fileInfos,
    String? txId,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    try {
      for (final fileInfo in fileInfos) {
        final txid = room.storePlaceholderFileInMem(
          fileInfo: fileInfo,
        );
        room.sendFileEvent(
          fileInfo,
          msgType: fileInfo.msgType,
          txid: txid,
          editEventId: editEventId,
          inReplyTo: inReplyTo,
          shrinkImageMaxDimension: shrinkImageMaxDimension,
        );
      }
    } catch (error) {
      Logs().d("SendFileInteractor: execute(): $error");
    }
  }
}
