import 'package:twake_chat/utils/matrix_sdk_extensions/twake_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

/// MockDatabase answers null to `delete`, which `Client.clear` awaits.
class _ClearableDatabase extends MockDatabase {
  @override
  Future<void> delete() async {}

  @override
  Future<void> clear() async {}
}

void main() {
  test('enables limited timeline history backfill before initialization', () {
    final client = TwakeClient('testclient', database: MockDatabase());

    expect(client.requestHistoryOnLimitedTimeline, isTrue);
  });

  test('keeps call events out of the room preview', () {
    final client = TwakeClient('testclient', database: MockDatabase());

    expect(
      client.roomPreviewLastEvents,
      containsAll([EventTypes.Message, EventTypes.Encrypted]),
    );
    expect(
      client.roomPreviewLastEvents,
      isNot(contains(EventTypes.CallInvite)),
    );
    expect(
      client.roomPreviewLastEvents,
      isNot(contains(EventTypes.GroupCallMember)),
    );
  });

  test('clear removes the http_ keychain entry of the user', () async {
    final store = {
      'http_@admin:fakeServer': '{"accessToken":"abcd"}',
      'http_@other:fakeServer': '{}',
    };
    FlutterSecureStorage.setMockInitialValues(store);
    PlatformInfos.isTestingForIOS = true;
    addTearDown(() => PlatformInfos.isTestingForIOS = false);
    final client = TwakeClient(
      'testclient',
      database: _ClearableDatabase(),
      httpClient: FakeMatrixApi(),
    );
    await client.checkHomeserver(
      Uri.parse('https://fakeServer.notExisting'),
      checkWellKnown: false,
    );
    await client.init(
      newToken: 'abcd',
      newUserID: '@admin:fakeServer',
      newHomeserver: client.homeserver,
      newDeviceName: 'Text Matrix Client',
      newDeviceID: 'GHTYAJCE',
    );

    await client.clear();

    expect(store.containsKey('http_@admin:fakeServer'), isFalse);
    expect(store.containsKey('http_@other:fakeServer'), isTrue);
  });
}
