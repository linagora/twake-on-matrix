import 'package:fluffychat/presentation/extensions/send_file_extension.dart';
import 'package:fluffychat/presentation/model/file/file_asset_entity.dart';
import 'package:matrix/matrix.dart';

class SendImagesInteractor {
  Future<void> execute({
    required Room room,
    required List<FileAssetEntity> entities,
  }) async {
    try {
      final txIdMapToFileInfo = await room.sendPlaceholdersForImagePickerFiles(
        entities: entities,
      );

      for (final txId in txIdMapToFileInfo.keys) {
        final fakeSendingFileInfo = txIdMapToFileInfo[txId];
        if (fakeSendingFileInfo == null) {
          continue;
        }

        await room.sendFileEvent(
          fakeSendingFileInfo.fileInfo,
          msgType: fakeSendingFileInfo.messageType,
          fakeImageEvent: fakeSendingFileInfo.fakeImageEvent,
          shrinkImageMaxDimension: 1600,
          txid: txId,
        );
      }
    } catch (error) {
      Logs().d("SendImageInteractor: execute(): $error");
    }
  }
}
