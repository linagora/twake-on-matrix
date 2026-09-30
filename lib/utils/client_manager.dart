import 'dart:convert';

import 'package:twake_chat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:twake_chat/utils/custom_http_client.dart';
import 'package:twake_chat/utils/custom_image_resizer.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/flutter_hive_collections_database.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/twake_client.dart';
import 'package:twake_chat/utils/open_sqflite_db.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as vod;
import 'package:matrix/encryption/utils/key_verification.dart';
import 'package:matrix/matrix.dart';

import 'famedlysdk_store.dart';

abstract class ClientManager {
  static const String clientNamespace = 'im.twake.store.clients';

  /// Legacy key used before the FluffyChat-to-Twake rename.
  ///
  /// Read as a fallback so existing installs don't lose their client list
  /// on upgrade; new writes always go to [clientNamespace].
  static const String _legacyClientNamespace = 'im.fluffychat.store.clients';

  /// One-shot: clear persisted sync_filter_id so Matrix 12 sessions redefine
  /// the filter with includeLeave (SDK skips defineFilter when an ID exists).
  static const String _includeLeaveFilterMigratedPrefix =
      'im.twake.store.sync_filter_include_leave_v1';

  static Future<List<Client>> getClients({bool initialize = true}) async {
    final clientNames = <String>{};
    var migratedFromLegacyKey = false;
    try {
      var rawClientNames = await Store().getItem(clientNamespace);
      if (rawClientNames == null) {
        rawClientNames = await Store().getItem(_legacyClientNamespace);
        migratedFromLegacyKey = rawClientNames != null;
      }
      if (rawClientNames != null) {
        final clientNamesList = (jsonDecode(rawClientNames) as List)
            .cast<String>();
        clientNames.addAll(clientNamesList);
      }
    } catch (e, s) {
      Logs().w('Client names in store are corrupted', e, s);
      await Store().deleteItem(clientNamespace);
    }
    if (clientNames.isEmpty) {
      clientNames.add(PlatformInfos.clientName);
      await Store().setItem(clientNamespace, jsonEncode(clientNames.toList()));
    } else if (migratedFromLegacyKey) {
      await Store().setItem(clientNamespace, jsonEncode(clientNames.toList()));
      await Store().deleteItem(_legacyClientNamespace);
    }
    final clients = await Future.wait(clientNames.map(createClient));
    if (initialize) {
      await Future.wait(
        clients.map(
          (client) => client
              .init(
                waitForFirstSync: false,
                waitUntilLoadCompletedLoaded: false,
              )
              .then((_) => _syncKeychainForClient(client))
              .catchError(
                (e, s) => Logs().e('Unable to initialize client', e, s),
              ),
        ),
      );
    }
    if (clients.length > 1 && clients.any((c) => !c.isLogged())) {
      final loggedOutClients = clients.where((c) => !c.isLogged()).toList();
      for (final client in loggedOutClients) {
        Logs().w(
          'Multi account is enabled but client ${client.userID} is not logged in. Removing...',
        );
        clientNames.remove(client.clientName);
        final database = client.database;
        await database.delete();
        if (database is MatrixSdkDatabase && database.database?.path != null) {
          await deleteSqfliteDb(database.database!.path);
        }
        clients.remove(client);
      }
      await Store().setItem(clientNamespace, jsonEncode(clientNames.toList()));
    }
    return clients;
  }

  static Future<void> addClientNameToStore(String clientName) async {
    final clientNamesList = <String>[];
    final rawClientNames = await Store().getItem(clientNamespace);
    if (rawClientNames != null) {
      final stored = (jsonDecode(rawClientNames) as List).cast<String>();
      clientNamesList.addAll(stored);
    }
    clientNamesList.add(clientName);
    await Store().setItem(clientNamespace, jsonEncode(clientNamesList));
  }

