import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';

/// Holds, in memory only, the SSO tokens of a login until Drive takes them.
///
/// The login runs before the account is active, so it cannot hand its tokens
/// to the Drive session directly. They wait here, per Matrix user id, and the
/// Drive session reads them the first time it needs a token. They leave when
/// the session holds them or when the account logs out (see
/// `ssoTokenVaultProvider`). They are never written to disk or logged.
///
/// Writers: the mobile SSO login (`put`) and the two places that empty an
/// entry (`remove`): the Drive session once it holds the tokens, and the
/// logout listener of `ssoTokenVaultProvider`.
///
/// TODO: [transitional] ToM-Private#3: the login could hand its tokens to the
/// Drive session directly once a login makes its account active before it
/// returns; then this vault goes away.
class SsoTokenVault {
  final _byUser = <String, DriveIdToken>{};

  void put(String userId, DriveIdToken tokens) => _byUser[userId] = tokens;

  DriveIdToken? of(String userId) => _byUser[userId];

  /// Drops the tokens of [userId]: the Drive session holds them, or the
  /// account is gone.
  void remove(String userId) => _byUser.remove(userId);
}
