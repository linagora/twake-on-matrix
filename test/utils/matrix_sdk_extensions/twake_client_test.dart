import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/twake_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:matrix/matrix.dart';

import '../../fake_client.dart';

const _userId = '@admin:fakeServer';
const _httpKey = 'http_$_userId';

/// MockDatabase answers null to `delete`, which `Client.clear` awaits.
/// [whileClearing] runs while the SDK clears, before it drops the token: a
/// sync callback still running at logout.
class _ClearableDatabase extends MockDatabase {
  _ClearableDatabase({this.whileClearing});

  final Future<void> Function()? whileClearing;

  @override
  Future<void> delete() async {}

  @override
  Future<void> clear() async => whileClearing?.call();
}

/// The SDK rethrows only when both `clear` and its fallback `delete` fail.
class _FailingDatabase extends _ClearableDatabase {
  _FailingDatabase({super.whileClearing});

  @override
  Future<void> delete() async => throw Exception('disk full');

  @override
  Future<void> clear() async {
    await super.clear();
    throw Exception('disk full');
  }
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

  group('logout and the HTTP session in the keychain', () {
    late Map<String, String> store;
    late TwakeClient client;

    setUp(() {
      store = {
        _httpKey: '{"accessToken":"abcd"}',
        'http_@other:fakeServer': '{}',
      };
      FlutterSecureStorage.setMockInitialValues(store);
      PlatformInfos.isTestingForIOS = true;
    });

    tearDown(() => PlatformInfos.isTestingForIOS = false);

    Future<void> logIn(DatabaseApi database) async {
      client = TwakeClient(
        'testclient',
        database: database,
        httpClient: FakeMatrixApi(),
      );
      await client.checkHomeserver(
        Uri.parse('https://fakeServer.notExisting'),
        checkWellKnown: false,
      );
      await client.init(
        newToken: 'abcd',
        newUserID: _userId,
        newHomeserver: client.homeserver,
        newDeviceName: 'Text Matrix Client',
        newDeviceID: 'GHTYAJCE',
      );
    }

    Future<void> lateSyncCallback() =>
        KeychainSharingManager.saveHttpSession(client);

    test('clear removes the http_ keychain entry of the user', () async {
      await logIn(_ClearableDatabase());

      await client.clear();

      expect(store.containsKey(_httpKey), isFalse);
      expect(store.containsKey('http_@other:fakeServer'), isTrue);
    });

    test(
      'an entry written back while the SDK clears does not survive logout',
      () async {
        await logIn(_ClearableDatabase(whileClearing: lateSyncCallback));

        await client.clear();

        expect(store.containsKey(_httpKey), isFalse);
      },
    );

    test('the entry is removed even when the SDK cleanup fails', () async {
      await logIn(_FailingDatabase(whileClearing: lateSyncCallback));

      await expectLater(client.clear(), throwsException);

      expect(store.containsKey(_httpKey), isFalse);
    });
  });
}
