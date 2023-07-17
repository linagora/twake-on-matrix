import 'package:fluffychat/presentation/extensions/send_image_extension.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

class SendImagesInteractor {

  Future<void> execute({
    required Room room,
    required List<AssetEntity> entities,
  }) async {
    try {
      final txIdMapToImageInfo = await room.sendPlaceholdersForImages(
        entities: entities,
      );

      for (final txId in txIdMapToImageInfo.value1.keys) {
        await room.sendImageFileEvent(
          txIdMapToImageInfo.value1[txId]!,
          fakeImageEvent: txIdMapToImageInfo.value2[txId],
          shrinkImageMaxDimension: 1600,
          txid: txId,
        );

        room.clearOlderImagesCacheInRoom();
      }
    } catch (error) {
      Logs().d("SendImageInteractor: execute(): $error");
    }
  }
}