import 'dart:io';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/sqlite_key_store.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database?> openSqfliteDb({String? name}) async {
  final databaseFactory = databaseFactoryFfi;
  final Directory baseDir = PlatformInfos.isMobile
      ? await getApplicationDocumentsDirectory()
      : await getApplicationSupportDirectory();
  final dbName = name ?? AppConfig.applicationName;
  final String dbPath = join(baseDir.path, "databases", "$dbName.db");
  await Directory(dirname(dbPath)).create(recursive: true);
  if (!PlatformInfos.isDesktop) return databaseFactory.openDatabase(dbPath);
  return _openEncrypted(dbName, dbPath);
}

Future<Database> _openEncrypted(String dbName, String dbPath) async {
  final keyStore = SqliteKeyStore();
  final String key;
  try {
    key = await keyStore.keyFor(dbName);
  } catch (e) {
    Logs().w('Secure storage unavailable, opening $dbName unencrypted: $e');
    return databaseFactoryFfi.openDatabase(dbPath);
  }
  try {
    return await _openWithKey(dbPath, key);
  } catch (e) {
    Logs().w('Cannot open encrypted $dbName, recreating it: $e');
    await _deleteFiles(dbPath);
    await keyStore.delete(dbName);
    return _openWithKey(dbPath, await keyStore.keyFor(dbName));
  }
}

Future<Database> _openWithKey(String dbPath, String key) async {
  final helper = SQfLiteEncryptionHelper(
    factory: databaseFactoryFfi,
    path: dbPath,
    cipher: key,
  );
  await helper.ensureDatabaseFileEncrypted();
  final db = await databaseFactoryFfi.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(onConfigure: helper.applyPragmaKey),
  );
  try {
    await db.rawQuery('SELECT count(*) FROM sqlite_master');
  } catch (_) {
    await db.close();
    rethrow;
  }
  return db;
}

Future<void> _deleteFiles(String dbPath) async {
  for (final suffix in ['', '-wal', '-shm', '.encrypted']) {
    final file = File('$dbPath$suffix');
    if (await file.exists()) await file.delete();
  }
}

Future<void> deleteSqfliteDb(String path) async {
  final databaseFactory = databaseFactoryFfi;
  await databaseFactory.deleteDatabase(path);
}
