import 'dart:convert';
import 'dart:io';

import 'package:fluffychat/utils/matrix_sdk_extensions/flutter_hive_collections_database.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';

class HiveCollectionToMDatabase {
  final String name;
  final String? path;
  final HiveCipher? key;

  late BoxCollection _collection;

  String get _tomConfigurationsBoxName => 'tom_configurations_box';
  late CollectionBox<Map> tomConfigurationsBox;

  HiveCollectionToMDatabase(this.name, this.path, {this.key});

  static Future<HiveCollectionToMDatabase> databaseBuilder() async {
    Logs().d('Open Hive for ToM...');
    HiveAesCipher? hiverCipher;
    try {
      // Workaround for secure storage is calling Platform.operatingSystem on web
      if (kIsWeb || PlatformInfos.isIOS) {
        // ignore: unawaited_futures
        throw MissingPluginException();
      }

      const secureStorage = FlutterSecureStorage();
      final containsEncryptionKey = await secureStorage.read(
            key: FlutterHiveCollectionsDatabase.cipherStorageKey,
          ) !=
          null;
      if (!containsEncryptionKey) {
        // do not try to create a buggy secure storage for new Linux users
        if (Platform.isLinux) throw MissingPluginException();
        final key = Hive.generateSecureKey();
        await secureStorage.write(
          key: FlutterHiveCollectionsDatabase.cipherStorageKey,
          value: base64UrlEncode(key),
        );
      }

      // workaround for if we just wrote to the key and it still doesn't exist
      final rawEncryptionKey = await secureStorage.read(
        key: FlutterHiveCollectionsDatabase.cipherStorageKey,
      );
      if (rawEncryptionKey == null) throw MissingPluginException();

      hiverCipher = HiveAesCipher(base64Url.decode(rawEncryptionKey));
    } on MissingPluginException catch (_) {
      const FlutterSecureStorage()
          .delete(key: FlutterHiveCollectionsDatabase.cipherStorageKey)
          .catchError((_) {});
      Logs().i('Hive encryption is not supported on this platform');
    } catch (e, s) {
      const FlutterSecureStorage()
          .delete(key: FlutterHiveCollectionsDatabase.cipherStorageKey)
          .catchError((_) {});
      Logs().w('Unable to init Hive encryption', e, s);
    }

    final db = HiveCollectionToMDatabase(
      'hive_collections_tom',
      await _findDatabasePath(),
      key: hiverCipher,
    );
    try {
      await db.open();
    } catch (e, s) {
      Logs().w('Unable to open ToM Hive.', e, s);
      const FlutterSecureStorage()
          .delete(key: FlutterHiveCollectionsDatabase.cipherStorageKey);
      await db.clear().catchError((_) {});
      await Hive.deleteFromDisk();
      rethrow;
    }
    Logs().d('Hive for ToM is ready');
    return db;
  }

  static Future<String> _findDatabasePath({String? path = 'tom_db'}) async {
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
    return path!;
  }

  Future<void> open() async {
    _collection = await BoxCollection.open(
      name,
      {_tomConfigurationsBoxName},
      path: path,
      key: key,
    );
    tomConfigurationsBox = await _collection.openBox(
      _tomConfigurationsBoxName,
      preload: true,
    );
  }

  Future<void> clear() async {
    await tomConfigurationsBox.clear();
    if (PlatformInfos.isMobile) {
      await _collection.deleteFromDisk();
    }
  }
}
