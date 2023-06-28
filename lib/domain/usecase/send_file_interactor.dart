
import 'package:fluffychat/presentation/extensions/room_extension.dart';
import 'package:matrix/matrix.dart';

class SendFileInteractor {
  Future<void> execute({
    required Room room,
    required List<MatrixFile> matrixFiles,
    String? txId,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    try {

      for (final matrixFile in matrixFiles) {
        await room.sendImageFileEvent(
          matrixFile,
          txid: txId,
          editEventId: editEventId,
          inReplyTo: inReplyTo,
          shrinkImageMaxDimension: shrinkImageMaxDimension,
          extraContent: extraContent,
        );
      }
    } catch(error) {
      Logs().d("SendFileInteractor: execute(): $error");
    }
  }
}