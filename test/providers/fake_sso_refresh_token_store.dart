import 'dart:async';

import 'package:twake_chat/data/drive/datasources_impl/sso_refresh_token_store.provider.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:twake_chat/domain/drive/sources/sso_refresh_token_store.dart';

/// The secure store of the refresh token, in memory. [failing] makes every call
/// throw, as a Keychain that cannot be opened does.
class FakeSsoRefreshTokenStore implements SsoRefreshTokenStore {
  final tokens = <String, String>{};

  /// The issuer each token was written for; a token set by hand has none and
  /// is read for any issuer.
  final issuers = <String, String>{};
  bool failing = false;
  final deleted = <String>[];

  /// How many times `write` was called.
  int writes = 0;

  /// Holds every read until the test completes it.
  Completer<void>? readGate;

  @override
  Future<String?> read(String userId, {required String issuer}) async {
    await readGate?.future;
    if (failing) throw Exception('the store is closed');
    final writtenFor = issuers[userId];
    if (writtenFor != null && writtenFor != issuer) return null;
    return tokens[userId];
  }

  @override
  Future<void> write(
    String userId,
    String refreshToken, {
    required String issuer,
  }) async {
    if (failing) throw Exception('the store is closed');
    writes++;
    tokens[userId] = refreshToken;
    issuers[userId] = issuer;
  }

  @override
  Future<void> delete(String userId) async {
    if (failing) throw Exception('the store is closed');
    deleted.add(userId);
    tokens.remove(userId);
    issuers.remove(userId);
  }
}

Override useSsoRefreshTokenStore(FakeSsoRefreshTokenStore store) =>
    ssoRefreshTokenStoreProvider.overrideWithValue(store);
