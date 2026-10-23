import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/bridge/cozy_bridge.dart';
import 'package:twake_chat/data/datasource_impl/drive/drive_bridge_datasource_impl.dart';
import 'package:twake_chat/data/network/drive/drive_bridge_api.dart';
import 'package:twake_chat/data/model/drive/drive_picker_action_request.dart';
import 'package:twake_chat/data/model/drive/drive_picker_session_request.dart';

import 'drive_test_fixtures.dart';

class _FakeDriveBridge implements CozyBridge {
  _FakeDriveBridge({this.response, this.error});

  final Object? response;
  final Object? error;
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
    if (error != null) throw error!;
    return response;
  }
}

Future<void> _postsThePickerRequestAndParsesTheIntent() async {
  final bridge = _FakeDriveBridge(response: drivePickerSessionResponseJson());

  final response = await DriveBridgeDatasourceImpl(
    DriveBridgeApi(bridge),
  ).createPickerSession(drivePickerSessionRequest);

  final call = bridge.calls.single;
  expect(call['method'], CozyBridgeMethod.post);
  expect(call['path'], '/intents');
  final attributes = (call['body'] as Map)['data']['attributes'] as Map;
  expect(attributes['action'], 'PICK');
  expect(attributes['permissions'], ['GET']);
  final pickerData = attributes['data'] as Map;
  expect(pickerData['sharingLink'], {'label': 'Add as link'});
  expect(pickerData['theme'], {'type': 'light'});
  expect(response.id, 'intent-1');
  expect(response.href, 'https://drive.example/intents/intent-1');
  expect(response.client, 'twake-chat');
}

Future<void> _hidesTheAttachmentButtonWhenOnlyLinksAreOffered() async {
  final bridge = _FakeDriveBridge(response: drivePickerSessionResponseJson());

  await DriveBridgeDatasourceImpl(DriveBridgeApi(bridge)).createPickerSession(
    DrivePickerSessionRequest.pick(
      sharingLink: const DrivePickerActionRequest(label: 'Add as link'),
    ),
  );

  final body = bridge.calls.single['body'] as Map;
  final pickerData = body['data']['attributes']['data'] as Map;
  expect(pickerData.containsKey('downloadLink'), isTrue);
  expect(pickerData['downloadLink'], isNull);
}

Future<void> _failsWhenTheResponseIsMalformed() async {
  final malformed = [
    {'unexpected': true},
    ['not', 'an', 'object'],
  ];

  for (final response in malformed) {
    final bridge = _FakeDriveBridge(response: response);
    await expectLater(
      DriveBridgeDatasourceImpl(
        DriveBridgeApi(bridge),
      ).createPickerSession(drivePickerSessionRequest),
      throwsFormatException,
    );
  }
}

Future<void> _letsABridgeFailureThroughWithoutFallback() async {
  final bridge = _FakeDriveBridge(error: StateError('bridge down'));

  await expectLater(
    DriveBridgeDatasourceImpl(
      DriveBridgeApi(bridge),
    ).createPickerSession(drivePickerSessionRequest),
    throwsStateError,
  );
  expect(bridge.calls, hasLength(1));
}

void _reportsTheBridgeAvailability() {
  final bridge = _FakeDriveBridge();

  expect(DriveBridgeDatasourceImpl(DriveBridgeApi(bridge)).isAvailable, isTrue);
}

void main() {
  test(
    'posts the picker request and parses the intent',
    _postsThePickerRequestAndParsesTheIntent,
  );
  test(
    'hides the attachment button when only links are offered',
    _hidesTheAttachmentButtonWhenOnlyLinksAreOffered,
  );
  test(
    'fails when the response is malformed',
    _failsWhenTheResponseIsMalformed,
  );
  test(
    'lets a bridge failure through without fallback',
    _letsABridgeFailureThroughWithoutFallback,
  );
  test('reports the bridge availability', _reportsTheBridgeAvailability);
}
