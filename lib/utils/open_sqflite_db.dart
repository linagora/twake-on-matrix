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

/// The database of [dbName] is encrypted and its key cannot be read from the
/// keychain. The file and the key are left untouched: opening it without the
/// key would fail later, and recreating it would drop the session and the
/// local E2EE keys. A later launch opens it.
class SqliteKeyUnavailableException implements Exception {
  SqliteKeyUnavailableException(this.dbName);

  final String dbName;

  @override
  String toString() => 'SqliteKeyUnavailableException: key of $dbName';
}

// Never log the exception itself: for SQL errors it carries the statement,
// and so the key.
String _describe(Object e) =>
    '${e.runtimeType}${e is DatabaseException ? ' code ${e.getResultCode()}' : ''}';

bool _isNotADatabase(Object e) =>
    e is DatabaseException &&
    (e.getResultCode() == 26 ||
        e.toString().contains('file is not a database'));

Future<Database> _openEncrypted(String dbName, String dbPath) async {
  final keyStore = SqliteKeyStore();
  final export = File('$dbPath.encrypted');
  final plain = await _isPlainText(dbPath);
  final String key;
  try {
    key = await keyStore.keyFor(dbName);
  } catch (e) {
    final encrypted =
        !plain && (await _hasContent(dbPath) || await export.exists());
    if (encrypted) {
      Logs().e('Key of $dbName unavailable: ${_describe(e)}');
      throw SqliteKeyUnavailableException(dbName);
    }
    Logs().w(
      'Secure storage unavailable, opening $dbName unencrypted: '
      '${_describe(e)}',
    );
    return databaseFactoryFfi.openDatabase(dbPath);
  }
  if (plain) {
    if (!await _encryptPlaintext(dbPath, key)) {
      // The plaintext file is intact: use it as is, retry on next launch.
      return databaseFactoryFfi.openDatabase(dbPath);
    }
  } else if (await export.exists()) {
    await _adoptExport(dbPath, key);
  }
  try {
    return await _openWithKey(dbPath, key);
  } catch (e) {
    // Only a wrong key or a corrupt file is recreated: any other failure
    // (I/O, database locked) must not cost the user the database.
    if (!_isNotADatabase(e)) rethrow;
    Logs().w('Cannot open encrypted $dbName, recreating it: ${_describe(e)}');
    await _deleteFiles(dbPath);
    await keyStore.delete(dbName);
    return _openEncrypted(dbName, dbPath);
  }
}

/// Exports the plaintext database to `.encrypted`, checks that it opens with
/// [key], then renames it over [dbPath]. The plaintext file is replaced only
/// by a verified copy; false (plaintext untouched) on any failure.
Future<bool> _encryptPlaintext(String dbPath, String key) async {
  final export = File('$dbPath.encrypted');
  try {
    if (await export.exists()) await export.delete();
    final plainDb = await databaseFactoryFfi.openDatabase(dbPath);
    try {
      await plainDb.execute(
        "ATTACH DATABASE '${export.path}' AS encrypted KEY '$key';",
      );
      await plainDb.execute("SELECT sqlcipher_export('encrypted');");
      await plainDb.execute('DETACH DATABASE encrypted;');
    } finally {
      await plainDb.close();
    }
    await _replaceWithExport(dbPath, key);
    return true;
  } catch (e) {
    Logs().e('Cannot encrypt $dbPath, keeping it untouched: ${_describe(e)}');
    try {
      if (await export.exists()) await export.delete();
    } catch (_) {}
    return false;
  }
}

/// [dbPath] is not plaintext and an export is next to it: an earlier
/// migration was interrupted. A verified export is the authoritative copy.
Future<void> _adoptExport(String dbPath, String key) async {
  try {
    await _replaceWithExport(dbPath, key);
  } catch (e) {
    if (!_isNotADatabase(e)) rethrow;
    Logs().w('Leftover export of $dbPath is unusable: ${_describe(e)}');
  }
}

Future<void> _replaceWithExport(String dbPath, String key) async {
  final export = '$dbPath.encrypted';
  await (await _openWithKey(export, key)).close();
  for (final suffix in ['-wal', '-shm']) {
    final file = File('$dbPath$suffix');
    if (await file.exists()) await file.delete();
  }
  await File(export).rename(dbPath);
}

Future<Database> _openWithKey(String dbPath, String key) async {
  final helper = SQfLiteEncryptionHelper(
    factory: databaseFactoryFfi,
    path: dbPath,
    cipher: key,
  );
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

Future<bool> _hasContent(String dbPath) async {
  final file = File(dbPath);
  return await file.exists() && await file.length() > 0;
}

Future<bool> _isPlainText(String dbPath) async {
  final file = File(dbPath);
  if (!await file.exists()) return false;
  final raf = await file.open();
  try {
    final head = await raf.read(16);
    return String.fromCharCodes(head) == 'SQLite format 3\u0000';
  } finally {
    await raf.close();
  }
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
