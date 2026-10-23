import 'package:twake_chat/data/bridge/cozy_bridge.dart';
import 'package:twake_chat/data/network/drive/drive_json.dart';
import 'package:twake_chat/data/network/service_path.dart';

class DriveBridgeApi {
  const DriveBridgeApi(this._bridge);

  final CozyBridge _bridge;

  bool get isAvailable => _bridge.isAvailable;

  Future<Map<String, dynamic>> post(
    ServicePath servicePath, {
    required Map<String, dynamic> body,
  }) async {
    final data = await _bridge.fetchJson(
      method: CozyBridgeMethod.post,
      path: servicePath.path,
      body: body,
    );
    return asJsonObject(data);
  }
}
