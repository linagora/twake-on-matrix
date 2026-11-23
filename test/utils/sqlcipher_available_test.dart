import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twake_chat/utils/open_sqflite_db.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);

  final String dir;

  @override
  Future<String?> getApplicationSupportPath() async => dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

const _hexKey =
    "\"x'2DD29CA851E7B56E4697B0E1F08507293D761A05CE4D1B628663F411A8086D99'\"";
const _wrongKey =
    "\"x'0000000000000000000000000000000000000000000000000000000000000001'\"";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late PathProviderPlatform originalPathProvider;

  setUp(() {
    root = Directory.systemTemp.createTempSync('sqlcipher_available_test');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(root.path);
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPathProvider;
    root.deleteSync(recursive: true);
  });

  test('the loaded SQLite library is SQLCipher', () async {
    final db = (await openSqfliteDb(name: 'cipher_version'))!;
    addTearDown(db.close);

    final rows = await db.rawQuery('PRAGMA cipher_version');

    expect(rows, isNotEmpty);
    expect(rows.first.values.first.toString(), isNotEmpty);
  });

  test(
    'an encrypted database round-trips and is unreadable without the key',
    () async {
      var db = (await openSqfliteDb(name: 'encrypted'))!;
      final path = db.path;
      await db.execute('PRAGMA key = $_hexKey');
      await db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
      await db.insert('t', {'id': 1, 'v': 'secret'});
      await db.close();

      final header = (await File(path).open()).readSync(16);
      expect(header, isNot(equals('SQLite format 3\u0000'.codeUnits)));

      db = (await openSqfliteDb(name: 'encrypted'))!;
      await db.execute('PRAGMA key = $_hexKey');
      expect(await db.query('t'), [
        {'id': 1, 'v': 'secret'},
      ]);
      await db.close();

      db = (await openSqfliteDb(name: 'encrypted'))!;
      addTearDown(db.close);
      await db.execute('PRAGMA key = $_wrongKey');
      await expectLater(db.query('t'), throwsA(isA<DatabaseException>()));
    },
  );
}
