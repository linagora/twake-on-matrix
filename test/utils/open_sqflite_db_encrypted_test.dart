import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twake_chat/utils/open_sqflite_db.dart';
import 'package:twake_chat/utils/secure_storage.dart';
import 'package:twake_chat/utils/sqlite_key_store.dart';

// Limit: the test host is a desktop, so the mobile path (plaintext, no key)
// cannot be exercised here.

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);

  final String dir;

  @override
  Future<String?> getApplicationSupportPath() async => dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

final _plainHeader = 'SQLite format 3\u0000'.codeUnits;

List<int> _header(String path) {
  final raf = File(path).openSync();
  try {
    return raf.readSync(16);
  } finally {
    raf.closeSync();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late PathProviderPlatform originalPathProvider;
  Database? db;

  String dbPath(String name) => p.join(root.path, 'databases', '$name.db');

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    root = Directory.systemTemp.createTempSync('open_sqflite_db_encrypted');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(root.path);
  });

  tearDown(() async {
    await db?.close();
    db = null;
    PathProviderPlatform.instance = originalPathProvider;
    root.deleteSync(recursive: true);
  });

  test('a new desktop database file is not a plaintext SQLite file', () async {
    db = await openSqfliteDb(name: 'fresh');
    await db!.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
    await db!.insert('t', {'id': 1, 'v': 'secret-value'});
    await db!.close();
    db = null;

    expect(_header(dbPath('fresh')), isNot(equals(_plainHeader)));
  });

  test(
    'rows written to a new database read back after close and reopen',
    () async {
      db = await openSqfliteDb(name: 'fresh');
      await db!.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
      await db!.insert('t', {'id': 1, 'v': 'hello'});
      await db!.close();

      db = await openSqfliteDb(name: 'fresh');

      expect(await db!.query('t'), [
        {'id': 1, 'v': 'hello'},
      ]);
    },
  );

  test('the content of a new database is not readable in the file', () async {
    db = await openSqfliteDb(name: 'fresh');
    await db!.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
    await db!.insert('t', {'id': 1, 'v': 'needle-in-haystack'});
    await db!.close();
    db = null;

    final text = String.fromCharCodes(File(dbPath('fresh')).readAsBytesSync());
    expect(text, isNot(contains('needle-in-haystack')));
  });

  test('opening a database stores its key under sqlite_key_<name>', () async {
    db = await openSqfliteDb(name: 'fresh');

    expect(
      await secureStorage.read(key: 'sqlite_key_fresh'),
      matches(RegExp(r'^[0-9a-f]{64}$')),
    );
  });

  group('an existing plaintext database', () {
    Future<void> createPlaintext(String name) async {
      await Directory(p.dirname(dbPath(name))).create(recursive: true);
      final plain = await databaseFactoryFfi.openDatabase(dbPath(name));
      await plain.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
      await plain.insert('t', {'id': 1, 'v': 'legacy-row'});
      await plain.close();
      expect(_header(dbPath(name)), equals(_plainHeader));
    }

    test('keeps its rows after opening', () async {
      await createPlaintext('legacy');

      db = await openSqfliteDb(name: 'legacy');

      expect(await db!.query('t'), [
        {'id': 1, 'v': 'legacy-row'},
      ]);
    });

    test('is no longer plaintext on disk after opening', () async {
      await createPlaintext('legacy');

      db = await openSqfliteDb(name: 'legacy');
      await db!.close();
      db = null;

      expect(_header(dbPath('legacy')), isNot(equals(_plainHeader)));
      final text = String.fromCharCodes(
        File(dbPath('legacy')).readAsBytesSync(),
      );
      expect(text, isNot(contains('legacy-row')));
    });

    test('leaves no temporary .encrypted file behind', () async {
      await createPlaintext('legacy');

      db = await openSqfliteDb(name: 'legacy');
      await db!.close();
      db = null;

      final files = Directory(
        p.dirname(dbPath('legacy')),
      ).listSync().map((e) => p.basename(e.path)).toList();
      expect(files.where((f) => f.endsWith('.encrypted')), isEmpty);
      // -wal/-shm: not asserted beyond "no plaintext header remains".
      for (final f in files) {
        final path = p.join(p.dirname(dbPath('legacy')), f);
        expect(_header(path), isNot(equals(_plainHeader)), reason: f);
      }
    });

    test('is readable again after close and reopen', () async {
      await createPlaintext('legacy');
      db = await openSqfliteDb(name: 'legacy');
      await db!.close();

      db = await openSqfliteDb(name: 'legacy');

      expect(await db!.query('t'), hasLength(1));
    });
  });

  group('lost key', () {
    Future<void> createEncrypted() async {
      db = await openSqfliteDb(name: 'lost');
      await db!.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
      await db!.insert('t', {'id': 1, 'v': 'old'});
      await db!.close();
      db = null;
    }

    test('when the key is deleted, opening does not throw and gives an empty '
        'usable database (the user must log in again)', () async {
      await createEncrypted();
      await SqliteKeyStore().delete('lost');

      db = await openSqfliteDb(name: 'lost');

      expect(db, isNotNull);
      final tables = await db!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='t'",
      );
      expect(tables, isEmpty);
      await db!.execute('CREATE TABLE u (id INTEGER PRIMARY KEY)');
      await db!.insert('u', {'id': 1});
      expect(await db!.query('u'), hasLength(1));
    });

    test('when the stored key is changed, opening does not throw and gives an '
        'empty usable database (the user must log in again)', () async {
      await createEncrypted();
      FlutterSecureStorage.setMockInitialValues({'sqlite_key_lost': '0' * 64});

      db = await openSqfliteDb(name: 'lost');

      expect(db, isNotNull);
      final tables = await db!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      expect(tables, isEmpty);
    });

    test('the recovered database is encrypted with a fresh key', () async {
      await createEncrypted();
      final oldKey = await secureStorage.read(key: 'sqlite_key_lost');
      await SqliteKeyStore().delete('lost');

      db = await openSqfliteDb(name: 'lost');
      await db!.execute('CREATE TABLE u (id INTEGER PRIMARY KEY)');
      await db!.close();
      db = null;

      final newKey = await secureStorage.read(key: 'sqlite_key_lost');
      expect(newKey, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(newKey, isNot(oldKey));
      expect(_header(dbPath('lost')), isNot(equals(_plainHeader)));

      db = await openSqfliteDb(name: 'lost');
      expect(await db!.query('u'), isEmpty);
    });
  });

  group('recovery only destroys what is really unrecoverable', () {
    test('keeps the plaintext database when it cannot be encrypted', () async {
      final dir = p.dirname(dbPath('legacy'));
      await Directory(dir).create(recursive: true);
      final plain = await databaseFactoryFfi.openDatabase(dbPath('legacy'));
      await plain.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
      await plain.insert('t', {'id': 1, 'v': 'only-copy'});
      await plain.close();
      final before = File(dbPath('legacy')).readAsBytesSync();

      // The '.encrypted' export file cannot be created: a directory already
      // has that name. (chmod 555 on the directory does not reproduce the
      // loss: the recovery's own delete then fails and the file survives.)
      Directory('${dbPath('legacy')}.encrypted').createSync();

      Object? failure;
      try {
        db = await openSqfliteDb(name: 'legacy');
      } catch (e) {
        failure = e;
      }
      await db?.close();
      db = null;

      expect(File(dbPath('legacy')).existsSync(), isTrue);
      expect(File(dbPath('legacy')).readAsBytesSync(), equals(before));
      expect(
        failure,
        isNotNull,
        reason: 'must surface the failure, not return a fresh empty database',
      );
      final check = await databaseFactoryFfi.openDatabase(dbPath('legacy'));
      expect(await check.query('t'), [
        {'id': 1, 'v': 'only-copy'},
      ]);
      await check.close();
    });

    test('a file that is neither plaintext nor decryptable is recreated '
        'empty', () async {
      final dir = p.dirname(dbPath('junk'));
      await Directory(dir).create(recursive: true);
      File(
        dbPath('junk'),
      ).writeAsBytesSync(List<int>.generate(4096, (i) => (i * 37 + 11) % 256));

      db = await openSqfliteDb(name: 'junk');

      final tables = await db!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      expect(tables, isEmpty);
      await db!.execute('CREATE TABLE u (id INTEGER PRIMARY KEY)');
      await db!.insert('u', {'id': 1});
      expect(await db!.query('u'), hasLength(1));
    });
  });

  test('deleteSqfliteDb still deletes a database from its path', () async {
    db = await openSqfliteDb(name: 'gone');
    final path = db!.path;
    await db!.close();
    db = null;

    await deleteSqfliteDb(path);

    expect(File(path).existsSync(), isFalse);
  });
}
