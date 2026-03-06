import 'dart:io';

import 'package:flutter/services.dart';
import 'package:matrix/matrix.dart';

/// Persists Megolm session keys to the iOS App Group container for NSE fallback decryption.
class IosMegolmSessionWriter {
  static const _channel = MethodChannel('megolm_session_store');

  static Future<void> writeSession({
    required String roomId,
    required String sessionId,
    required String sessionKey,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('writeSession', {
        'roomId': roomId,
        'sessionId': sessionId,
        'sessionKey': sessionKey,
      });
    } catch (e, s) {
      Logs().w(
        '[MegolmSessionWriter] Failed to write session $sessionId',
        e,
        s,
      );
    }
  }
}
