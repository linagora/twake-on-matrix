import 'dart:convert';
import 'dart:io';

import 'package:fluffychat/domain/keychain_sharing/keychain_sharing_manager.dart';
import 'package:fluffychat/domain/keychain_sharing/keychain_sharing_restore_token.dart';
import 'package:fluffychat/domain/keychain_sharing/keychain_sharing_session.dart';
import 'package:fluffychat/migrate_steps/migrate_v6_to_v7/migrate_v6_to_v7.dart';
import 'package:flutter/foundation.dart' hide Key;
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/manager/storage_directory_manager.dart';

class FlutterHiveCollectionsDatabase extends HiveCollectionsDatabase {
  FlutterHiveCollectionsDatabase(
    super.name,
    String super.path, {
    super.key,
    super.onStartMigrating,
  });

  @override
  int get version => 7;

  static const String cipherStorageKey = 'hive_encryption_key';

  static Future<FlutterHiveCollectionsDatabase> databaseBuilder(
    Client client,
  ) async {
    Logs().d('Open Hive...');
    HiveAesCipher? hiverCipher;
    try {
      // Workaround for secure storage is calling Platform.operatingSystem on web
      if (kIsWeb || PlatformInfos.isIOS) {
        // ignore: unawaited_futures
        throw MissingPluginException();
      }

      const secureStorage = FlutterSecureStorage();
      final containsEncryptionKey =
          await secureStorage.read(key: cipherStorageKey) != null;
      if (!containsEncryptionKey) {
        // do not try to create a buggy secure storage for new Linux users
        if (Platform.isLinux) throw MissingPluginException();
        final key = Hive.generateSecureKey();
        await secureStorage.write(
          key: cipherStorageKey,
          value: base64UrlEncode(key),
        );
      }

      // workaround for if we just wrote to the key and it still doesn't exist
      final rawEncryptionKey = await secureStorage.read(key: cipherStorageKey);
      if (rawEncryptionKey == null) throw MissingPluginException();

      hiverCipher = HiveAesCipher(base64Url.decode(rawEncryptionKey));
    } on MissingPluginException catch (_) {
      const FlutterSecureStorage()
          .delete(key: cipherStorageKey)
          .catchError((_) {});
      Logs().i('Hive encryption is not supported on this platform');
    } catch (e, s) {
      const FlutterSecureStorage()
          .delete(key: cipherStorageKey)
          .catchError((_) {});
      Logs().w('Unable to init Hive encryption', e, s);
    }

    final db = FlutterHiveCollectionsDatabase(
      'hive_collections_${client.clientName.replaceAll(' ', '_').toLowerCase()}',
      await _findDatabasePath(client),
      key: hiverCipher,
      onStartMigrating: _onStartMigrating,
    );
    try {
      Logs().i('FlutterHiveCollectionsDatabase()::databaseBuilder()::open()');
      await db.open();
    } catch (e, s) {
      Logs().w('Unable to open Hive. Delete database and storage key...', e, s);
      const FlutterSecureStorage().delete(key: cipherStorageKey);
      await db
          .clear(supportDeleteCollections: !PlatformInfos.isWeb)
          .catchError((_) {});
      await Hive.deleteFromDisk();
      rethrow;
    }
    Logs().d('Hive is ready');
    return db;
  }

  static Future<String> _findDatabasePath(Client client) async {
    String path = client.clientName;
    if (!kIsWeb) {
      Directory directory;
      try {
        if (Platform.isLinux) {
          directory = await getApplicationSupportDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } catch (_) {
        try {
          directory = await getLibraryDirectory();
        } catch (_) {
          directory = Directory.current;
        }
      }
      // do not destroy your stable FluffyChat in debug mode
      directory = Directory(
        directory.uri.resolve(kDebugMode ? 'hive_debug' : 'hive').toFilePath(),
      );
      directory.create(recursive: true);
      path = directory.path;
    }
    return path;
  }

  @override
  int get maxFileSize => supportsFileStoring ? 100 * 1024 * 1024 : 0;

  @override
  bool get supportsFileStoring => !kIsWeb;

  @override
  Future<Uint8List?> getFile(String eventId, String fileName) async {
    if (!supportsFileStoring) return null;
    final file = File(
      await StorageDirectoryManager.instance.getFilePathInAppDownloads(
        eventId: eventId,
        fileName: fileName,
      ),
    );
    if (await file.exists() == false) return null;
    final bytes = await file.readAsBytes();
    return bytes;
  }

  @override
  Future storeEventFile(
    String eventId,
    String fileName,
    Uint8List bytes,
    int time,
  ) async {
    if (!supportsFileStoring) return null;
    final file = File(
      await StorageDirectoryManager.instance.getFilePathInAppDownloads(
        eventId: eventId,
        fileName: fileName,
      ),
    );
    if (await file.exists()) return;
    await file.writeAsBytes(bytes);
    return;
  }

  @override
  Future<File?> getFileEntity(String eventId, String fileName) async {
    if (!supportsFileStoring) return null;
    final file = File(
      await StorageDirectoryManager.instance.getFilePathInAppDownloads(
        eventId: eventId,
        fileName: fileName,
      ),
    );
    if (await file.exists() == false) return null;
    return file;
  }

  @override
  Future<void> updateClient(
    String homeserverUrl,
    String token,
    String userId,
    String? deviceId,
    String? deviceName,
    String? prevBatch,
    String? olmAccount,
  ) async {
    if (PlatformInfos.isIOS) {
      final restoreToken = KeychainSharingRestoreToken(
        session: KeychainSharingSession(
          accessToken: token,
          userId: userId,
          deviceId: deviceId ?? "",
          homeserverUrl: homeserverUrl,
        ),
      );
      await KeychainSharingManager.save(restoreToken);
    }
    return super.updateClient(
      homeserverUrl,
      token,
      userId,
      deviceId,
      deviceName,
      prevBatch,
      olmAccount,
    );
  }

  @override
  Future<int> insertClient(
    String name,
    String homeserverUrl,
    String token,
    String userId,
    String? deviceId,
    String? deviceName,
    String? prevBatch,
    String? olmAccount,
  ) async {
    if (PlatformInfos.isIOS) {
      final restoreToken = KeychainSharingRestoreToken(
        session: KeychainSharingSession(
          accessToken: token,
          userId: userId,
          deviceId: deviceId ?? "",
          homeserverUrl: homeserverUrl,
        ),
      );
      await KeychainSharingManager.save(restoreToken);
    }
    return super.insertClient(
      name,
      homeserverUrl,
      token,
      userId,
      deviceId,
      deviceName,
      prevBatch,
      olmAccount,
    );
  }

  @override
  Future<void> clear({bool supportDeleteCollections = false}) async {
    if (PlatformInfos.isIOS) {
      // TODO: Should pass userId here when support multiple accounts
      await KeychainSharingManager.delete(userId: null);
    }
    return super.clear(supportDeleteCollections: supportDeleteCollections);
  }

  static void _onStartMigrating(int currentVersion, int newVersion) async {
    Logs().d(
      'FlutterHiveCollectionsDatabase::startMigrationProcess() CurrentVersion - $currentVersion || NewVersion - $newVersion',
    );
    if (currentVersion == 6 && newVersion == 7) {
      await MigrateV6ToV7().onMigrate(currentVersion, newVersion);
    }
  }
}
