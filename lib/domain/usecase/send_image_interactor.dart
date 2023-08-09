import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';

class SendImageInteractor {
  Future<void> execute({
    required Room room,
    required FileAssetEntity entity,
    String? txId,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    final fileInfo = await entity.toFileInfo();
    if (fileInfo != null) {
      try {
        await room.sendFileEvent(
          fileInfo,
          txid: txId,
          editEventId: editEventId,
          inReplyTo: inReplyTo,
          shrinkImageMaxDimension: shrinkImageMaxDimension,
        );
      } catch (error) {
        Logs().d("SendImageInteractor: execute(): $error");
      }
    }
  }
}
