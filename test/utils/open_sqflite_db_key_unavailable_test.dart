import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twake_chat/utils/open_sqflite_db.dart';

import 'fake_keychain.dart';

// The keychain cannot be read (locked, refused, daemon down) when the account
// database is already encrypted: opening it without its key would only fail
// later, and recreating it would log the user out and drop the local E2EE
// keys. The open fails for this account with SqliteKeyUnavailableException
// and leaves the file and its key alone; the next launch opens it.

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);

  final String dir;

  @override
  Future<String?> getApplicationSupportPath() async => dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late PathProviderPlatform originalPathProvider;
  late FakeKeychain keychain;
  Database? db;

  String dbPath(String name) => p.join(root.path, 'databases', '$name.db');

  setUp(() {
    (keychain = FakeKeychain()).install();
    root = Directory.systemTemp.createTempSync(
      'open_sqflite_db_key_unavailable',
    );
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(root.path);
  });

  tearDown(() async {
    await db?.close();
    db = null;
    PathProviderPlatform.instance = originalPathProvider;
    root.deleteSync(recursive: true);
  });

  Future<void> createEncrypted(String name) async {
    db = await openSqfliteDb(name: name);
    await db!.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
    await db!.insert('t', {'id': 1, 'v': 'kept'});
    await db!.close();
    db = null;
  }

  group('an encrypted database whose key cannot be read', () {
    test('fails to open with SqliteKeyUnavailableException', () async {
      await createEncrypted('acc');
      keychain.failReads = true;

      await expectLater(
        () async => db = await openSqfliteDb(name: 'acc'),
        throwsA(isA<SqliteKeyUnavailableException>()),
      );
    });

    test('keeps the file and its key, and opens on the next launch', () async {
      await createEncrypted('acc');
      final bytes = File(dbPath('acc')).readAsBytesSync();
      final key = keychain.stored('sqlite_key_acc');
      keychain.failReads = true;

      try {
        db = await openSqfliteDb(name: 'acc');
      } catch (_) {}
      await db?.close();
      db = null;

      expect(File(dbPath('acc')).readAsBytesSync(), equals(bytes));
      expect(keychain.stored('sqlite_key_acc'), key);
      keychain.failReads = false;
      db = await openSqfliteDb(name: 'acc');
      expect(await db!.query('t'), [
        {'id': 1, 'v': 'kept'},
      ]);
    });
  });

  test('a plaintext database whose key cannot be read still opens with its '
      'rows', () async {
    await Directory(p.dirname(dbPath('legacy'))).create(recursive: true);
    final plain = await databaseFactoryFfi.openDatabase(dbPath('legacy'));
    await plain.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
    await plain.insert('t', {'id': 1, 'v': 'legacy-row'});
    await plain.close();
    keychain.failReads = true;

    db = await openSqfliteDb(name: 'legacy');

    expect(await db!.query('t'), [
      {'id': 1, 'v': 'legacy-row'},
    ]);
  });
}
