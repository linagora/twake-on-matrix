
import 'package:fluffychat/presentation/extensions/room_extension.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:fluffychat/presentation/extensions/asset_entity_extension.dart';

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
    final matrixFile = await entity.toMatrixFile();
    if (matrixFile != null) {
      try {
        final mxcUri = await room.sendImageFileEvent(
          matrixFile,
          txid: txId,
          editEventId: editEventId,
          inReplyTo: inReplyTo,
          shrinkImageMaxDimension: shrinkImageMaxDimension,
          extraContent: extraContent,
        );
      } catch(error) {
        Logs().d("SendImageInteractor: execute(): $error");
      }
    }
  }
}