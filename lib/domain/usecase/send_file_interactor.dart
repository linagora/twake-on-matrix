
import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/presentation/extensions/send_image_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:matrix/matrix.dart';

class SendFileInteractor {
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
      final matrixFiles = filePickerResult.files.map((xFile) => MatrixFile(
        bytes: xFile.bytes!,
        name: xFile.name,
      ).detectFileType).toList();

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