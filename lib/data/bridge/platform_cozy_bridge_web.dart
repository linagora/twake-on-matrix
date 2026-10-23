import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:twake_chat/data/bridge/cozy_bridge.dart';
import 'package:twake_chat/domain/model/drive/drive_exceptions.dart';

@JS('window._cozyBridge')
external JSObject? get _cozyBridge;

@JS('JSON.stringify')
external String _stringify(JSAny? value);

extension type _CozyBridgeJs(JSObject _) implements JSObject {
  external JSPromise<JSAny?> fetchJSON(JSObject options);
}

class PlatformCozyBridge implements CozyBridge {
  const PlatformCozyBridge();

  @override
  bool get isAvailable => _cozyBridge?.has('fetchJSON') ?? false;

  @override
  Future<Object?> fetchJson({
    required CozyBridgeMethod method,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final bridge = _cozyBridge;
    if (bridge == null || !bridge.has('fetchJSON')) {
      throw const DriveBridgeUnavailableException();
    }
    final options =
        {'method': method.wireName, 'path': path, 'body': body}.jsify()
            as JSObject;
    final result = await _CozyBridgeJs(bridge).fetchJSON(options).toDart;
    return result == null ? null : jsonDecode(_stringify(result));
  }
}
