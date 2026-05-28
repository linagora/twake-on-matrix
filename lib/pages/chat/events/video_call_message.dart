import 'dart:async';
import 'dart:math';

import 'package:fluffychat/config/app_config.dart';
import 'package:matrix/matrix.dart';

class VideoCallMessage {
  const VideoCallMessage._();

  static const _slugAlphabet = 'abcdefghijklmnopqrstuvwxyz';

  static final RegExp _urlRegExp = RegExp(
    '${RegExp.escape(AppConfig.videoCallBaseUrl)}/[a-z]{3}-[a-z]{4}-[a-z]{3}(?=\\s|\$)',
  );

  static String? extractUrl(String body) =>
      _urlRegExp.firstMatch(body.trim())?.group(0);

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
    unawaited(room.sendTextEvent('$startedTitle $url'));
  }
}
