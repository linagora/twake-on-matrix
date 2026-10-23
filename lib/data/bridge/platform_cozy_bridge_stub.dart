import 'package:twake_chat/data/bridge/cozy_bridge.dart';
import 'package:twake_chat/domain/model/drive/drive_exceptions.dart';

class PlatformCozyBridge implements CozyBridge {
  const PlatformCozyBridge();

  @override
  bool get isAvailable => false;

  @override
  Future<Object?> fetchJson({
    required CozyBridgeMethod method,
    required String path,
    required Map<String, dynamic> body,
  }) => throw const DriveBridgeUnavailableException();
}
