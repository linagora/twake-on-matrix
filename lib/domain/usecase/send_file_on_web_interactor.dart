import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/presentation/extensions/send_file_web_extension.dart';
import 'package:matrix/matrix.dart';

class SendFileOnWebInteractor {
  Future<void> execute({
    required Room room,
    required FilePickerResult filePickerResult,
    String? txId,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    try {
      final matrixFiles = filePickerResult.files
          .map(
            (xFile) => MatrixFile.fromMimeType(
              bytes: xFile.bytes,
              name: xFile.name,
              filePath: '',
            ),
          )
          .toList();

      for (final matrixFile in matrixFiles) {
        await room.sendFileOnWebEvent(
          matrixFile,
          txid: txId,
        );
      }
    } catch (error) {
      Logs().d("SendFileInteractor: execute(): $error");
    }
  }
}
