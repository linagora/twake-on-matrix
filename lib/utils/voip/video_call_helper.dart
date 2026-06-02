import 'dart:async';
import 'dart:math';

import 'package:fluffychat/config/app_config.dart';
import 'package:matrix/matrix.dart';

class VideoCallHelper {
  const VideoCallHelper._();

  static const _slugAlphabet = 'abcdefghijklmnopqrstuvwxyz';
  static const callUrlKey = 'call_url';

  static String? extractUrl(Event event) {
    if (event.messageType != MessageTypes.Text) return null;
    final url = event.content.tryGet<String>(callUrlKey);
    if (url == null || url.isEmpty) return null;
    return url;
  }

  static String generateUrl() {
    final random = Random.secure();
    String letters(int length) => List.generate(
      length,
      (_) => _slugAlphabet[random.nextInt(_slugAlphabet.length)],
    ).join();
    final slug = '${letters(3)}-${letters(4)}-${letters(3)}';
    return '${AppConfig.videoCallBaseUrl}/$slug';
  }

  static void start({required Room? room, required String startedTitle}) {
    if (room == null) return;
    final url = generateUrl();
    unawaited(
      room.sendEvent({
        'msgtype': MessageTypes.Text,
        'body': '$startedTitle $url',
        callUrlKey: url,
      }),
    );
  }
}
