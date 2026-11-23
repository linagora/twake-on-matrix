import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/secure_storage.dart';
import 'package:twake_chat/utils/sqlite_key_store.dart';

import 'fake_keychain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'creates a 64 character key made only of lowercase hex digits',
    () async {
      final key = await SqliteKeyStore().keyFor('client_a');

      expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
    },
  );

  test('returns the same key on the second call', () async {
    final store = SqliteKeyStore();

    expect(await store.keyFor('client_a'), await store.keyFor('client_a'));
  });

  test('a new store instance reads the key the first one created', () async {
    final first = await SqliteKeyStore().keyFor('client_a');

    expect(await SqliteKeyStore().keyFor('client_a'), first);
  });

  test('keeps the key in the secure storage under sqlite_key_<name>', () async {
    final key = await SqliteKeyStore().keyFor('client_a');

    expect(await secureStorage.read(key: 'sqlite_key_client_a'), key);
  });

  test('reuses a key already present in the secure storage', () async {
    final existing = 'ab' * 32;
    FlutterSecureStorage.setMockInitialValues({
      'sqlite_key_client_a': existing,
    });

    expect(await SqliteKeyStore().keyFor('client_a'), existing);
  });

  test('gives each database name its own key', () async {
    final store = SqliteKeyStore();

    expect(
      await store.keyFor('client_a'),
      isNot(await store.keyFor('client_b')),
    );
  });

  test('does not repeat keys across many databases', () async {
    final store = SqliteKeyStore();
    final keys = {for (var i = 0; i < 20; i++) await store.keyFor('db_$i')};

    expect(keys, hasLength(20));
  });

  test('delete removes the key, so the next call creates a new one', () async {
    final store = SqliteKeyStore();
    final old = await store.keyFor('client_a');

    await store.delete('client_a');

    expect(await secureStorage.read(key: 'sqlite_key_client_a'), isNull);
    expect(await store.keyFor('client_a'), isNot(old));
  });

  test('delete only removes the key of the given database', () async {
    final store = SqliteKeyStore();
    await store.keyFor('client_a');
    final other = await store.keyFor('client_b');

    await store.delete('client_a');

    expect(await store.keyFor('client_b'), other);
  });

  test('delete on an unknown database does not throw', () async {
    await SqliteKeyStore().delete('never_created');
  });

  group('a key the secure storage did not keep', () {
    late FakeKeychain keychain;

    setUp(() => (keychain = FakeKeychain()).install());

    test('is not handed out when its write is silently lost', () async {
      keychain.loseWrites = true;

      await expectLater(SqliteKeyStore().keyFor('client_a'), throwsA(anything));
    });

    test('is not handed out when the storage keeps another value', () async {
      keychain.alterWrites = (value) => value.substring(1);

      await expectLater(SqliteKeyStore().keyFor('client_a'), throwsA(anything));
    });
  });
}
