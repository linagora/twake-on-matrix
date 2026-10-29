import 'package:collection/collection.dart';
import 'dart:convert';

import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_restore_token.dart';
import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_session.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matrix/matrix.dart';

class KeychainSharingManager {
  static FlutterSecureStorage get _secureStorage => const FlutterSecureStorage(
    iOptions: IOSOptions(
      groupId: AppConfig.iOSKeychainSharingId,
      accountName: AppConfig.iOSKeychainSharingAccount,
      synchronizable: false,
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _ssssRecoveryKeyPrefix = 'ssss_recovery_';

  static Future<void> saveRecoveryKey({
    required String? userId,
    required String recoveryKey,
  }) async {
    if (!PlatformInfos.isIOS || userId == null) return;
    try {
      await _secureStorage.write(
        key: '$_ssssRecoveryKeyPrefix$userId',
        value: recoveryKey,
      );
      Logs().d('[KeychainSharing] Saved SSSS recovery key for $userId');
    } catch (e, s) {
      Logs().wtf('[KeychainSharing] Unable to save SSSS recovery key', e, s);
    }
  }

  static Future<void> deleteRecoveryKey({required String? userId}) async {
    if (!PlatformInfos.isIOS || userId == null) return;
    try {
      await _secureStorage.delete(key: '$_ssssRecoveryKeyPrefix$userId');
      Logs().d('[KeychainSharing] Deleted SSSS recovery key for $userId');
    } catch (e, s) {
      Logs().wtf('[KeychainSharing] Unable to delete SSSS recovery key', e, s);
    }
  }

  static const String _notificationDeviceName = 'Twake Chat notifications';

  /// Written by the NSE: the ed25519 key it generated for its device.
  static const String _nseDeviceKeyPrefix = 'nse_ed25519_';

  /// Gives the iOS notification extension its own device.
  ///
  /// The extension runs its own crypto engine. Sharing the app's device with
  /// it makes it upload its own identity keys over the app's ones and consume
  /// the app's to-device messages. The dedicated device comes from a second
  /// SSO login: [loginToken] is the token returned by that SSO flow.
  static Future<void> createNotificationSession(
    Client client,
    String loginToken,
  ) => _pendingCreation = _createNotificationSession(client, loginToken);

  /// Lets a logout wait for a session being created, which it must delete.
  static Future<void>? _pendingCreation;

  static Future<void> _createNotificationSession(
    Client client,
    String loginToken,
  ) async {
    final userId = client.userID;
    final homeserver = client.homeserver;
    if (userId == null || homeserver == null) return;
    await _logoutNotificationSession(client, userId);
    final login =
        await MatrixApi(
          homeserver: homeserver,
          httpClient: client.httpClient,
        ).login(
          LoginType.mLoginToken,
          token: loginToken,
          initialDeviceDisplayName: _notificationDeviceName,
        );
    if (login.userId != userId) {
      // The SSO flow signed another account in: never hand it to the extension.
      await MatrixApi(
        homeserver: homeserver,
        accessToken: login.accessToken,
        httpClient: client.httpClient,
      ).logout();
      throw Exception('SSO login returned ${login.userId}, expected $userId');
    }
    await save(
      KeychainSharingRestoreToken(
        session: KeychainSharingSession(
          accessToken: login.accessToken,
          userId: userId,
          deviceId: login.deviceId,
          homeserverUrl: homeserver.toString(),
        ),
        dedicated: true,
      ),
    );
    Logs().i(
      '[KeychainSharing] Notification device ${login.deviceId} for $userId',
    );
  }

  /// The SSO provider that signs the extension in, or null without SSO.
  static Future<String?> notificationSsoProviderId(Client client) async {
    try {
      final flows = await client.getLoginFlows();
      final sso = flows?.firstWhereOrNull(
        (flow) => flow.type == AuthenticationTypes.sso,
      );
      final providers = sso?.additionalProperties['identity_providers'];
      // ponytail: first provider; pick the app's own one if a server ever
      // offers several.
      return providers is List && providers.isNotEmpty
          ? (providers.first as Map)['id'] as String?
          : null;
    } catch (e, s) {
      Logs().w('Unable to read login flows', e, s);
      return null;
    }
  }

  /// The app cross-signs the extension's device, so it needs the
  /// self-signing key in cache. Without cross-signing, senders share keys with
  /// every device anyway.
  static Future<bool> notificationPreviewsLocked(Client client) async {
    final cached = await client.encryption?.crossSigning.isCached() ?? false;
    return client.userDeviceKeys[client.userID]?.masterKey != null && !cached;
  }

  /// Whether the extension has its own device for [client].
  static Future<bool> hasNotificationSession(Client client) async {
    final userId = client.userID;
    if (!PlatformInfos.isIOS || userId == null) return false;
    final token = await read(userId: userId);
    return token?.dedicated == true &&
        token?.session.deviceId != client.deviceID;
  }

  /// Removes a keychain session that is not a dedicated extension session.
  ///
  /// Older versions stored the app's own session there, which made the
  /// extension take over the app's device.
  static Future<void> removeAppSession(Client client) async {
    final userId = client.userID;
    if (!PlatformInfos.isIOS || userId == null) return;
    final token = await read(userId: userId);
    if (token == null) return;
    if (token.dedicated != true || token.session.deviceId == client.deviceID) {
      Logs().i('[KeychainSharing] Removing the app session of $userId');
      await delete(userId: userId);
    }
  }

  /// Keeps the extension's device usable: forgets it once revoked, and
  /// cross-signs it so senders that share keys only with cross-signed
  /// devices (Dart SDK `crossVerifiedIfEnabled`) reach it.
  ///
  /// The device publishes its keys on its first push, so signing waits for
  /// a later call (startup or own device list change).
  static Future<void> checkNotificationDevice(Client client) async {
    final userId = client.userID;
    final homeserver = client.homeserver;
    if (!PlatformInfos.isIOS || userId == null || homeserver == null) return;
    final token = await read(userId: userId);
    if (token?.dedicated != true) return;
    final session = token!.session;
    try {
      await MatrixApi(
        homeserver: homeserver,
        accessToken: session.accessToken,
        httpClient: client.httpClient,
      ).getTokenOwner();
    } on MatrixException catch (e) {
      if (e.error == MatrixError.M_UNKNOWN_TOKEN) {
        Logs().i('[KeychainSharing] Notification device revoked for $userId');
        await delete(userId: userId);
      }
      return;
    } catch (_) {
      return; // offline: try again later
    }
    final encryption = client.encryption;
    if (encryption == null || !await encryption.crossSigning.isCached()) {
      return;
    }
    try {
      await client.updateUserDeviceKeys();
      final device =
          client.userDeviceKeys[userId]?.deviceKeys[session.deviceId];
      // Same check as a sender's `ShareKeysWith.crossVerifiedIfEnabled`.
      if (device == null ||
          device.hasValidSignatureChain(verifiedByTheirMasterKey: true)) {
        return;
      }
      // Sign only the keys the extension generated, never keys the server
      // published for that device id.
      final nseKey = await _secureStorage.read(
        key: '$_nseDeviceKeyPrefix${session.deviceId}',
      );
      if (nseKey == null || nseKey != device.ed25519Key) {
        Logs().w(
          '[KeychainSharing] Keys of ${device.deviceId} do not match the NSE',
        );
        return;
      }
      await encryption.crossSigning.sign([device]);
      Logs().i(
        '[KeychainSharing] Signed notification device ${device.deviceId}',
      );
    } catch (e, s) {
      Logs().w('[KeychainSharing] Unable to sign notification device', e, s);
    }
  }

  /// Logs the notification device out and forgets its session.
  static Future<void> logoutNotificationSession(Client client) async {
    final userId = client.userID;
    if (!PlatformInfos.isIOS || userId == null) return;
    await _pendingCreation?.catchError((_) {});
    // userId is kept: the client may have been cleared while waiting.
    await _logoutNotificationSession(client, userId);
  }

  /// Forgets the session before the network call, so the extension stops
  /// using it even if the logout request hangs.
  static Future<void> _logoutNotificationSession(
    Client client,
    String userId,
  ) async {
    if (!PlatformInfos.isIOS) return;
    try {
      final session = (await read(userId: userId))?.session;
      await delete(userId: userId);
      if (session != null && session.deviceId != client.deviceID) {
        await MatrixApi(
          homeserver: Uri.parse(session.homeserverUrl),
          accessToken: session.accessToken,
          httpClient: client.httpClient,
        ).logout();
      }
    } catch (e, s) {
      Logs().w('[KeychainSharing] Unable to log out notification device', e, s);
    }
  }

  static Future save(KeychainSharingRestoreToken token) => _secureStorage.write(
    key: token.session.userId,
    value: jsonEncode(token.toJson()),
  );

  static Future<KeychainSharingRestoreToken?> read({
    required String userId,
  }) async {
    try {
      final token = await _secureStorage.read(key: userId);
      if (token != null) {
        return KeychainSharingRestoreToken.fromJson(jsonDecode(token));
      }
    } catch (e, s) {
      Logs().wtf('Unable to read token from Secure storage', e, s);
      return null;
    }
    return null;
  }

  static Future delete({required String? userId}) {
    if (userId != null) {
      return _secureStorage.delete(key: userId);
    } else {
      return _secureStorage.deleteAll();
    }
  }
}
