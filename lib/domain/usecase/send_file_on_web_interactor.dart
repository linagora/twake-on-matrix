import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:matrix/matrix.dart';

class SendFileOnWebInteractor {
  Future<void> execute({
    required Room room,
    required List<MatrixFile> files,
    String? txId,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    try {
      for (final matrixFile in files) {
        await room.sendFileOnWebEvent(
          matrixFile,
          txid: txId,
        );
      }
    } catch (error) {
      Logs().w("SendFileInteractor: execute(): $error");
    }
  }
}
