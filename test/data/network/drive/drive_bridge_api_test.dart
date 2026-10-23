import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/bridge/cozy_bridge.dart';
import 'package:twake_chat/data/network/drive/drive_bridge_api.dart';
import 'package:twake_chat/data/network/service_path.dart';

class _FakeCozyBridge implements CozyBridge {
  _FakeCozyBridge({this.response = const <String, dynamic>{}});

  final Object? response;
  final List<Map<String, Object?>> calls = [];

  @override
  bool get isAvailable => true;

  @override
  Future<Object?> fetchJson({
    required CozyBridgeMethod method,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    calls.add({'method': method, 'path': path, 'body': body});
    return response;
  }
}

final _path = ServicePath('/custom/endpoint');

Future<void> _postsTheBodyToThePathThroughTheBridge() async {
  final bridge = _FakeCozyBridge(response: {'ok': true});

  final json = await DriveBridgeApi(bridge).post(_path, body: {'a': 1});

  expect(json, {'ok': true});
  expect(bridge.calls.single, {
    'method': CozyBridgeMethod.post,
    'path': '/custom/endpoint',
    'body': {'a': 1},
  });
}

Future<void> _failsWhenTheResponseIsNotAJsonObject() async {
  final bridge = _FakeCozyBridge(response: ['not', 'an', 'object']);

  await expectLater(
    DriveBridgeApi(bridge).post(_path, body: {}),
    throwsFormatException,
  );
}

void _reportsTheBridgeAvailability() {
  expect(DriveBridgeApi(_FakeCozyBridge()).isAvailable, isTrue);
}

void main() {
  test(
    'posts the body to the path through the bridge',
    _postsTheBodyToThePathThroughTheBridge,
  );
  test(
    'fails when the response is not a JSON object',
    _failsWhenTheResponseIsNotAJsonObject,
  );
  test('reports the bridge availability', _reportsTheBridgeAvailability);
}
