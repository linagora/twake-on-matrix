import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/drive/datasources_impl/sso_refresh_token_store_impl.dart';

const _issuer = 'https://sso.example';

/// A keychain that is locked: every call throws.
class _ClosedStorage implements FlutterSecureStorage {
  const _ClosedStorage();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw PlatformException(code: 'keychain');
}

/// A keychain whose writes wait for the test, and that notes the order in
/// which its calls start.
class _SlowWriteStorage implements FlutterSecureStorage {
  final writeGate = Completer<void>();
  final started = <String>[];
  final values = <String, String>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String;
    switch (invocation.memberName) {
      case #write:
        started.add('write $key');
        final value = invocation.namedArguments[#value] as String;
        return writeGate.future.then((_) => values[key] = value);
      case #delete:
        started.add('delete $key');
        values.remove(key);
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('SsoRefreshTokenStoreImpl', () {
    final store = SsoRefreshTokenStoreImpl(const FlutterSecureStorage());

    test('reads what it wrote, for that user only', () async {
      await store.write('@alice:example.org', 'refresh-a', issuer: _issuer);
      await store.write('@bob:example.org', 'refresh-b', issuer: _issuer);

      expect(
        await store.read('@alice:example.org', issuer: _issuer),
        'refresh-a',
      );
      expect(
        await store.read('@bob:example.org', issuer: _issuer),
        'refresh-b',
      );
      expect(await store.read('@carol:example.org', issuer: _issuer), isNull);
    });

    test(
      'a new instance on the same storage sees the token (a restart)',
      () async {
        await store.write('@alice:example.org', 'refresh-a', issuer: _issuer);

        final restarted = SsoRefreshTokenStoreImpl(
          const FlutterSecureStorage(),
        );

        expect(
          await restarted.read('@alice:example.org', issuer: _issuer),
          'refresh-a',
        );
      },
    );

    test('a token is not read for another issuer', () async {
      await store.write('@alice:example.org', 'refresh-a', issuer: _issuer);

      expect(
        await store.read('@alice:example.org', issuer: 'https://other.example'),
        isNull,
      );
      expect(
        await store.read('@alice:example.org', issuer: _issuer),
        'refresh-a',
      );
    });

    test('a trailing slash does not make another issuer', () async {
      await store.write('@alice:example.org', 'refresh-a', issuer: _issuer);

      expect(
        await store.read('@alice:example.org', issuer: '$_issuer/'),
        'refresh-a',
      );
    });

    test('a bare token that an older build kept is read as no token', () async {
      FlutterSecureStorage.setMockInitialValues({
        'twake_sso_refresh_token_@alice:example.org': 'bare-token',
      });

      expect(await store.read('@alice:example.org', issuer: _issuer), isNull);
    });

    test('writing again replaces the token', () async {
      await store.write('@alice:example.org', 'old', issuer: _issuer);
      await store.write('@alice:example.org', 'new', issuer: _issuer);

      expect(await store.read('@alice:example.org', issuer: _issuer), 'new');
    });

    test('deletes one user and keeps the others, twice is safe', () async {
      await store.write('@alice:example.org', 'refresh-a', issuer: _issuer);
      await store.write('@bob:example.org', 'refresh-b', issuer: _issuer);

      await store.delete('@alice:example.org');
      await store.delete('@alice:example.org');

      expect(await store.read('@alice:example.org', issuer: _issuer), isNull);
      expect(
        await store.read('@bob:example.org', issuer: _issuer),
        'refresh-b',
      );
    });

    test('a store the platform cannot read is read as no token', () async {
      final closed = SsoRefreshTokenStoreImpl(const _ClosedStorage());

      expect(await closed.read('@alice:example.org', issuer: _issuer), isNull);
    });
  });

  group('SsoRefreshTokenStoreImpl calls in turn', () {
    test('a delete made while a write runs ends with no token', () async {
      final storage = _SlowWriteStorage();
      final store = SsoRefreshTokenStoreImpl(storage);

      final write = store.write(
        '@alice:example.org',
        'refresh-a',
        issuer: _issuer,
      );
      final delete = store.delete('@alice:example.org');
      await Future<void>.delayed(Duration.zero);
      expect(storage.started, [
        'write twake_sso_refresh_token_@alice:example.org',
      ]);

      storage.writeGate.complete();
      await Future.wait([write, delete]);

      expect(storage.values, isEmpty);
      expect(storage.started.last, startsWith('delete'));
    });

    test('another user does not wait for a write', () async {
      final storage = _SlowWriteStorage();
      final store = SsoRefreshTokenStoreImpl(storage);

      final write = store.write(
        '@alice:example.org',
        'refresh-a',
        issuer: _issuer,
      );
      await store.delete('@bob:example.org');

      expect(storage.started, [
        'write twake_sso_refresh_token_@alice:example.org',
        'delete twake_sso_refresh_token_@bob:example.org',
      ]);
      storage.writeGate.complete();
      await write;
    });
  });
}
