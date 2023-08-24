import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/data/network/upload_file/file_info_extension.dart';
import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

class SendFileInteractor {
  Future<void> execute({
    required Room room,
    required FilePickerResult filePickerResult,
    Event? inReplyTo,
    String? editEventId,
    int? shrinkImageMaxDimension,
    Map<String, dynamic>? extraContent,
  }) async {
    try {
      final fileInfos = filePickerResult.files
          .map(
            (xFile) => FileInfo(
              xFile.name,
              xFile.path ?? '${getTemporaryDirectory()}/${xFile.name}',
              xFile.size,
              readStream: xFile.readStream,
            ),
          )
          .toList();

      for (final fileInfo in fileInfos) {
        final txid = _storePlaceholderFileInMem(
          fileInfo: fileInfo,
          room: room,
        );
        await room.sendFileEvent(
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

  String _storePlaceholderFileInMem({
    required Room room,
    required FileInfo fileInfo,
  }) {
    final txid = room.client.generateUniqueTransactionId();
    final matrixFile = MatrixFile.fromMimeType(
      name: fileInfo.fileName,
      filePath: fileInfo.filePath,
      mimeType: fileInfo.mimeType,
    );
    room.sendingFilePlaceholders[txid] = matrixFile;
    return txid;
  }
}