  static Future<void> removeClientNameFromStore(String clientName) async {
    final clientNamesList = <String>[];
    final rawClientNames = await Store().getItem(clientNamespace);
    if (rawClientNames != null) {
      final stored = (jsonDecode(rawClientNames) as List).cast<String>();
      clientNamesList.addAll(stored);
    }
    clientNamesList.remove(clientName);
    await Store().setItem(clientNamespace, jsonEncode(clientNamesList));
  }

  static Future<void> _syncKeychainForClient(Client client) async {
    if (!PlatformInfos.isIOS || !client.isLogged()) return;
    final accessToken = client.accessToken;
    final userId = client.userID;
    final homeserver = client.homeserver?.toString();
    if (accessToken == null || userId == null || homeserver == null) return;
    await KeychainSharingManager.saveSession(
      accessToken: accessToken,
      userId: userId,
      deviceId: client.deviceID ?? '',
      homeserverUrl: homeserver,
    );
  }

  static NativeImplementations get nativeImplementations => kIsWeb
      ? const NativeImplementationsDummy()
      : NativeImplementationsIsolate(compute, vodozemacInit: () => vod.init());

  static Future<Client> createClient(String clientName) async {
    final database = await MatrixSdkDatabase.init(
      clientName,
      database: await openSqfliteDb(name: clientName),
    );
    await _invalidatePersistedSyncFilterForIncludeLeave(database, clientName);
    return TwakeClient(
      clientName,
      httpClient: PlatformInfos.isAndroid
          ? CustomHttpClient.createHTTPClient()
          : null,
      verificationMethods: {
        KeyVerificationMethod.numbers,
        if (kIsWeb || PlatformInfos.isMobile || PlatformInfos.isLinux)
          KeyVerificationMethod.emoji,
      },
      importantStateEvents: <String>{
        // To make room emotes work
        'im.ponies.room_emotes',
        // To check which story room we can post in
        EventTypes.RoomPowerLevels,
      },
      // Matrix 12+ no longer caches loadArchive() results for getRoomById().
      // Persist left rooms via sync; keep SDK default member lazy-loading.
      syncFilter: Filter(
        room: RoomFilter(
          includeLeave: true,
          state: StateFilter(lazyLoadMembers: true),
        ),
      ),
      logLevel: kReleaseMode ? Level.warning : Level.verbose,
      database: database,
      legacyDatabaseBuilder: FlutterHiveCollectionsDatabase.databaseBuilder,
      supportedLoginTypes: {
        AuthenticationTypes.password,
        if (PlatformInfos.isMobile ||
            PlatformInfos.isWeb ||
            PlatformInfos.isMacOS)
          AuthenticationTypes.sso,
      },
      nativeImplementations: nativeImplementations,
      customImageResizer: PlatformInfos.isMobile ? customImageResizer : null,
    );
  }

  static Future<void> _invalidatePersistedSyncFilterForIncludeLeave(
    DatabaseApi database,
    String clientName,
  ) async {
    final store = Store();
    final migratedKey = '$_includeLeaveFilterMigratedPrefix.$clientName';
    if (await store.getItem(migratedKey) == '1') return;

    try {
      final account = await database.getClient(clientName);
      if (account != null && account['sync_filter_id'] != null) {
        final tokenExpiresAtMs = int.tryParse(
          account['token_expires_at']?.toString() ?? '',
        );
        await database.insertClient(
          clientName,
          account['homeserver_url'] as String,
          account['token'] as String,
          tokenExpiresAtMs == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(tokenExpiresAtMs),
          account['refresh_token'] as String?,
          account['user_id'] as String,
          account['device_id'] as String?,
          account['device_name'] as String?,
          account['prev_batch'] as String?,
          account['olm_account'] as String?,
          account['oidc_client_id'] as String?,
        );
      }
      await store.setItem(migratedKey, '1');
    } catch (e, s) {
      Logs().w(
        'Unable to invalidate sync filter for includeLeave migration',
        e,
        s,
      );
    }
  }
}
