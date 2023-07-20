
import 'package:fluffychat/presentation/extensions/asset_entity_extension.dart';
import 'package:fluffychat/presentation/extensions/room_extension.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

class SendImageInteractor {
  Future<void> execute({
    required Room room,
    required AssetEntity entity,
    String? txId,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    final fileInfo = await entity.toFileInfo();
    if (fileInfo != null) {
      try {
        final mxcUri = await room.sendImageFileEvent(
          fileInfo,
          txid: txId,
          editEventId: editEventId,
          inReplyTo: inReplyTo,
          shrinkImageMaxDimension: shrinkImageMaxDimension,
        );
      } catch(error) {
        Logs().d("SendImageInteractor: execute(): $error");
      }
    }
  }
}