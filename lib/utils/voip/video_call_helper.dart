import 'dart:async';
import 'dart:math';

import 'package:matrix/matrix.dart';

class VideoCallHelper {
  const VideoCallHelper._();

  static const _slugAlphabet = 'abcdefghijklmnopqrstuvwxyz';
  static const callUrlKey = 'call_url';

  static final RegExp _slugRegExp = RegExp(r'^[a-z]{3}-[a-z]{4}-[a-z]{3}$');

  static String? extractUrl(Event event, String? baseUrl) {
    if (baseUrl == null || baseUrl.isEmpty) return null;
    if (event.messageType != MessageTypes.Text) return null;
    final url = event.content.tryGet<String>(callUrlKey);
    if (url == null || url.isEmpty) return null;
    final prefix = '$baseUrl/';
    if (!url.startsWith(prefix)) return null;
    if (!_slugRegExp.hasMatch(url.substring(prefix.length))) return null;
    return url;
  }

  static String generateUrl(String baseUrl) {
    final random = Random.secure();
    String letters(int length) => List.generate(
      length,
      (_) => _slugAlphabet[random.nextInt(_slugAlphabet.length)],
    ).join();
    final slug = '${letters(3)}-${letters(4)}-${letters(3)}';
    return '$baseUrl/$slug';
  }

  static void start({
    required Room? room,
    required String startedTitle,
    required String? baseUrl,
  }) {
    if (room == null || baseUrl == null) return;
    final url = generateUrl(baseUrl);
    unawaited(
      room.sendEvent({
        'msgtype': MessageTypes.Text,
        'body': "$startedTitle $url",
        callUrlKey: url,
      }),
    );
  }
}
