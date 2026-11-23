import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twake_chat/utils/open_sqflite_db.dart';
import 'package:twake_chat/utils/platform_infos.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider({required this.support, required this.documents});

  final String support;
  final String documents;

  @override
  Future<String?> getApplicationSupportPath() async => support;

  @override
  Future<String?> getApplicationDocumentsPath() async => documents;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('openSqfliteDb on desktop', () {
    late Directory root;
    late Directory support;
    late Directory documents;
    late PathProviderPlatform originalPathProvider;
    Database? db;

    setUp(() {
      root = Directory.systemTemp.createTempSync('open_sqflite_db_test');
      support = Directory(p.join(root.path, 'support'))..createSync();
      documents = Directory(p.join(root.path, 'documents'))..createSync();
      originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _FakePathProvider(
        support: support.path,
        documents: documents.path,
      );
    });

    tearDown(() async {
      await db?.close();
      db = null;
      PathProviderPlatform.instance = originalPathProvider;
      root.deleteSync(recursive: true);
    });

    test('the test host is a desktop', () {
      expect(PlatformInfos.isMobile, isFalse);
      expect(PlatformInfos.isDesktop, isTrue);
    });

    test('opens a usable SQLite database instead of returning null', () async {
      db = await openSqfliteDb(name: 'client_a');

      expect(db, isNotNull);
      await db!.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');
      await db!.insert('t', {'id': 1});
      expect(await db!.query('t'), hasLength(1));
    });

    test(
      'stores the database file in the app Application Support folder',
      () async {
        db = await openSqfliteDb(name: 'client_a');

        expect(db, isNotNull);
        expect(p.isWithin(support.path, db!.path), isTrue);
        expect(File(db!.path).existsSync(), isTrue);
        expect(p.basename(db!.path), 'client_a.db');
      },
    );

    test('does not write into the user Documents folder', () async {
      db = await openSqfliteDb(name: 'client_a');
      expect(db, isNotNull);
      await db!.execute('CREATE TABLE t (id INTEGER PRIMARY KEY)');

      expect(documents.listSync(recursive: true), isEmpty);
    });

    test('gives each client name its own database file', () async {
      final first = await openSqfliteDb(name: 'client_a');
      final second = await openSqfliteDb(name: 'client_b');
      addTearDown(() async {
        await first?.close();
        await second?.close();
      });

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first!.path, isNot(second!.path));
    });
  });
}
