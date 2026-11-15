import 'dart:convert';

import 'package:twake_chat/config/app_config.dart';
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

  /// Same invalidation once more so existing installs ask the server for
  /// per-thread counters (`unread_thread_notifications`).
  static const String _threadCountersFilterMigratedPrefix =
      'im.twake.store.sync_filter_thread_counters_v1';

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
      await Future.wait(clients.map(initClient));
    }
    // A logged-out client next to others is not deleted here: the account
    // repository lists it as a pending removal, which is retried until it works.
    return clients;
  }

  /// Initialises [client] and syncs its session to the keychain. A failure is
  /// logged, not thrown.
  static Future<void> initClient(Client client) => client
      .init(waitForFirstSync: false, waitUntilLoadCompletedLoaded: false)
      .then((_) => _syncKeychainForClient(client))
      .catchError((e, s) => Logs().e('Unable to initialize client', e, s));

  /// The first client that holds a session. It initialises one client at a
  /// time and stops at the first logged-in one: the background isolate of a
  /// push needs one account, not all of them.
  static Future<Client?> firstLoggedIn(Iterable<Client> clients) async {
    for (final client in clients) {
      await initClient(client);
      if (client.isLogged()) return client;
    }
    return null;
  }

  /// The clients that hold a session. A logged-out client stays loaded while
  /// its removal is pending; screens that read profiles or homeservers, and the
  /// background push, must not treat it as an account.
  static List<Client> loggedIn(Iterable<Client> clients) =>
      clients.where((client) => client.isLogged()).toList();

  /// The client that serves a push: [preferred] while it holds a session, else
  /// the first of [held] that does, else [preferred]. It only picks among
  /// clients the app already runs: building another one for the same account
  /// would start a second sync on the same database.
  static Client serving(Client preferred, Iterable<Client> held) =>
      preferred.isLogged()
      ? preferred
      : loggedIn(held).firstOrNull ?? preferred;

  /// Deletes what a client stored: its database and, for the SQLite one, the
  /// file.
  static Future<void> deleteClientStorage(DatabaseApi database) async {
    await database.delete();
    if (database is MatrixSdkDatabase) {
      final path = database.database?.path;
      if (path != null) await deleteSqfliteDb(path);
    }
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

  static Future<void> _syncKeychainForClient(Client client) =>
      KeychainSharingManager.removeAppSession(client);

  static NativeImplementations get nativeImplementations => kIsWeb
      ? const NativeImplementationsDummy()
      : NativeImplementationsIsolate(compute, vodozemacInit: () => vod.init());

  /// `unread_thread_notifications` makes the server count unread messages per
  /// thread instead of mixing them into the room counters.
  /// Read when used: it follows [AppConfig.threadsEnabled].
  static Filter get syncFilter => Filter(
    room: RoomFilter(
      includeLeave: true,
      state: StateFilter(lazyLoadMembers: true),
      timeline: AppConfig.threadsEnabled
          ? StateFilter(unreadThreadNotifications: true)
          : null,
    ),
  );

  static Future<Client> createClient(String clientName) async {
    final database = await MatrixSdkDatabase.init(
      clientName,
      database: await openSqfliteDb(name: clientName),
    );
    await migrateSyncFilter(database, clientName);
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
        // Globe badge on public rooms in the chat list; rooms synced before
        // this was added only get it on their next join_rules change.
        EventTypes.RoomJoinRules,
      },
      // Matrix 12+ no longer caches loadArchive() results for getRoomById().
      // Persist left rooms via sync; keep SDK default member lazy-loading.
      syncFilter: syncFilter,
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

  /// The SDK defines a sync filter only when none is saved, so the saved
  /// filter id is dropped once for the leave rooms, then whenever the threads
  /// flag differs from the state the saved filter was defined for.
  static Future<void> migrateSyncFilter(
    DatabaseApi database,
    String clientName,
  ) async {
    await _migrateOnce(
      database,
      clientName,
      '$_includeLeaveFilterMigratedPrefix.$clientName',
      migrated: (stored) => stored == '1',
      marker: '1',
    );
    final threads = AppConfig.threadsEnabled ? 'on' : 'off';
    await _migrateOnce(
      database,
      clientName,
      '$_threadCountersFilterMigratedPrefix.$clientName',
      // '1' was written when the filter asked for the thread counters.
      migrated: (stored) => switch (stored) {
        null => threads == 'off',
        '1' => threads == 'on',
        _ => stored == threads,
      },
      marker: threads,
    );
  }

  static Future<void> _migrateOnce(
    DatabaseApi database,
    String clientName,
    String migratedKey, {
    required bool Function(String? stored) migrated,
    required String marker,
  }) async {
    final store = Store();
    if (migrated(await store.getItem(migratedKey))) return;

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
      await store.setItem(migratedKey, marker);
    } catch (e, s) {
      Logs().w(
        'Unable to invalidate the persisted sync filter ($migratedKey)',
        e,
        s,
      );
    }
  }
}
