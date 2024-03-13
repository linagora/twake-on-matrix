import 'package:matrix/matrix.dart';

extension BacsicEventExtension on BasicEvent {
  Map<String, Object?> formatContentForwards() {
    if (content['m.relates_to'] != null) {
      content.remove('m.relates_to');
    }
    return content;
  }
}
