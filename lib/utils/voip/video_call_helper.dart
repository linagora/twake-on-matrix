import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/services/video_call/video_call_slug_service.dart';

class VideoCallHelper {
  const VideoCallHelper._();

  static const callUrlKey = 'call_url';

  static String? extractUrl(Event event, String? baseUrl) {
    if (baseUrl == null || baseUrl.isEmpty) return null;
    if (event.messageType != MessageTypes.Text) return null;
    final url = event.content.tryGet<String>(callUrlKey);
    if (url == null || url.isEmpty) return null;
    final prefix = '$baseUrl/';
    if (!url.startsWith(prefix)) return null;
    final slug = url.substring(prefix.length);
    if (!VideoCallSlugService.pattern.hasMatch(slug)) return null;
    return url;
  }
}
