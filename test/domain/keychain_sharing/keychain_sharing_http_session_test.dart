import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_restore_token.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_session.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/string_extension.dart';

import '../../fake_client.dart';

const _userId = '@admin:fakeServer';
const _httpKey = 'http_$_userId';

// A notification extension that does only HTTP reads this entry: the app's own
// token, under a key that is never the keychain slot of the user.
void main() {
  late Map<String, String> store;
  late Client client;

  setUp(() async {
    store = {};
    FlutterSecureStorage.setMockInitialValues(store);
    PlatformInfos.isTestingForIOS = true;
    client = await getClient();
  });

  tearDown(() => PlatformInfos.isTestingForIOS = false);

  Map<String, dynamic> httpEntry() =>
      jsonDecode(store[_httpKey]!) as Map<String, dynamic>;

  group('saveHttpSession', () {
    test('stores the app token under http_<userId>', () async {
      await KeychainSharingManager.saveHttpSession(client);

      expect(httpEntry(), {
        'accessToken': 'abcd',
        'userId': _userId,
        'homeserverUrl': client.homeserver.toString(),
        'pusherNotificationClientIdentifier': _userId.sha256Hash,
      });
    });

    test('has no session field, so the Rust path never restores it', () async {
      await KeychainSharingManager.saveHttpSession(client);

      expect(httpEntry().containsKey('session'), isFalse);
    });

    test('does not write the slot of the user', () async {
      await KeychainSharingManager.saveHttpSession(client);

      expect(store.containsKey(_userId), isFalse);
      expect(await KeychainSharingManager.read(userId: _userId), isNull);
    });

    test('is idempotent', () async {
      await KeychainSharingManager.saveHttpSession(client);
      final first = Map.of(store);
      await KeychainSharingManager.saveHttpSession(client);

      expect(store, first);
    });

    test('replaces the token when the app token changes', () async {
      store[_httpKey] = jsonEncode({'accessToken': 'old', 'userId': _userId});

      await KeychainSharingManager.saveHttpSession(client);

      expect(httpEntry()['accessToken'], 'abcd');
    });

    test('writes nothing outside iOS', () async {
      PlatformInfos.isTestingForIOS = false;
      await KeychainSharingManager.saveHttpSession(client);

      expect(store, isEmpty);
    });

    test('writes nothing without a user', () async {
      await KeychainSharingManager.saveHttpSession(
        Client('anonymous', database: MockDatabase()),
      );

      expect(store, isEmpty);
    });
  });

  group('deleteHttpSession', () {
    test('removes the entry of that user only', () async {
      store[_httpKey] = '{}';
      store['http_@other:fakeServer'] = '{}';

      await KeychainSharingManager.deleteHttpSession(_userId);

      expect(store.containsKey(_httpKey), isFalse);
      expect(store.containsKey('http_@other:fakeServer'), isTrue);
    });

    test('leaves the slot of the user alone', () async {
      store[_userId] = 'slot';
      store[_httpKey] = '{}';

      await KeychainSharingManager.deleteHttpSession(_userId);

      expect(store[_userId], 'slot');
    });
  });

  group('http_ entry and the user slot', () {
    KeychainSharingRestoreToken appSlot() => KeychainSharingRestoreToken(
      session: KeychainSharingSession(
        accessToken: 'abcd',
        userId: _userId,
        deviceId: client.deviceID!,
        homeserverUrl: client.homeserver.toString(),
      ),
    );

    test(
      'removeAppSession purges the slot but never the http_ entry',
      () async {
        await KeychainSharingManager.saveHttpSession(client);
        await KeychainSharingManager.save(appSlot());

        await KeychainSharingManager.removeAppSession(client);

        expect(store.containsKey(_userId), isFalse);
        expect(store.containsKey(_httpKey), isTrue);
      },
    );

    test('read ignores the http_ entry', () async {
      store[_httpKey] = jsonEncode({'accessToken': 'abcd', 'userId': _userId});

      expect(await KeychainSharingManager.read(userId: _userId), isNull);
    });

    test('delete of a slot leaves the http_ entry', () async {
      await KeychainSharingManager.saveHttpSession(client);
      await KeychainSharingManager.save(appSlot());

      await KeychainSharingManager.delete(userId: _userId);

      expect(store.containsKey(_httpKey), isTrue);
    });
  });
}
