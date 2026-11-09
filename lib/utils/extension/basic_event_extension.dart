import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/media_album/policy/media_batch_stamp.dart';

extension BacsicEventExtension on BasicEvent {
  Map<String, Object?> formatContentForwards() {
    final forwardContent = const MediaBatchStamp().withoutBatch(content)
      ..remove('m.relates_to');
    // Forwards are sent as m.room.message, so a sticker becomes an image.
    if (type == EventTypes.Sticker) {
      forwardContent['msgtype'] = MessageTypes.Image;
    }
    return forwardContent;
  }
}
