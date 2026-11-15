import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart' show Logs;
import 'package:twake_chat/domain/drive/sources/sso_refresh_token_store.dart';

/// [SsoRefreshTokenStore] backed by [FlutterSecureStorage] (the Keychain on
/// iOS, the Keystore on Android). Keys are namespaced per user, so accounts on
/// one device do not collide. The token is never logged.
///
/// The calls of one user run one after the other, in the order they were
/// made: a logout that deletes the token while a sign-in is still writing it
/// ends with no token, not with the late write.
class SsoRefreshTokenStoreImpl implements SsoRefreshTokenStore {
  SsoRefreshTokenStoreImpl(this._storage);

  final FlutterSecureStorage _storage;

  /// The last call of each user that is still running.
  final _tails = <String, Future<void>>{};

  Future<T> _inTurn<T>(String userId, Future<T> Function() call) {
    final previous = _tails[userId] ?? Future<void>.value();
    final run = previous.then((_) => call());
    final tail = run.then<void>((_) {}, onError: (Object _) {});
    _tails[userId] = tail;
    // Forget the tail once nothing came after it.
    unawaited(
      tail.then((_) {
        if (identical(_tails[userId], tail)) _tails.remove(userId);
      }),
    );
    return run;
  }

  static String _key(String userId) => 'twake_sso_refresh_token_$userId';

  /// A store that cannot be read is read as holding nothing, and the key is
  /// kept: the failure is access (a keychain that is locked until the first
  /// unlock, for one), not a bad value, and the next start may read it.
  @override
  Future<String?> read(String userId, {required String issuer}) =>
      _inTurn(userId, () async {
        try {
          final stored = await _storage.read(key: _key(userId));
          return _tokenFor(stored, issuer);
        } on PlatformException {
          // A value the platform cannot give back is read as no token.
          Logs().w('SsoRefreshTokenStoreImpl::read: the store failed');
          return null;
        }
      });

  /// The token inside [stored] when it came from [issuer]. A value that is not
  /// the JSON this class writes (an older build kept the bare token) has no
  /// issuer to compare, so it is read as no token.
  static String? _tokenFor(String? stored, String issuer) {
    if (stored == null) return null;
    try {
      final record = jsonDecode(stored);
      if (record is! Map<String, dynamic>) return null;
      final token = record['token'];
      // A trailing slash does not make another issuer.
      final slash = RegExp(r'/$');
      final sameIssuer =
          '${record['issuer']}'.replaceFirst(slash, '') ==
          issuer.replaceFirst(slash, '');
      return sameIssuer && token is String ? token : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(
    String userId,
    String refreshToken, {
    required String issuer,
  }) => _inTurn(
    userId,
    () => _storage.write(
      key: _key(userId),
      value: jsonEncode({'issuer': issuer, 'token': refreshToken}),
    ),
  );

  @override
  Future<void> delete(String userId) =>
      _inTurn(userId, () => _storage.delete(key: _key(userId)));
}
