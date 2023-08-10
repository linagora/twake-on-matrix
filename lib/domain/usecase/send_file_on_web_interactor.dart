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
      final fileInfos = filePickerResult.files
          .map(
            (xFile) => MatrixFile(
              bytes: xFile.bytes,
              name: xFile.name,
            ),
          )
          .toList();

      final txIdMapToImageInfo =
          await room.sendPlaceholdersWebForImages(entities: fileInfos);

      for (final txId in txIdMapToImageInfo.value1.keys) {
        await room.sendFileOnWebEvent(
          txIdMapToImageInfo.value1[txId]!,
          fakeImageEvent: txIdMapToImageInfo.value2[txId],
          txid: txId,
        );
        room.clearOlderImagesCacheInRoom(txId: txId);
      }
    } catch (error) {
      Logs().d("SendFileInteractor: execute(): $error");
    }
  }
}
