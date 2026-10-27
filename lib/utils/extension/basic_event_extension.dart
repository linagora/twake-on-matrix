import 'package:matrix/matrix.dart';

extension BacsicEventExtension on BasicEvent {
  Map<String, Object?> formatContentForwards() {
    final forwardContent = Map<String, Object?>.from(content)
      ..remove('m.relates_to');
    // Forwards are sent as m.room.message, so a sticker becomes an image.
    if (type == EventTypes.Sticker) {
      forwardContent['msgtype'] = MessageTypes.Image;
    }
    return forwardContent;
  }
}
